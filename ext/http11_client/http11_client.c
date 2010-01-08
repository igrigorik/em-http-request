/**
 * Copyright (c) 2005 Zed A. Shaw
 * You can redistribute it and/or modify it under the same terms as Ruby.
 */

#include "ruby.h"
#include "ext_help.h"
#include <assert.h>
#include <string.h>
#include "http11_parser.h"
#include <ctype.h>

static VALUE mEm;
static VALUE cHttpClientParser;
static VALUE eHttpClientParserError;

#define  id_reason rb_intern("@http_reason")
#define  id_status rb_intern("@http_status")
#define  id_version rb_intern("@http_version")
#define  id_body rb_intern("@http_body")
#define  id_chunk_size rb_intern("@http_chunk_size")
#define  id_last_chunk rb_intern("@last_chunk")

#ifndef rb_hash_lookup
/* rb_hash_lookup() is only in Ruby 1.8.7 */
static VALUE rb_hash_lookup(VALUE hash, VALUE key)
{
  VALUE val;

  if (!st_lookup(RHASH(hash)->tbl, key, &val)) {
    return Qnil; /* without Hash#default */
  }

  return val;
}
#endif

void client_http_field(void *data, const char *field, size_t flen, const char *value, size_t vlen)
{
  char *ch, *end;
  VALUE req = (VALUE)data;
  VALUE v = Qnil;
  VALUE f = Qnil;
  VALUE el = Qnil;

  v = rb_str_new(value, vlen);
  f = rb_str_new(field, flen);

  /* Yes Children, rb_str_upcase_bang isn't even available as an intern.h function.
   * how incredibly handy to not have that.  Nope, I have to do it by hand.*/
  for(ch = RSTRING_PTR(f), end = ch + RSTRING_LEN(f); ch < end; ch++) {
    if(*ch == '-') {
      *ch = '_';
    } else {
      *ch = toupper(*ch);
    }
  }

  el = rb_hash_lookup(req, f);
  switch(TYPE(el)) {
    case T_ARRAY:
      rb_ary_push(el, v);
      break;
    case T_STRING:
      rb_hash_aset(req, f, rb_ary_new3(2, el, v));
      break;
    default:
      rb_hash_aset(req, f, v);
      break;
  }
}

void client_reason_phrase(void *data, const char *at, size_t length)
{
  VALUE req = (VALUE)data;
  VALUE v = Qnil;

  v = rb_str_new(at, length);

  rb_ivar_set(req, id_reason, v);
}

void client_status_code(void *data, const char *at, size_t length)
{
  VALUE req = (VALUE)data;
  VALUE v = Qnil;

  v = rb_str_new(at, length);

  rb_ivar_set(req, id_status, v);
}

void client_http_version(void *data, const char *at, size_t length)
{
  VALUE req = (VALUE)data;
  VALUE v = Qnil;

  v = rb_str_new(at, length);

  rb_ivar_set(req, id_version, v);
}

/** Finalizes the request header to have a bunch of stuff that's
  needed. */
void client_header_done(void *data, const char *at, size_t length)
{
  VALUE req = (VALUE)data;
  VALUE v = Qnil;

  v = rb_str_new(at, length);
  rb_ivar_set(req, id_body, v);
}

void client_chunk_size(void *data, const char *at, size_t length)
{
  VALUE req = (VALUE)data;
  VALUE v = Qnil;

  if(length <= 0) {
    rb_raise(eHttpClientParserError, "Chunked Encoding gave <= 0 chunk size.");
  }

  v = rb_str_new(at, length);

  rb_ivar_set(req, id_chunk_size, v);
}

void client_last_chunk(void *data, const char *at, size_t length) {
  VALUE req = (VALUE)data;
  rb_ivar_set(req, id_last_chunk,Qtrue);
}


void HttpClientParser_free(void *data) {
  TRACE();

  if(data) {
    free(data);
  }
}


VALUE HttpClientParser_alloc(VALUE klass)
{
  VALUE obj;
  httpclient_parser *hp = ALLOC_N(httpclient_parser, 1);
  TRACE();
  hp->http_field = client_http_field;
  hp->status_code = client_status_code;
  hp->reason_phrase = client_reason_phrase;
  hp->http_version = client_http_version;
  hp->header_done = client_header_done;
  hp->chunk_size = client_chunk_size;
  hp->last_chunk = client_last_chunk;
  httpclient_parser_init(hp);

  obj = Data_Wrap_Struct(klass, NULL, HttpClientParser_free, hp);

  return obj;
}


/**
 * call-seq:
 *    parser.new -> parser
 *
 * Creates a new parser.
 */
VALUE HttpClientParser_init(VALUE self)
{
  httpclient_parser *http = NULL;
  DATA_GET(self, httpclient_parser, http);
  httpclient_parser_init(http);

  return self;
}


/**
 * call-seq:
 *    parser.reset -> nil
 *
 * Resets the parser to it's initial state so that you can reuse it
 * rather than making new ones.
 */
VALUE HttpClientParser_reset(VALUE self)
{
  httpclient_parser *http = NULL;
  DATA_GET(self, httpclient_parser, http);
  httpclient_parser_init(http);

  return Qnil;
}


/**
 * call-seq:
 *    parser.finish -> true/false
 *
 * Finishes a parser early which could put in a "good" or bad state.
 * You should call reset after finish it or bad things will happen.
 */
VALUE HttpClientParser_finish(VALUE self)
{
  httpclient_parser *http = NULL;
  DATA_GET(self, httpclient_parser, http);
  httpclient_parser_finish(http);

  return httpclient_parser_is_finished(http) ? Qtrue : Qfalse;
}


/**
 * call-seq:
 *    parser.execute(req_hash, data, start) -> Integer
 *
 * Takes a Hash and a String of data, parses the String of data filling in the Hash
 * returning an Integer to indicate how much of the data has been read.  No matter
 * what the return value, you should call HttpClientParser#finished? and HttpClientParser#error?
 * to figure out if it's done parsing or there was an error.
 * 
 * This function now throws an exception when there is a parsing error.  This makes 
 * the logic for working with the parser much easier.  You can still test for an 
 * error, but now you need to wrap the parser with an exception handling block.
 *
 * The third argument allows for parsing a partial request and then continuing
 * the parsing from that position.  It needs all of the original data as well 
 * so you have to append to the data buffer as you read.
 */
VALUE HttpClientParser_execute(VALUE self, VALUE req_hash, VALUE data, VALUE start)
{
  httpclient_parser *http = NULL;
  int from = 0;
  char *dptr = NULL;
  long dlen = 0;

  REQUIRE_TYPE(req_hash, T_HASH);
  REQUIRE_TYPE(data, T_STRING);
  REQUIRE_TYPE(start, T_FIXNUM);

  DATA_GET(self, httpclient_parser, http);

  from = FIX2INT(start);
  dptr = RSTRING_PTR(data);
  dlen = RSTRING_LEN(data);

  if(from >= dlen) {
    rb_raise(eHttpClientParserError, "Requested start is after data buffer end.");
  } else {
    http->data = (void *)req_hash;
    httpclient_parser_execute(http, dptr, dlen, from);

    if(httpclient_parser_has_error(http)) {
      rb_raise(eHttpClientParserError, "Invalid HTTP format, parsing fails.");
    } else {
      return INT2FIX(httpclient_parser_nread(http));
    }
  }
}



/**
 * call-seq:
 *    parser.error? -> true/false
 *
 * Tells you whether the parser is in an error state.
 */
VALUE HttpClientParser_has_error(VALUE self)
{
  httpclient_parser *http = NULL;
  DATA_GET(self, httpclient_parser, http);

  return httpclient_parser_has_error(http) ? Qtrue : Qfalse;
}


/**
 * call-seq:
 *    parser.finished? -> true/false
 *
 * Tells you whether the parser is finished or not and in a good state.
 */
VALUE HttpClientParser_is_finished(VALUE self)
{
  httpclient_parser *http = NULL;
  DATA_GET(self, httpclient_parser, http);

  return httpclient_parser_is_finished(http) ? Qtrue : Qfalse;
}


/**
 * call-seq:
 *    parser.nread -> Integer
 *
 * Returns the amount of data processed so far during this processing cycle.  It is
 * set to 0 on initialize or reset calls and is incremented each time execute is called.
 */
VALUE HttpClientParser_nread(VALUE self)
{
  httpclient_parser *http = NULL;
  DATA_GET(self, httpclient_parser, http);

  return INT2FIX(http->nread);
}



void Init_http11_client()
{

  mEm = rb_define_module("EventMachine");

  eHttpClientParserError = rb_define_class_under(mEm, "HttpClientParserError", rb_eIOError);

  cHttpClientParser = rb_define_class_under(mEm, "HttpClientParser", rb_cObject);
  rb_define_alloc_func(cHttpClientParser, HttpClientParser_alloc);
  rb_define_method(cHttpClientParser, "initialize", HttpClientParser_init,0);
  rb_define_method(cHttpClientParser, "reset", HttpClientParser_reset,0);
  rb_define_method(cHttpClientParser, "finish", HttpClientParser_finish,0);
  rb_define_method(cHttpClientParser, "execute", HttpClientParser_execute,3);
  rb_define_method(cHttpClientParser, "error?", HttpClientParser_has_error,0);
  rb_define_method(cHttpClientParser, "finished?", HttpClientParser_is_finished,0);
  rb_define_method(cHttpClientParser, "nread", HttpClientParser_nread,0);
}



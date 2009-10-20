
#line 1 "http11_parser.rl"
/**
 * Copyright (c) 2005 Zed A. Shaw
 * You can redistribute it and/or modify it under the same terms as Ruby.
 */

#include "http11_parser.h"
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define LEN(AT, FPC) (FPC - buffer - parser->AT)
#define MARK(M,FPC) (parser->M = (FPC) - buffer)
#define PTR_TO(F) (buffer + parser->F)
#define L(M) fprintf(stderr, "" # M "\n");


/** machine **/

#line 95 "http11_parser.rl"


/** Data **/

#line 29 "http11_parser.c"
static const char _httpclient_parser_actions[] = {
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 7, 1, 
	8, 1, 10, 2, 0, 5, 2, 2, 
	3, 2, 3, 4, 2, 4, 10, 2, 
	6, 0, 2, 8, 10, 2, 9, 10, 
	2, 10, 9, 3, 2, 3, 4, 3, 
	4, 9, 10, 3, 4, 10, 9, 3, 
	6, 0, 5, 3, 8, 10, 9, 4, 
	2, 3, 4, 10, 5, 2, 3, 4, 
	9, 10, 5, 2, 3, 4, 10, 9
	
};

static const short _httpclient_parser_key_offsets[] = {
	0, 0, 11, 12, 24, 29, 30, 31, 
	43, 58, 80, 95, 116, 131, 153, 168, 
	189, 204, 223, 238, 256, 257, 258, 259, 
	260, 262, 265, 267, 270, 272, 274, 276, 
	279, 281, 298, 314, 317, 319, 320, 322
};

static const char _httpclient_parser_trans_keys[] = {
	10, 13, 48, 59, 72, 49, 57, 65, 
	70, 97, 102, 10, 10, 13, 32, 59, 
	9, 12, 48, 57, 65, 70, 97, 102, 
	10, 13, 32, 9, 12, 10, 10, 10, 
	13, 32, 59, 9, 12, 48, 57, 65, 
	70, 97, 102, 33, 124, 126, 35, 39, 
	42, 43, 45, 46, 48, 57, 65, 90, 
	94, 122, 10, 13, 32, 33, 59, 61, 
	124, 126, 9, 12, 35, 39, 42, 43, 
	45, 46, 48, 57, 65, 90, 94, 122, 
	33, 124, 126, 35, 39, 42, 43, 45, 
	46, 48, 57, 65, 90, 94, 122, 10, 
	13, 32, 33, 59, 124, 126, 9, 12, 
	35, 39, 42, 43, 45, 46, 48, 57, 
	65, 90, 94, 122, 33, 124, 126, 35, 
	39, 42, 43, 45, 46, 48, 57, 65, 
	90, 94, 122, 10, 13, 32, 33, 59, 
	61, 124, 126, 9, 12, 35, 39, 42, 
	43, 45, 46, 48, 57, 65, 90, 94, 
	122, 33, 124, 126, 35, 39, 42, 43, 
	45, 46, 48, 57, 65, 90, 94, 122, 
	10, 13, 32, 33, 59, 124, 126, 9, 
	12, 35, 39, 42, 43, 45, 46, 48, 
	57, 65, 90, 94, 122, 33, 124, 126, 
	35, 39, 42, 43, 45, 46, 48, 57, 
	65, 90, 94, 122, 10, 13, 33, 59, 
	61, 124, 126, 35, 39, 42, 43, 45, 
	46, 48, 57, 65, 90, 94, 122, 33, 
	124, 126, 35, 39, 42, 43, 45, 46, 
	48, 57, 65, 90, 94, 122, 10, 13, 
	33, 59, 124, 126, 35, 39, 42, 43, 
	45, 46, 48, 57, 65, 90, 94, 122, 
	84, 84, 80, 47, 48, 57, 46, 48, 
	57, 48, 57, 32, 48, 57, 48, 57, 
	48, 57, 48, 57, 10, 13, 32, 10, 
	13, 10, 13, 33, 124, 126, 35, 39, 
	42, 43, 45, 46, 48, 57, 65, 90, 
	94, 122, 33, 58, 124, 126, 35, 39, 
	42, 43, 45, 46, 48, 57, 65, 90, 
	94, 122, 10, 13, 32, 10, 13, 10, 
	10, 13, 0
};

static const char _httpclient_parser_single_lengths[] = {
	0, 5, 1, 4, 3, 1, 1, 4, 
	3, 8, 3, 7, 3, 8, 3, 7, 
	3, 7, 3, 6, 1, 1, 1, 1, 
	0, 1, 0, 1, 0, 0, 0, 3, 
	2, 5, 4, 3, 2, 1, 2, 0
};

static const char _httpclient_parser_range_lengths[] = {
	0, 3, 0, 4, 1, 0, 0, 4, 
	6, 7, 6, 7, 6, 7, 6, 7, 
	6, 6, 6, 6, 0, 0, 0, 0, 
	1, 1, 1, 1, 1, 1, 1, 0, 
	0, 6, 6, 0, 0, 0, 0, 0
};

static const short _httpclient_parser_index_offsets[] = {
	0, 0, 9, 11, 20, 25, 27, 29, 
	38, 48, 64, 74, 89, 99, 115, 125, 
	140, 150, 164, 174, 187, 189, 191, 193, 
	195, 197, 200, 202, 205, 207, 209, 211, 
	215, 218, 230, 241, 245, 248, 250, 253
};

static const char _httpclient_parser_indicies[] = {
	0, 2, 3, 5, 6, 4, 4, 4, 
	1, 0, 1, 8, 9, 7, 11, 7, 
	10, 10, 10, 1, 13, 14, 12, 12, 
	1, 13, 1, 15, 1, 16, 17, 7, 
	18, 7, 10, 10, 10, 1, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 1, 
	21, 22, 20, 23, 24, 25, 23, 23, 
	20, 23, 23, 23, 23, 23, 23, 1, 
	26, 26, 26, 26, 26, 26, 26, 26, 
	26, 1, 28, 29, 27, 30, 31, 30, 
	30, 27, 30, 30, 30, 30, 30, 30, 
	1, 32, 32, 32, 32, 32, 32, 32, 
	32, 32, 1, 33, 34, 20, 35, 36, 
	37, 35, 35, 20, 35, 35, 35, 35, 
	35, 35, 1, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 1, 39, 40, 27, 
	41, 42, 41, 41, 27, 41, 41, 41, 
	41, 41, 41, 1, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 1, 44, 45, 
	46, 47, 48, 46, 46, 46, 46, 46, 
	46, 46, 46, 1, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 1, 50, 51, 
	52, 53, 52, 52, 52, 52, 52, 52, 
	52, 52, 1, 54, 1, 55, 1, 56, 
	1, 57, 1, 58, 1, 59, 58, 1, 
	60, 1, 61, 60, 1, 62, 1, 63, 
	1, 64, 1, 66, 67, 68, 65, 70, 
	71, 69, 13, 14, 72, 72, 72, 72, 
	72, 72, 72, 72, 72, 1, 73, 74, 
	73, 73, 73, 73, 73, 73, 73, 73, 
	1, 76, 77, 78, 75, 80, 81, 79, 
	82, 1, 84, 85, 83, 1, 0
};

static const char _httpclient_parser_trans_targs[] = {
	39, 0, 2, 3, 7, 16, 20, 4, 
	39, 6, 7, 12, 4, 39, 5, 39, 
	39, 5, 8, 9, 4, 39, 5, 9, 
	8, 10, 11, 4, 39, 5, 11, 8, 
	13, 39, 6, 13, 12, 14, 15, 39, 
	6, 15, 12, 17, 39, 2, 17, 16, 
	18, 19, 39, 2, 19, 16, 21, 22, 
	23, 24, 25, 26, 27, 28, 29, 30, 
	31, 32, 33, 37, 38, 32, 33, 37, 
	34, 34, 35, 36, 33, 37, 35, 36, 
	33, 37, 33, 32, 33, 37
};

static const char _httpclient_parser_trans_actions[] = {
	37, 0, 0, 1, 1, 0, 1, 15, 
	59, 15, 0, 15, 0, 17, 0, 40, 
	34, 15, 15, 3, 43, 63, 43, 0, 
	43, 22, 7, 9, 28, 9, 0, 9, 
	3, 74, 43, 0, 43, 22, 7, 51, 
	9, 0, 9, 3, 68, 43, 0, 43, 
	22, 7, 47, 9, 0, 9, 0, 0, 
	0, 0, 0, 0, 0, 13, 1, 0, 
	0, 31, 55, 55, 31, 0, 11, 11, 
	3, 0, 5, 7, 25, 25, 7, 0, 
	9, 9, 0, 1, 19, 19
};

static const int httpclient_parser_start = 1;
static const int httpclient_parser_first_final = 39;
static const int httpclient_parser_error = 0;

static const int httpclient_parser_en_main = 1;


#line 99 "http11_parser.rl"

int httpclient_parser_init(httpclient_parser *parser)  {
  int cs = 0;
  
#line 195 "http11_parser.c"
	{
	cs = httpclient_parser_start;
	}

#line 103 "http11_parser.rl"
  parser->cs = cs;
  parser->body_start = 0;
  parser->content_len = 0;
  parser->mark = 0;
  parser->nread = 0;
  parser->field_len = 0;
  parser->field_start = 0;    

  return(1);
}


/** exec **/
size_t httpclient_parser_execute(httpclient_parser *parser, const char *buffer, size_t len, size_t off)  {
  const char *p, *pe;
  int cs = parser->cs;

  assert(off <= len && "offset past end of buffer");

  p = buffer+off;
  pe = buffer+len;

  assert(*pe == '\0' && "pointer does not end on NUL");
  assert(pe - p == len - off && "pointers aren't same distance");


  
#line 228 "http11_parser.c"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _httpclient_parser_trans_keys + _httpclient_parser_key_offsets[cs];
	_trans = _httpclient_parser_index_offsets[cs];

	_klen = _httpclient_parser_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _httpclient_parser_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += ((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _httpclient_parser_indicies[_trans];
	cs = _httpclient_parser_trans_targs[_trans];

	if ( _httpclient_parser_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _httpclient_parser_actions + _httpclient_parser_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 23 "http11_parser.rl"
	{MARK(mark, p); }
	break;
	case 1:
#line 25 "http11_parser.rl"
	{ MARK(field_start, p); }
	break;
	case 2:
#line 27 "http11_parser.rl"
	{ 
    parser->field_len = LEN(field_start, p);
  }
	break;
	case 3:
#line 31 "http11_parser.rl"
	{ MARK(mark, p); }
	break;
	case 4:
#line 33 "http11_parser.rl"
	{ 
    parser->http_field(parser->data, PTR_TO(field_start), parser->field_len, PTR_TO(mark), LEN(mark, p));
  }
	break;
	case 5:
#line 37 "http11_parser.rl"
	{ 
    parser->reason_phrase(parser->data, PTR_TO(mark), LEN(mark, p));
  }
	break;
	case 6:
#line 41 "http11_parser.rl"
	{ 
    parser->status_code(parser->data, PTR_TO(mark), LEN(mark, p));
  }
	break;
	case 7:
#line 45 "http11_parser.rl"
	{	
    parser->http_version(parser->data, PTR_TO(mark), LEN(mark, p));
  }
	break;
	case 8:
#line 49 "http11_parser.rl"
	{
    parser->chunk_size(parser->data, PTR_TO(mark), LEN(mark, p));
  }
	break;
	case 9:
#line 53 "http11_parser.rl"
	{
    parser->last_chunk(parser->data, NULL, 0);
  }
	break;
	case 10:
#line 57 "http11_parser.rl"
	{ 
    parser->body_start = p - buffer + 1; 
    if(parser->header_done != NULL)
      parser->header_done(parser->data, p + 1, pe - p - 1);
    {p++; goto _out; }
  }
	break;
#line 365 "http11_parser.c"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 130 "http11_parser.rl"

  parser->cs = cs;
  parser->nread += p - (buffer + off);

  assert(p <= pe && "buffer overflow after parsing execute");
  assert(parser->nread <= len && "nread longer than length");
  assert(parser->body_start <= len && "body starts after buffer end");
  assert(parser->mark < len && "mark is after buffer end");
  assert(parser->field_len <= len && "field has length longer than whole buffer");
  assert(parser->field_start < len && "field starts after buffer end");

  if(parser->body_start) {
    /* final \r\n combo encountered so stop right here */
    parser->nread = parser->body_start;
  }

  return(parser->nread);
}

int httpclient_parser_finish(httpclient_parser *parser)
{
  int cs = parser->cs;

  parser->cs = cs;

  if (httpclient_parser_has_error(parser) ) {
    return -1;
  } else if (httpclient_parser_is_finished(parser) ) {
    return 1;
  } else {
    return 0;
  }
}

int httpclient_parser_has_error(httpclient_parser *parser) {
  return parser->cs == httpclient_parser_error;
}

int httpclient_parser_is_finished(httpclient_parser *parser) {
  return parser->cs == httpclient_parser_first_final;
}

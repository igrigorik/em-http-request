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

#line 27 "http11_parser.c"
static const char _httpclient_parser_actions[] = {
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 7, 1, 
	8, 1, 10, 2, 2, 3, 2, 6, 
	0, 2, 6, 5, 2, 9, 10, 2, 
	10, 9, 3, 2, 3, 4
};

static const short _httpclient_parser_key_offsets[] = {
	0, 10, 10, 11, 22, 26, 27, 28, 
	39, 54, 75, 90, 110, 125, 146, 161, 
	181, 196, 214, 229, 246, 247, 248, 249, 
	250, 252, 255, 257, 260, 262, 264, 266, 
	268, 269, 270, 286, 302, 304, 305, 306
};

static const char _httpclient_parser_trans_keys[] = {
	13, 48, 59, 72, 49, 57, 65, 70, 
	97, 102, 10, 13, 32, 59, 9, 12, 
	48, 57, 65, 70, 97, 102, 13, 32, 
	9, 12, 10, 10, 13, 32, 59, 9, 
	12, 48, 57, 65, 70, 97, 102, 33, 
	124, 126, 35, 39, 42, 43, 45, 46, 
	48, 57, 65, 90, 94, 122, 13, 32, 
	33, 59, 61, 124, 126, 9, 12, 35, 
	39, 42, 43, 45, 46, 48, 57, 65, 
	90, 94, 122, 33, 124, 126, 35, 39, 
	42, 43, 45, 46, 48, 57, 65, 90, 
	94, 122, 13, 32, 33, 59, 124, 126, 
	9, 12, 35, 39, 42, 43, 45, 46, 
	48, 57, 65, 90, 94, 122, 33, 124, 
	126, 35, 39, 42, 43, 45, 46, 48, 
	57, 65, 90, 94, 122, 13, 32, 33, 
	59, 61, 124, 126, 9, 12, 35, 39, 
	42, 43, 45, 46, 48, 57, 65, 90, 
	94, 122, 33, 124, 126, 35, 39, 42, 
	43, 45, 46, 48, 57, 65, 90, 94, 
	122, 13, 32, 33, 59, 124, 126, 9, 
	12, 35, 39, 42, 43, 45, 46, 48, 
	57, 65, 90, 94, 122, 33, 124, 126, 
	35, 39, 42, 43, 45, 46, 48, 57, 
	65, 90, 94, 122, 13, 33, 59, 61, 
	124, 126, 35, 39, 42, 43, 45, 46, 
	48, 57, 65, 90, 94, 122, 33, 124, 
	126, 35, 39, 42, 43, 45, 46, 48, 
	57, 65, 90, 94, 122, 13, 33, 59, 
	124, 126, 35, 39, 42, 43, 45, 46, 
	48, 57, 65, 90, 94, 122, 84, 84, 
	80, 47, 48, 57, 46, 48, 57, 48, 
	57, 32, 48, 57, 48, 57, 48, 57, 
	48, 57, 13, 32, 13, 10, 13, 33, 
	124, 126, 35, 39, 42, 43, 45, 46, 
	48, 57, 65, 90, 94, 122, 33, 58, 
	124, 126, 35, 39, 42, 43, 45, 46, 
	48, 57, 65, 90, 94, 122, 13, 32, 
	13, 13, 0
};

static const char _httpclient_parser_single_lengths[] = {
	4, 0, 1, 3, 2, 1, 1, 3, 
	3, 7, 3, 6, 3, 7, 3, 6, 
	3, 6, 3, 5, 1, 1, 1, 1, 
	0, 1, 0, 1, 0, 0, 0, 2, 
	1, 1, 4, 4, 2, 1, 1, 0
};

static const char _httpclient_parser_range_lengths[] = {
	3, 0, 0, 4, 1, 0, 0, 4, 
	6, 7, 6, 7, 6, 7, 6, 7, 
	6, 6, 6, 6, 0, 0, 0, 0, 
	1, 1, 1, 1, 1, 1, 1, 0, 
	0, 0, 6, 6, 0, 0, 0, 0
};

static const unsigned char _httpclient_parser_index_offsets[] = {
	0, 8, 8, 10, 18, 22, 24, 26, 
	34, 44, 59, 69, 83, 93, 108, 118, 
	132, 142, 155, 165, 177, 179, 181, 183, 
	185, 187, 190, 192, 195, 197, 199, 201, 
	204, 206, 208, 219, 230, 233, 235, 237
};

static const char _httpclient_parser_indicies[] = {
	14, 15, 17, 18, 16, 16, 16, 0, 
	30, 0, 63, 37, 64, 37, 39, 39, 
	39, 0, 19, 32, 32, 0, 29, 0, 
	31, 0, 38, 37, 40, 37, 39, 39, 
	39, 0, 58, 58, 58, 58, 58, 58, 
	58, 58, 58, 0, 42, 41, 43, 44, 
	45, 43, 43, 41, 43, 43, 43, 43, 
	43, 43, 0, 59, 59, 59, 59, 59, 
	59, 59, 59, 59, 0, 34, 33, 35, 
	36, 35, 35, 33, 35, 35, 35, 35, 
	35, 35, 0, 70, 70, 70, 70, 70, 
	70, 70, 70, 70, 0, 65, 41, 66, 
	67, 68, 66, 66, 41, 66, 66, 66, 
	66, 66, 66, 0, 69, 69, 69, 69, 
	69, 69, 69, 69, 69, 0, 60, 33, 
	61, 62, 61, 61, 33, 61, 61, 61, 
	61, 61, 61, 0, 10, 10, 10, 10, 
	10, 10, 10, 10, 10, 0, 24, 25, 
	26, 27, 25, 25, 25, 25, 25, 25, 
	25, 25, 0, 11, 11, 11, 11, 11, 
	11, 11, 11, 11, 0, 21, 22, 23, 
	22, 22, 22, 22, 22, 22, 22, 22, 
	0, 1, 0, 56, 0, 2, 0, 5, 
	0, 7, 0, 6, 7, 0, 13, 0, 
	12, 13, 0, 4, 0, 3, 0, 57, 
	0, 54, 55, 53, 49, 48, 28, 0, 
	19, 20, 20, 20, 20, 20, 20, 20, 
	20, 20, 0, 8, 9, 8, 8, 8, 
	8, 8, 8, 8, 8, 0, 47, 52, 
	51, 47, 46, 49, 50, 0, 0
};

static const char _httpclient_parser_trans_targs_wi[] = {
	1, 21, 23, 30, 29, 24, 26, 25, 
	35, 36, 17, 19, 28, 27, 2, 3, 
	7, 16, 20, 5, 35, 2, 19, 16, 
	2, 17, 16, 18, 34, 39, 39, 39, 
	4, 4, 5, 11, 8, 4, 5, 7, 
	8, 4, 5, 9, 8, 10, 37, 33, 
	32, 33, 32, 37, 36, 32, 33, 38, 
	22, 31, 9, 11, 6, 15, 12, 6, 
	12, 6, 13, 12, 14, 15, 13
};

static const char _httpclient_parser_trans_actions_wi[] = {
	0, 0, 0, 0, 1, 0, 0, 0, 
	0, 5, 3, 7, 13, 0, 0, 1, 
	1, 0, 1, 0, 3, 9, 0, 9, 
	34, 0, 34, 19, 0, 17, 28, 31, 
	0, 9, 9, 0, 9, 15, 15, 0, 
	15, 34, 34, 0, 34, 19, 0, 9, 
	0, 11, 1, 7, 7, 22, 25, 22, 
	0, 0, 3, 7, 9, 0, 9, 15, 
	15, 34, 0, 34, 19, 7, 3
};

static const int httpclient_parser_start = 0;

static const int httpclient_parser_first_final = 39;

static const int httpclient_parser_error = 1;

#line 99 "http11_parser.rl"

int httpclient_parser_init(httpclient_parser *parser)  {
  int cs = 0;
  
#line 178 "http11_parser.c"
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


  
#line 210 "http11_parser.c"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _out;
_resume:
	if ( cs == 1 )
		goto _out;
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
	cs = _httpclient_parser_trans_targs_wi[_trans];

	if ( _httpclient_parser_trans_actions_wi[_trans] == 0 )
		goto _again;

	_acts = _httpclient_parser_actions + _httpclient_parser_trans_actions_wi[_trans];
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
    goto _out;
  }
	break;
#line 347 "http11_parser.c"
		}
	}

_again:
	if ( ++p != pe )
		goto _resume;
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
    
#line 371 "http11_parser.c"
#line 144 "http11_parser.rl"
    parser->nread++;
  }

  return(parser->nread);
}

int httpclient_parser_finish(httpclient_parser *parser)
{
  int cs = parser->cs;

  
#line 384 "http11_parser.c"
#line 155 "http11_parser.rl"

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

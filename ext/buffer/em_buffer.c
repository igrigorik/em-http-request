/*
 * Copyright (C) 2007 Tony Arcieri
 * You may redistribute this under the terms of the Ruby license.
 * See LICENSE for details
 */

#include "ruby.h"
#include "rubyio.h"

#include <assert.h>

#include <string.h>
#include <time.h>
#include <errno.h>

#ifndef GetReadFile
#define FPTR_TO_FD(fptr) (fptr->fd)
#else
#define FPTR_TO_FD(fptr) (fileno(GetReadFile(fptr)))
#endif

/* Default number of bytes in each node's buffer */
#define DEFAULT_NODE_SIZE 16384

/* Maximum age of a buffer node in a memory pool, in seconds */
#define MAX_AGE 60

/* How often to scan the pool for old nodes */
#define PURGE_INTERVAL 10

struct buffer {
	time_t last_purged_at;
  unsigned size, node_size;
  struct buffer_node *head, *tail;
  struct buffer_node *pool_head, *pool_tail;
	
};

struct buffer_node {
	time_t last_used_at;
  unsigned start, end;
  struct buffer_node *next;
  unsigned char data[0];
};

static VALUE mEm = Qnil;
static VALUE cEm_Buffer = Qnil;

static VALUE Em_Buffer_allocate(VALUE klass);
static void Em_Buffer_mark(struct buffer *);
static void Em_Buffer_free(struct buffer *);

static VALUE Em_Buffer_initialize(int argc, VALUE *argv, VALUE self);
static VALUE Em_Buffer_clear(VALUE self);
static VALUE Em_Buffer_size(VALUE self);
static VALUE Em_Buffer_empty(VALUE self);
static VALUE Em_Buffer_append(VALUE self, VALUE data);
static VALUE Em_Buffer_prepend(VALUE self, VALUE data);
static VALUE Em_Buffer_read(int argc, VALUE *argv, VALUE self);
static VALUE Em_Buffer_to_str(VALUE self);
static VALUE Em_Buffer_read_from(VALUE self, VALUE io);
static VALUE Em_Buffer_write_to(VALUE self, VALUE io);

static struct buffer *buffer_new(void);
static void buffer_clear(struct buffer *buf);
static void buffer_free(struct buffer *buf);
static void buffer_gc(struct buffer *buf);
static void buffer_prepend(struct buffer *buf, char *str, unsigned len);
static void buffer_append(struct buffer *buf, char *str, unsigned len);
static void buffer_read(struct buffer *buf, char *str, unsigned len);
static void buffer_copy(struct buffer *buf, char *str, unsigned len);
static int buffer_read_from(struct buffer *buf, int fd);
static int buffer_write_to(struct buffer *buf, int fd);

/* 
 * High speed buffering geared towards non-blocking I/O.
 *
 * Data is stored in a byte queue implemented as a linked list of equal size
 * chunks.  Since every node in the list is the same size they are easily
 * memory pooled.  Routines are provided for high speed non-blocking reads
 * and writes from Ruby IO objects.
 */
void Init_em_buffer()
{
  mEm = rb_define_module("EventMachine");
  cEm_Buffer = rb_define_class_under(mEm, "Buffer", rb_cObject);
  rb_define_alloc_func(cEm_Buffer, Em_Buffer_allocate);

  rb_define_method(cEm_Buffer, "initialize", Em_Buffer_initialize, -1);
  rb_define_method(cEm_Buffer, "clear", Em_Buffer_clear, 0);
  rb_define_method(cEm_Buffer, "size", Em_Buffer_size, 0);
  rb_define_method(cEm_Buffer, "empty?", Em_Buffer_empty, 0);
  rb_define_method(cEm_Buffer, "<<", Em_Buffer_append, 1);
  rb_define_method(cEm_Buffer, "append", Em_Buffer_append, 1);
  rb_define_method(cEm_Buffer, "prepend", Em_Buffer_prepend, 1);
  rb_define_method(cEm_Buffer, "read", Em_Buffer_read, -1);
	rb_define_method(cEm_Buffer, "to_str", Em_Buffer_to_str, 0);
	rb_define_method(cEm_Buffer, "read_from", Em_Buffer_read_from, 1);
  rb_define_method(cEm_Buffer, "write_to", Em_Buffer_write_to, 1);
}

static VALUE Em_Buffer_allocate(VALUE klass)
{
  return Data_Wrap_Struct(klass, Em_Buffer_mark, Em_Buffer_free, buffer_new());
}

static void Em_Buffer_mark(struct buffer *buf)
{
  /* Walks the pool of unused chunks and frees any that are beyond a certain age */
  buffer_gc(buf);
}

static void Em_Buffer_free(struct buffer *buf)
{
  buffer_free(buf);
}

/**
 *  call-seq:
 *    EventMachine::Buffer.new(size = DEFAULT_NODE_SIZE) -> EventMachine::Buffer
 * 
 * Create a new EventMachine::Buffer with linked segments of the given size
 */
static VALUE Em_Buffer_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE node_size_obj;
  int node_size;
  struct buffer *buf;

  if(rb_scan_args(argc, argv, "01", &node_size_obj) == 1) {
    node_size = NUM2INT(node_size_obj);

    if(node_size < 1) rb_raise(rb_eArgError, "invalid buffer size");

    Data_Get_Struct(self, struct buffer, buf);

    /* Make sure we're not changing the buffer size after data has been allocated */
    assert(!buf->head);
    assert(!buf->pool_head);

    buf->node_size = node_size;
  }

  return Qnil;
}

/**
 *  call-seq:
 *    EventMachine::Buffer#clear -> nil
 * 
 * Clear all data from the EventMachine::Buffer
 */
static VALUE Em_Buffer_clear(VALUE self)
{
  struct buffer *buf;
  Data_Get_Struct(self, struct buffer, buf);

  buffer_clear(buf);

  return Qnil;
}

/**
 *  call-seq:
 *    EventMachine::Buffer#size -> Integer
 * 
 * Return the size of the buffer in bytes
 */
static VALUE Em_Buffer_size(VALUE self) 
{
  struct buffer *buf;
  Data_Get_Struct(self, struct buffer, buf);

  return INT2NUM(buf->size);
}

/**
 *  call-seq:
 *    EventMachine::Buffer#empty? -> Boolean
 * 
 * Is the buffer empty?
 */
static VALUE Em_Buffer_empty(VALUE self) 
{
  struct buffer *buf;
  Data_Get_Struct(self, struct buffer, buf);

  return buf->size > 0 ? Qfalse : Qtrue;	
}

/**
 *  call-seq:
 *    EventMachine::Buffer#append(data) -> String
 * 
 * Append the given data to the end of the buffer
 */
static VALUE Em_Buffer_append(VALUE self, VALUE data)
{
  struct buffer *buf;
  Data_Get_Struct(self, struct buffer, buf);

  /* Is this needed?  Never seen anyone else do it... */
  data = rb_convert_type(data, T_STRING, "String", "to_str");
  buffer_append(buf, RSTRING_PTR(data), RSTRING_LEN(data));

  return data;
}

/**
 *  call-seq:
 *    EventMachine::Buffer#prepend(data) -> String
 * 
 * Prepend the given data to the beginning of the buffer
 */
static VALUE Em_Buffer_prepend(VALUE self, VALUE data)
{
  struct buffer *buf;
  Data_Get_Struct(self, struct buffer, buf);

  data = rb_convert_type(data, T_STRING, "String", "to_str");
  buffer_prepend(buf, RSTRING_PTR(data), RSTRING_LEN(data));

  return data;
}

/**
 *  call-seq:
 *    EventMachine::Buffer#read(length = nil) -> String
 * 
 * Read the specified abount of data from the buffer.  If no value
 * is given the entire contents of the buffer are returned.  Any data
 * read from the buffer is cleared.
 */
static VALUE Em_Buffer_read(int argc, VALUE *argv, VALUE self)
{
  VALUE length_obj, str;
  int length;
  struct buffer *buf;

  Data_Get_Struct(self, struct buffer, buf);

  if(rb_scan_args(argc, argv, "01", &length_obj) == 1) {
    length = NUM2INT(length_obj);
  } else {
    if(buf->size == 0)
      return rb_str_new2("");

    length = buf->size;
  }

  if(length > buf->size)
    length = buf->size;

  if(length < 1)
    rb_raise(rb_eArgError, "length must be greater than zero");

  str = rb_str_new(0, length);
  buffer_read(buf, RSTRING_PTR(str), length);

  return str;
}

/**
 *  call-seq:
 *    EventMachine::Buffer#to_str -> String
 * 
 * Convert the Buffer to a String.  The original buffer is unmodified.
 */
static VALUE Em_Buffer_to_str(VALUE self) {
	VALUE str;
	struct buffer *buf;
	
	Data_Get_Struct(self, struct buffer, buf);
	
	str = rb_str_new(0, buf->size);
	buffer_copy(buf, RSTRING_PTR(str), buf->size);
  
  return str;
}

/**
 *  call-seq:
 *    EventMachine::Buffer#read_from(io) -> Integer
 * 
 * Perform a nonblocking read of the the given IO object and fill
 * the buffer with any data received.  The call will read as much
 * data as it can until the read would block.
 */
static VALUE Em_Buffer_read_from(VALUE self, VALUE io) {
	struct buffer *buf;
#if HAVE_RB_IO_T
  rb_io_t *fptr;
#else
  OpenFile *fptr;
#endif

  Data_Get_Struct(self, struct buffer, buf);
  GetOpenFile(rb_convert_type(io, T_FILE, "IO", "to_io"), fptr);
  rb_io_set_nonblock(fptr);

  return INT2NUM(buffer_read_from(buf, FPTR_TO_FD(fptr)));
}

/**
 *  call-seq:
 *    EventMachine::Buffer#write_to(io) -> Integer
 * 
 * Perform a nonblocking write of the buffer to the given IO object.
 * As much data as possible is written until the call would block.
 * Any data which is written is removed from the buffer.
 */
static VALUE Em_Buffer_write_to(VALUE self, VALUE io) {
  struct buffer *buf;
#if HAVE_RB_IO_T 
  rb_io_t *fptr;
#else
  OpenFile *fptr;
#endif

  Data_Get_Struct(self, struct buffer, buf);
  GetOpenFile(rb_convert_type(io, T_FILE, "IO", "to_io"), fptr);
  rb_io_set_nonblock(fptr);

  return INT2NUM(buffer_write_to(buf, FPTR_TO_FD(fptr)));
}

/*
 * Ruby bindings end here.  Below is the actual implementation of 
 * the underlying data structures.
 */

/* Create a new buffer */
static struct buffer *buffer_new(void)
{
  struct buffer *buf;

  buf = (struct buffer *)xmalloc(sizeof(struct buffer));
  buf->head = buf->tail = buf->pool_head = buf->pool_tail = 0;
  buf->size = 0;
  buf->node_size = DEFAULT_NODE_SIZE;
	time(&buf->last_purged_at);
	
  return buf;
}

/* Clear all data from a buffer */
static void buffer_clear(struct buffer *buf)
{
  struct buffer_node *tmp;

  /* Move everything into the buffer pool */
  if(!buf->pool_tail)
    buf->pool_head = buf->pool_tail = buf->head;
  else
    buf->pool_tail->next = buf->head;

  buf->head = buf->tail = 0;
  buf->size = 0;
}

/* Free a buffer */
static void buffer_free(struct buffer *buf) 
{
  struct buffer_node *tmp;

  buffer_clear(buf);

  while(buf->pool_head) {
    tmp = buf->pool_head;
    buf->pool_head = tmp->next;
    free(tmp);
  }

  free(buf);
}

/* Run through the pool and find elements that haven't been used for awhile */
static void buffer_gc(struct buffer *buf)
{
  struct buffer_node *cur, *tmp;
  time_t now;
  time(&now);

	/* Only purge if we've passed the purge interval */
	if(now - buf->last_purged_at < PURGE_INTERVAL)
		return;
		
	buf->last_purged_at = now;

  while(buf->pool_head && now - buf->pool_head->last_used_at >= MAX_AGE) {
    tmp = buf->pool_head;
    buf->pool_head = buf->pool_head->next;
    free(tmp);
  }

  if(!buf->pool_head)
		buf->pool_tail = 0;
}

/* Create a new buffer_node (or pull one from the memory pool) */
static struct buffer_node *buffer_node_new(struct buffer *buf)
{
  struct buffer_node *node;

  /* Pull from the memory pool if available */
  if(buf->pool_head) {
    node = buf->pool_head;
    buf->pool_head = node->next;

    if(node->next)
      node->next = 0;
    else
      buf->pool_tail = 0;
  } else {
    node = (struct buffer_node *)xmalloc(sizeof(struct buffer_node) + buf->node_size);
    node->next = 0;
  }

  node->start = node->end = 0;
  return node;
}

/* Free a buffer node (i.e. return it to the memory pool) */
static void buffer_node_free(struct buffer *buf, struct buffer_node *node)
{
  /* Store when the node was freed */
  time(&node->last_used_at);

  node->next = buf->pool_head;
  buf->pool_head = node;

  if(!buf->pool_tail)
    buf->pool_tail = node;
}

/* Prepend data to the front of the buffer */
static void buffer_prepend(struct buffer *buf, char *str, unsigned len)
{
  struct buffer_node *node, *tmp;
  buf->size += len;

  /* If it fits in the beginning of the head */
  if(buf->head && buf->head->start >= len) {
    buf->head->start -= len;
    memcpy(buf->head->data + buf->head->start, str, len);
  } else {
    node = buffer_node_new(buf);
    node->next = buf->head;
    buf->head = node;
    if(!buf->tail) buf->tail = node;

    while(len > buf->node_size) {
      memcpy(node->data, str, buf->node_size);
      node->end = buf->node_size;

      tmp = buffer_node_new(buf);
      tmp->next = node->next;
      node->next = tmp;

      if(buf->tail == node) buf->tail = tmp;
      node = tmp;

      str += buf->node_size;
      len -= buf->node_size;
    }

    if(len > 0) {
      memcpy(node->data, str, len);
      node->end = len;
    }
  }
}

/* Append data to the front of the buffer */
static void buffer_append(struct buffer *buf, char *str, unsigned len)
{
  unsigned nbytes;
  buf->size += len;

  /* If it fits in the remaining space in the tail */
  if(buf->tail && len <= buf->node_size - buf->tail->end) {
    memcpy(buf->tail->data + buf->tail->end, str, len);
    buf->tail->end += len;
    return;
  }

  /* Empty list needs initialized */
  if(!buf->head) {
    buf->head = buffer_node_new(buf);
    buf->tail = buf->head;
  }

  /* Build links out of the data */
  while(len > 0) {
    nbytes = buf->node_size - buf->tail->end;
    if(len < nbytes) nbytes = len;
    
    memcpy(buf->tail->data + buf->tail->end, str, nbytes);
    str += nbytes;    
    len -= nbytes;
    
    buf->tail->end += nbytes;

    if(len > 0) {
      buf->tail->next = buffer_node_new(buf);
      buf->tail = buf->tail->next;
    }
  }
}

/* Read data from the buffer (and clear what we've read) */
static void buffer_read(struct buffer *buf, char *str, unsigned len)
{
  unsigned nbytes;
  struct buffer_node *tmp;

  while(buf->size > 0 && len > 0) {
    nbytes = buf->head->end - buf->head->start;
    if(len < nbytes) nbytes = len;

    memcpy(str, buf->head->data + buf->head->start, nbytes);
    str += nbytes;
    len -= nbytes;

    buf->head->start += nbytes;
    buf->size -= nbytes;

    if(buf->head->start == buf->head->end) {
      tmp = buf->head;
      buf->head = tmp->next;
      buffer_node_free(buf, tmp);

      if(!buf->head) buf->tail = 0;
    }
  }
}

/* Copy data from the buffer without clearing it */
static void buffer_copy(struct buffer *buf, char *str, unsigned len)
{
  unsigned nbytes;
  struct buffer_node *node;

	node = buf->head;
  while(node && len > 0) {
    nbytes = node->end - node->start;
    if(len < nbytes) nbytes = len;

    memcpy(str, node->data + node->start, nbytes);
    str += nbytes;
    len -= nbytes;

    if(node->start + nbytes == node->end)
			node = node->next;
  }
}

/* Write data from the buffer to a file descriptor */
static int buffer_write_to(struct buffer *buf, int fd)
{
  int bytes_written, total_bytes_written = 0;
  struct buffer_node *tmp;

  while(buf->head) {
    bytes_written = write(fd, buf->head->data + buf->head->start, buf->head->end - buf->head->start);

    /* If the write failed... */
    if(bytes_written < 0) {
      if(errno != EAGAIN)
        rb_sys_fail("write");

      return total_bytes_written;
    }

    total_bytes_written += bytes_written;
    buf->size -= bytes_written;

    /* If the write blocked... */
    if(bytes_written < buf->head->end - buf->head->start) {
      buf->head->start += bytes_written;
      return total_bytes_written;
    }

    /* Otherwise we wrote the whole buffer */
    tmp = buf->head;
    buf->head = tmp->next;
    buffer_node_free(buf, tmp);

    if(!buf->head) buf->tail = 0;
  }

  return total_bytes_written;
}

/* Read data from a file descriptor to a buffer */
/* Append data to the front of the buffer */
static int buffer_read_from(struct buffer *buf, int fd)
{
	int bytes_read, total_bytes_read = 0;
  unsigned nbytes;

  /* Empty list needs initialized */
  if(!buf->head) {
    buf->head = buffer_node_new(buf);
    buf->tail = buf->head;
  }

	do {
	  nbytes = buf->node_size - buf->tail->end;
		bytes_read = read(fd, buf->tail->data + buf->tail->end, nbytes);
	
		if(bytes_read < 1) {
			if(errno != EAGAIN)
        rb_sys_fail("read");
			
			return total_bytes_read;
		}
		
		total_bytes_read += bytes_read; 
		buf->tail->end += nbytes;
		buf->size += nbytes;
		
		if(buf->tail->end == buf->node_size) {
      buf->tail->next = buffer_node_new(buf);
      buf->tail = buf->tail->next;
		}
	} while(bytes_read == nbytes);
	
	return total_bytes_read;
}

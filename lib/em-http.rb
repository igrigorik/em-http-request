#--
# Copyright (C)2008 Ilya Grigorik
# You can redistribute this under the terms of the Ruby license
# See file LICENSE for details
#++

require 'rubygems'
require 'eventmachine'
require 'zlib'

require 'http11_client'
require 'em_buffer'

require 'em-http/client'
require 'em-http/multi'
require 'em-http/request'
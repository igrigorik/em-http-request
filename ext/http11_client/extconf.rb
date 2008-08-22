require 'mkmf'

dir_config("http11_client")
have_library("c", "main")

create_makefile("http11_client")

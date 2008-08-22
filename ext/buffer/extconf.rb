require 'mkmf'

libs = []

$defs << "-DRUBY_VERSION_CODE=#{RUBY_VERSION.gsub(/\D/, '')}"

if have_func('rb_thread_blocking_region')
  $defs << '-DHAVE_RB_THREAD_BLOCKING_REGION'
end

if have_func('rb_str_set_len')
  $defs << '-DHAVE_RB_STR_SET_LEN'
end

if have_header('sys/select.h')
  $defs << '-DEV_USE_SELECT'
end

if have_header('poll.h')
  $defs << '-DEV_USE_POLL'
end

if have_header('sys/epoll.h')
  $defs << '-DEV_USE_EPOLL'
end

if have_header('sys/event.h') and have_header('sys/queue.h')
  $defs << '-DEV_USE_KQUEUE'
end

if have_header('port.h')
  $defs << '-DEV_USE_PORT'
end

if have_header('openssl/ssl.h')
  $defs << '-DHAVE_OPENSSL_SSL_H'
  libs << '-lssl -lcrypto'
end

# ncpu detection specifics
case RUBY_PLATFORM
when /linux/
  $defs << '-DHAVE_LINUX_PROCFS'
else
  if have_func('sysctlbyname', ['sys/param.h', 'sys/sysctl.h'])
    $defs << '-DHAVE_SYSCTLBYNAME'
  end
end

$LIBS << ' ' << libs.join(' ')

dir_config('em_buffer')
create_makefile('em_buffer')

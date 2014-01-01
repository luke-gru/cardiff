require 'mkmf'
require 'rbconfig'
RUBY_LIBDIR = RbConfig::CONFIG['libdir']
RUBY_INCLUDEDIR = RbConfig::CONFIG['includedir']

vendor_diffutils_dir = File.expand_path('../../vendor/diffutils/', __FILE__)
Dir.chdir(vendor_diffutils_dir) do
  puts 'configuring...'
  system('./configure')
  status = $?.exitstatus
  unless status == 0
    abort "CONFIGURATION ERROR: configuration failed with status: #{status}"
  end
end

vendor_diffutils_srcdir = File.join(vendor_diffutils_dir, 'src')
vendor_diffutils_libdir = File.join(vendor_diffutils_dir, 'lib')

unless File.directory?(vendor_diffutils_srcdir)
  abort "vendor/diffutils/scr not found"
end

HEADER_DIRS = [
  vendor_diffutils_srcdir,
  vendor_diffutils_libdir,
  '/opt/local/include',
  '/usr/local/include',
  RUBY_INCLUDEDIR,
  '/usr/include'
]

LIB_DIRS = [
  '/opt/local/lib',
  '/usr/local/lib',
  RUBY_LIBDIR,
  '/usr/lib'
]

extension_name = 'cardiff_gnu_diff'
dir_config(extension_name, HEADER_DIRS, LIB_DIRS)

create_header

create_makefile(extension_name)

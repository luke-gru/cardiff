require 'mkmf'
require 'rbconfig'

RUBY_LIBDIR = RbConfig::CONFIG['libdir']
RUBY_INCLUDEDIR = RbConfig::CONFIG['includedir']

vendor_diffutils_dir = File.expand_path('../../vendor/diffutils/', __FILE__)
vendor_diffutils_srcdir = File.join(vendor_diffutils_dir, 'src')
vendor_diffutils_libdir = File.join(vendor_diffutils_dir, 'lib')

Dir.chdir(vendor_diffutils_dir) do

  unless File.exist?(File.join(vendor_diffutils_libdir, 'config.h'))
    puts 'Running configure'
    system('./configure')
    status = $?.exitstatus
    unless status == 0
      abort "CONFIGURATION ERROR: configuration failed with status: #{status}"
    end
  end

  puts "Running make"
  system('make')
  status = $?.exitstatus
  unless status == 0
    abort "MAKE ERROR: make failed with status: #{status}"
  end
end


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
  vendor_diffutils_libdir,
  '/opt/local/lib',
  '/usr/local/lib',
  RUBY_LIBDIR,
  '/usr/lib'
]

$LOCAL_LIBS << File.join(vendor_diffutils_libdir, 'libdiffutils.a')

SRCOBJS = Dir[File.join(vendor_diffutils_srcdir, '*.o')].to_a.reject { |obj| %r(cmp|sdiff|diff3) =~ obj }
SRCOBJS.each do |obj|
  $LOCAL_LIBS << " #{obj}"
end

LIBOBJS = Dir[File.join(vendor_diffutils_libdir, '*.o')].to_a
LIBOBJS.each do |obj|
  $LOCAL_LIBS << " #{obj}"
end

extension_name = 'cardiff_gnu_diff'

#dir_config('libdiffutils', HEADER_DIRS, LIB_DIRS)

#unless have_library('diffutils')
  #abort "libdiffutils not found"
#end

dir_config(extension_name, HEADER_DIRS, LIB_DIRS)

create_header

create_makefile(extension_name)

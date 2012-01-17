module Pkgbuild_Detection
  def detect_build_system
    if File.exists? 'CMakeLists.txt'
      # cmake
      @makedepends << 'cmake'
      @build_system = 'cmake'
    elsif File.exists? 'configure'
      # gnu autoconf generated
      @build_system = 'gnu'

      if File.read('Makefile.in').match /^check:/
	@check_target = "check"
      end
    end
    puts "#{@build_system} build system detected"
  end

  def detect_arch
    native_extensions = ['c','C', 'cc', 'cxx', 'cpp', 'h', 'f', 'asm']
    native_files = []
    native_extensions.each {|ext| native_files += Dir.glob('**/*\.' + ext)}

    if native_files.empty?
      @arch << 'any'
    else
      @arch << 'i686' << 'x86_64'
    end
  end

  def detect_license
    if File.exists?('COPYING') && File.read('COPYING').match(/Version 2, June 1991/)
      @license << 'GPL'
    end
  end
end

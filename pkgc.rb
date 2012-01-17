#!/usr/bin/env ruby

class Pkgbuild
  def initialize
    # used to set the maintainer tag at the top
    @maintainer = ""
    # variables set in the PKGBUILD
    @pkgname, @pkgdesc, @url = *Array.new(3) { "" }
    # can't really extract pkgver and pkgrel
    @pkgver, @pkgrel = *Array.new(2) { "1" }
    # variables set in the PKGBUILD
    @arch, @license, @depends, @checkdepends, @makedepends, @source, @md5sums = *Array.new(7) { [] }
    # used to specify if this is a -git, -svn, etc. package
    @development = false
    @repository_url, @repository_name = *Array.new(2) { "" }
    # the name of the directory that will hold the sourcecode, under src/
    @source_directory = ""
    # type of build system detected, "cmake", etc.
    @build_system = ""
    # type of checks if any
    @check_target = ""
    # this will hold our PKGBUILD contents
    @PKGBUILD = ""
  end

  def run
    # read ~/.pkgc/maintainer if not detected, ask for it the first time and write it
    read_maintainer

    ask_pkgname
    ask_pkgdesc
    ask_url

    # create a folder to store all our work into
    Dir.mkdir @pkgname
    Dir.chdir @pkgname

    pkgbuild_save_path = File.join(Dir.pwd, 'PKGBUILD')

    ask_source
    #exit true
    # should be cd'ed into pkgname/src/src_folder by now

    detect_license
    detect_build_system
    detect_arch

    File.write(pkgbuild_save_path, contents)
  end

  private

  def detect_build_system
    if File.exists? 'CMakeLists.txt'
      # cmake
      makedepends << 'cmake'
      @build_system = 'cmake'
    end
    if File.exists? 'configure'
      # gnu autoconf generated
      @build_system = 'gnu'

      if File.read('Makefile.in').match /^check:/
	@check_target = "check"
      end
    end
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
    if File.read('COPYING').match /Version 2, June 1991/
      @license << 'GPL'
    end
  end

  def write path
    pkgbuild_path = File.join path, 'PKGBUILD'
    File.write pkgbuild_path, contents
  end

  def ask_pkgname
    @pkgname = ask 'What is the package name (pkgname) you want to use?'

    if @pkgname.match /^(.+)-(svn|git|cvs|hg|bzr|darcs)$/
      @repository_name = $1
      @development = $2
      case @development
      when "svn"
	@makedepends << "subversion"
      when "git"
	@makedepends << "git"
      when "cvs"
	@makedepends << "cvs"
      when "hg"
	@makedepends << "mercurial"
      when "bzr"
	@makedepends << "bzr"
      when "darcs"
	@makedepends << "darcs"
      end
    end
  end

  def ask_pkgdesc
    @pkgdesc = ask 'What is the description for the package?'
  end

  def ask_url
    @url = ask 'What is the url or homepage for the package?'
  end

  def ask_source
    Dir.mkdir 'src'

    if @development
      @repository_url = ask "What is the url to the #{@development} repository?"

      Dir.chdir 'src'

      fetch_development_repository @repository_url
    else
      source_url = ask 'Where is the file? (typically the URL to the source)'
      puts "downloading #{source_url}"
      `wget #{source_url}`
      error "failed to get #{source_url}" unless $?.success?
      @source << source_url

      source_filename = File.basename source_url
      @md5sums << `md5sum #{source_filename}`.split[0]

      Dir.chdir 'src'
      `tar xf ../#{source_filename}`
    end
    cur_files = Dir.glob '*'
    error "more than 1 file detected in the toplevel of the source file" if cur_files.size != 1
    @source_directory = cur_files[0]
    Dir.chdir @source_directory
  end

  def fetch_development_repository
    case @development
    when "svn"
      `svn co #{@repository_url}`
    when "git"
      `git clone #{@repository_url}`
    when "cvs"
      `cvs -d #{@repository_url} co #{@repository_name}`
    when "hg"
      `hg clone #{@repository_url}`
    when "bzr"
      `bzr co #{@repository_url}`
    when "darcs"
      `darcs get --partial --set-scripts-executable #{@repository_url}`
    end
  end

  def read_maintainer
    config_dir = File.join ENV['XDG_CONFIG_HOME'], 'pkgc'
    Dir.mkdir config_dir unless File.directory? config_dir
    maintainer_path = File.join config_dir, 'maintainer'
    if File.file? maintainer_path
      @maintainer = File.read maintainer_path
    else
      puts "#{maintainer_path} doesn't exist."
      name = ask "Please enter your name"
      email = ask "Please enter your email (could be obfuscated)"
      @maintainer = "#{name} <#{email}>"
      puts "Writing '#{@maintainer}' to #{maintainer_path}."
      File.write maintainer_path, @maintainer
      puts "This will be your new maintainer tag at the top of new PKGBUILDs."
    end
  end

  def contents
    @PKGBUILD << %{# Maintainer: #{@maintainer}\n}
    @PKGBUILD << %{\n}
    @PKGBUILD << %{pkgname="#{@pkgname}"\n}
    @PKGBUILD << %{pkgver="#{@pkgver}"\n}
    @PKGBUILD << %{pkgrel="#{@pkgrel}"\n}
    @PKGBUILD << %{pkgdesc="#{@pkgdesc}"\n}
    @PKGBUILD << %{arch=#{array_to_bash @arch}\n}
    @PKGBUILD << %{url="#{@url}"\n}
    @PKGBUILD << %{license=#{array_to_bash @license}\n}
    @PKGBUILD << %{depends=#{array_to_bash @depends}\n}
    #@PKGBUILD << %{checkdepends=#{array_to_bash @checkdepends}\n} unless @checkdepends.empty?
    @PKGBUILD << %{makedepends=#{array_to_bash @makedepends}\n} unless @makedepends.empty?
    @PKGBUILD << %{source=#{array_to_bash @source}\n} unless @source.empty?
    @PKGBUILD << %{md5sums=#{array_to_bash @md5sums}\n} unless @md5sums.empty?
    @PKGBUILD << %{\n}

    if @development
      case @development
      when "svn"
	@PKGBUILD << %{_svntrunk="#{@repository_url}"\n}
	@PKGBUILD << %{_svnmod="#{@repository_name}"\n}
      when "git"
	@PKGBUILD << %{_gitroot="#{@repository_url}"\n}
	@PKGBUILD << %{_gitname="#{@repository_name}"\n}
      when "cvs"
	@PKGBUILD << %{_cvsroot="#{@repository_url}"\n}
	@PKGBUILD << %{_cvsmod="#{@repository_name}"\n}
      when "hg"
	@PKGBUILD << %{_hgroot="#{@repository_url}"\n}
	@PKGBUILD << %{_hgrepo="#{@repository_name}"\n}
      when "bzr"
	@PKGBUILD << %{_bzrtrunk="#{@repository_url}"\n}
	@PKGBUILD << %{_bzrmod="#{@repository_name}"\n}
      when "darcs"
	@PKGBUILD << %{_darcstrunk="#{@repository_url}"\n}
	@PKGBUILD << %{_darcsmod="#{@repository_name}"\n}
      end
      @PKGBUILD << %{\n}
    end

    @PKGBUILD << %|build() {\n|
    # TODO: clone and update if development
    if @build_system == "cmake"
      @PKGBUILD << %{  rm -rf build\n}
      @PKGBUILD << %{  mkdir build\n}
      @PKGBUILD << %{  cd build\n}
      @PKGBUILD << %{\n}
      @PKGBUILD << %{  cmake \\\n}
      @PKGBUILD << %{    -DCMAKE_INSTALL_PREFIX:FILEPATH=/usr \\\n}
      @PKGBUILD << %{    -DCMAKE_BUILD_TYPE:STRING=Release \\\n}
      @PKGBUILD << %{    ../#{@source_directory}\n}
      @PKGBUILD << %{\n}
      @PKGBUILD << %{  make\n}
      @PKGBUILD << %|}\n|

      @PKGBUILD << %{\n}

      @PKGBUILD << %|package() {\n|
      @PKGBUILD << %{  cd build\n}
      @PKGBUILD << %{\n}
      @PKGBUILD << %{  make DESTDIR=${pkgdir} install\n}
    elsif @build_system == "gnu"
      @PKGBUILD << %{  cd #{@source_directory}\n}
      @PKGBUILD << %{\n}
      @PKGBUILD << %{  ./configure \\\n}
      @PKGBUILD << %{    --prefix=/usr\n}
      @PKGBUILD << %{\n}
      @PKGBUILD << %{  make\n}
      @PKGBUILD << %|}\n|

      @PKGBUILD << %{\n}

      unless @check_target.empty?
	@PKGBUILD << %|check() {\n|
	@PKGBUILD << %{  cd #{@source_directory}\n}
	@PKGBUILD << %{\n}
	@PKGBUILD << %{  make #{@check_target}\n}
	@PKGBUILD << %|}\n|
	@PKGBUILD << %{\n}
      end

      @PKGBUILD << %|package() {\n|
      @PKGBUILD << %{  cd #{@source_directory}\n}
      @PKGBUILD << %{\n}
      @PKGBUILD << %{  make DESTDIR=${pkgdir} install\n}
    end
    @PKGBUILD << %|}\n|

    @PKGBUILD
  end

  def array_to_bash array
    quoted_array = array.map {|item| "'" + item + "'"}
    "(" + quoted_array.join(" ") + ")"
  end

  def ask prompt
    puts prompt
    gets.chomp
  end

  def error message
    print 'error: '
    puts message
    exit false
  end
end

pkgbuild = Pkgbuild.new
pkgbuild.run

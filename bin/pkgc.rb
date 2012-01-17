#!/usr/bin/env ruby

require "PkgcHelpers"
require "Pkgbuild_Hooks"
require "Pkgbuild_Detection"

class Pkgbuild
  include PkgcHelpers
  include Pkgbuild_Hooks
  include Pkgbuild_Detection

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
    @repository_url_varname, @repository_name_varname = *Array.new(2) { "" }
    @repository_url, @repository_name = *Array.new(2) { "" }
    # the name of the directory that will hold the sourcecode, under src/
    @source_directory, @build_directory = *Array.new(2) { "" }
    # type of build system detected, "cmake", "gnu"
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

    File.write(pkgbuild_save_path, pkgbuild_contents)
  end

  private

  def pkgbuild_contents
    hook_maintainer

    hook_newline

    hook_pkgname
    hook_pkgver
    hook_pkgrel
    hook_pkgdesc
    hook_arch
    hook_url
    hook_license
    hook_depends
    hook_checkdepends
    hook_makedepends
    hook_source
    hook_md5sums

    hook_newline

    hook_development_vars

    @PKGBUILD << %|build() {\n|

    hook_development_clone_pull

    if @build_system == "cmake"
      hook_build_system_cmake
    elsif @build_system == "gnu"
      hook_build_system_gnu
    end

    @PKGBUILD << %|}\n|

    @PKGBUILD
  end
end

pkgbuild = Pkgbuild.new
pkgbuild.run

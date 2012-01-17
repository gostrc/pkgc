module Pkgbuild_Hooks
  # {{{ build system hooks
  def hook_build_system_cmake
    @PKGBUILD << %{  rm -rf build\n}
    @PKGBUILD << %{  mkdir build\n}
    @PKGBUILD << %{  cd build\n}
    hook_newline
    @PKGBUILD << %{  cmake \\\n}
    @PKGBUILD << %{    -DCMAKE_INSTALL_PREFIX:FILEPATH=/usr \\\n}
    @PKGBUILD << %{    -DCMAKE_BUILD_TYPE:STRING=Release \\\n}
    @PKGBUILD << %{    ${srcdir}/#{@source_directory}\n}
    hook_newline
    @PKGBUILD << %{  make\n}
    @PKGBUILD << %|}\n|

    hook_newline

    @PKGBUILD << %|package() {\n|
    @PKGBUILD << %{  cd build\n}
    hook_newline
    @PKGBUILD << %{  make DESTDIR=${pkgdir} install\n}
  end

  def hook_build_system_gnu
    @PKGBUILD << %{  cd #{@source_directory}\n}
    hook_newline
    @PKGBUILD << %{  ./configure \\\n}
    @PKGBUILD << %{    --prefix=/usr\n}
    hook_newline
    @PKGBUILD << %{  make\n}
    @PKGBUILD << %|}\n|

    hook_newline

    unless @check_target.empty?
      @PKGBUILD << %|check() {\n|
      @PKGBUILD << %{  cd #{@source_directory}\n}
      hook_newline
      @PKGBUILD << %{  make #{@check_target}\n}
      @PKGBUILD << %|}\n|
      hook_newline
    end

    @PKGBUILD << %|package() {\n|
    @PKGBUILD << %{  cd #{@source_directory}\n}
    hook_newline
    @PKGBUILD << %{  make DESTDIR=${pkgdir} install\n}
  end
  # }}}

  # {{{ development version hooks
  def hook_development_vars
    if @development
      @PKGBUILD << %{#{@repository_url_varname}="#{@repository_url}"\n}
      @PKGBUILD << %{#{@repository_name_varname}="#{@repository_name}"\n}
      hook_newline
    end
  end

  def hook_development_clone_pull
    if @development
      pkgbuild_clone_command = {
	"svn" => %{svn co ${_svntrunk} --config-dir ./ -r ${pkgver} ${_svnmod}},
	"git" => %{git clone ${_gitroot} ${_gitname}},
	"cvs" => %{cvs -z3 -d ${_cvsroot} co -D ${pkgver} -f ${_cvsmod}},
	"hg" => %{hg clone ${_hgroot} ${_hgrepo}},
	"bzr" => %{bzr --no-plugins branch ${_bzrtrunk} ${_bzrmod} -q -r ${pkgver}},
	"darcs" => %{darcs get --partial --set-scripts-executable ${_darcstrunk}/${_darcsmod}}
      }
      pkgbuild_pull_command = {
	"svn" => %{svn up -r ${pkgver}},
	"git" => %{git pull origin},
	"cvs" => %{cvs -z3 update -d},
	"hg" => %{hg pull -u},
	"bzr" => %{bzr --no-plugins pull ${_bzrtrunk} -r ${pkgver}},
	"darcs" => %{darcs pull -a ${_darcstrunk}/${_darcsmod}}
      }

      @PKGBUILD << %{  msg "Connecting to #{@development} server..."\n}
      @PKGBUILD << %{  if [[ -d ${#{@repository_name_varname}} ]]; then\n}
      @PKGBUILD << %{    msg "Updating existing repository"\n}
      @PKGBUILD << %{    cd ${#{@repository_name_varname}}\n}
      @PKGBUILD << %{    #{pkgbuild_pull_command[@development]}\n}
      @PKGBUILD << %{  else\n}
      @PKGBUILD << %{    msg "Retrieving entire repository"\n}
      @PKGBUILD << %{    #{pkgbuild_clone_command[@development]}\n}
      @PKGBUILD << %{  fi\n}
      hook_newline
      @PKGBUILD << %{  msg "#{@development} checkout done"\n}
      @PKGBUILD << %{  msg "Starting build..."\n}
      hook_newline
    end
  end
  # }}}

  # {{{ single variable hooks
  def hook_maintainer
    @PKGBUILD << %{# Maintainer: #{@maintainer}\n}
  end

  def hook_newline
    @PKGBUILD << %{\n}
  end

  def hook_pkgname
    @PKGBUILD << %{pkgname="#{@pkgname}"\n}
  end

  def hook_pkgver
    @PKGBUILD << %{pkgver="#{@pkgver}"\n}
  end

  def hook_pkgrel
    @PKGBUILD << %{pkgrel="#{@pkgrel}"\n}
  end

  def hook_pkgdesc
    @PKGBUILD << %{pkgdesc="#{@pkgdesc}"\n}
  end

  def hook_arch
    @PKGBUILD << %{arch=#{array_to_bash @arch}\n}
  end

  def hook_url
    @PKGBUILD << %{url="#{@url}"\n}
  end
  
  def hook_license
    @PKGBUILD << %{license=#{array_to_bash @license}\n}
  end

  def hook_depends
    @PKGBUILD << %{depends=#{array_to_bash @depends}\n}
  end

  def hook_checkdepends
    @PKGBUILD << %{checkdepends=#{array_to_bash @checkdepends}\n} unless @checkdepends.empty?
  end

  def hook_makedepends
    @PKGBUILD << %{makedepends=#{array_to_bash @makedepends}\n} unless @makedepends.empty?
  end

  def hook_source
    @PKGBUILD << %{source=#{array_to_bash @source}\n} unless @source.empty?
  end

  def hook_md5sums
    @PKGBUILD << %{md5sums=#{array_to_bash @md5sums}\n} unless @md5sums.empty?
  end
  # }}}
end

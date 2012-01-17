module PkgcHelpers
  def ask_pkgname
    @pkgname = ask 'What is the package name (pkgname) you want to use?'

    if @pkgname.match /^(.+)-(svn|git|cvs|hg|bzr|darcs)$/
      @repository_name = $1
      @development = $2
      development_makedepends = {
	"svn" => "subversion",
	"git" => "git",
	"cvs" => "cvs",
	"hg" => "mercurial",
	"bzr" => "bzr",
	"darcs" => "darcs"
      }
      repository_url_varname = {
	"svn" => "_svntrunk",
	"git" => "_gitroot",
	"cvs" => "_cvsroot",
	"hg" => "_hgroot",
	"bzr" => "_bzrtrunk",
	"darcs" => "_darcstrunk"
      }
      repository_name_varname = {
	"svn" => "_svnmod",
	"git" => "_gitname",
	"cvs" => "_cvsmod",
	"hg" => "_hgrepo",
	"bzr" => "_bzrmod",
	"darcs" => "_darcsmod"
      }
      @makedepends << development_makedepends[@development]
      @repository_url_varname = repository_url_varname[@development]
      @repository_name_varname = repository_name_varname[@development]
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

    if @development
      @build_directory = "#{@source_directory}-build"
    else
      @build_directory = @source_directory
    end
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

  # converts a ruby array into a bash array, returns a string
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

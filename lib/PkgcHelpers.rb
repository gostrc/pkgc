module PkgcHelpers
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

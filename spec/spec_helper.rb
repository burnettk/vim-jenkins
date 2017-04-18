require 'vimrunner'
require 'vimrunner/rspec'

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  config.start_vim do
    vim = Vimrunner.start
    plugin_path = File.expand_path('../..', __FILE__)
    vim.add_plugin(plugin_path, 'plugin/jenkins.vim')
    vim
  end

  # takes a filename argument like app/js/blah.js and
  # creates the directory structure if it doesn't already exist
  def safe_write_file(filename)
    dirname = File.dirname(filename)
    if !File.directory?(dirname)
      FileUtils.mkdir_p dirname
    end
    write_file(filename, "")
  end

  def current_file_name
    vim.echo 'bufname("%")'
  end

  # takes any number of filenames as arguments and creates each as an empty file
  def setup_filesystem(*args)
    args.each do |filename|
      safe_write_file(filename)
    end
  end

  def assume_vimrc(command)
    vim.command(command)
  end

  def assume_blank_vimrc_by_unsetting_any_global_variables
    vim.command('function JenkinsShellOutToCurl(curlCommand)
  return {}
endfunction')
  end

end

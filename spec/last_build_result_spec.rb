require "spec_helper"

describe "alternate" do

  before do
    assume_blank_vimrc_by_unsetting_any_global_variables
  end

	# FIXME: need to make this test actually test something
  specify "JenkinsShowLastBuildResult should run the appropriate curl" do
    setup_filesystem('hot_file')
    vim.edit 'hot_file'
    vim.normal('')
    vim.type(':echom "sure enough"<cr>')
    puts vim.command(':messages')
    vim.command('cal JenkinsShowLastBuildResult()')
    vim.command('cal JenkinsShellOutToCurl("ls")')
    vim.command('echom "hotness"')
    puts vim.command(':messages')
  end

end

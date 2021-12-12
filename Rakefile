# for vimrunner
# require 'rspec/core/rake_task'
#
# RSpec::Core::RakeTask.new
#
# task :default => :spec

task :ci => [:dump, :test]

task :dump do
  sh 'vim --version'
end

task :test do
  sh 'bundle exec vim-flavor test ./test/jenkins.vim'
end

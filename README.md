# jenkins.vim

Do you use Jenkins? Do you use vim? Do you like cute features?

## Setup

You need to be using Jenkinsfiles for any of this to work. If you don't already
use them, stop clawing your eyes out by typing and clicking around in your CI
system and put your build plan configurations into source control for crying out
loud.

After you install via the instructions below, in your .vimrc, configure your
jenkins url and some credentials that can get you in there:

    let g:jenkins_url = 'https://jenkins.example.com'
    let g:jenkins_username = 'ci'
    let g:jenkins_password = 'ci'

## Features

### Find current build status

In your Jenkinfile, add a comment like this:

    // BUILD_PATH: /view/Sweetapps/job/hot-app/job/master

Then, call JenkinsShowLastBuildResult by using the "jenkins build" shortcut:

    <Leader>jb

### Validate Jenkinsfile

Call JenkinsValidateJenkinsFile by using the "jenkins Jenkinsfile" shortcut:
    
    <Leader>jj

Major props to the Jenkins guys for providing this killer feature via the API.

## Installation

* Using [Pathogen][pathogen], run the following commands:

        % cd ~/.vim/bundle
        % git clone git://github.com/burnettk/vim-jenkins.git

* Using [Vundle][vundle], add the following to your `vimrc` and then run
  `:PluginInstall`

        Plugin 'burnettk/vim-jenkins'

Once help tags have been generated, you can view the manual with
`:help jenkins`.

## Self-Promotion

Like vim-jenkins.vim? Star the repository on [GitHub][project]. And if you're
feeling especially charitable, follow [me][mysite] on [Twitter][mytwitter] and
[GitHub][mygithub].

## License

Copyright (c) Kevin Burnett.  Distributed under the same terms as Vim itself.
See `:help license`.

[pathogen]: https://github.com/tpope/vim-pathogen
[vundle]: https://github.com/gmarik/vundle
[project]: https://github.com/burnettk/vim-jenkins
[mysite]: http://notkeepingitreal.com
[mytwitter]: http://twitter.com/kbbkkbbk
[mygithub]: https://github.com/burnettk

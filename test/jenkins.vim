runtime plugin/jenkins.vim

describe 'loading_plugin'
  before
    call delete('tmp/test', 'rf')
    call mkdir('tmp/test', 'p')
    cd tmp/test
  end

  after
    cd -
  end

  context 'when loaded'
    it 'returns "-"'
      Expect g:loaded_vim_jenkins ==# 1
    end
  end
end

describe 'setting_jenkins_url'
  context 'default'
    it 'is set'
      Expect g:jenkins_url ==# 'http://jenkins'
    end
  end
  context 'overridden'
    before
      let g:jenkins_url = 'http://my-hot-jenkins'
    end
    it 'is set'
      Expect g:jenkins_url ==# 'http://my-hot-jenkins'
    end
  end
end

" describe 'GetGitBranchName()'
"   before
"     call delete('tmp/test', 'rf')
"     call mkdir('tmp/test', 'p')
"     cd tmp/test
"   end
"
"   after
"     cd -
"   end
"
"   context 'in a non-Git directory'
"     it 'returns "-"'
"       Expect GetGitBranchName('.') ==# '-'
"     end
"   end
"
"   context 'in a Git repository'
"     before
"       !git init && touch foo && git add foo && git commit -m 'Initial commit'
"     end
"
"     it 'returns the current branch'
"       Expect GetGitBranchName('.') ==# 'master'
"     end
"
"     it 'detects detached HEAD state'
"       !git checkout master~0
"       Expect GetGitBranchName('.') ==# 'master~0'
"     end
"   end
" end

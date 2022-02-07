runtime plugin/jenkins.vim

function! GetAllLogMessages()
  " https://stackoverflow.com/a/5442225/6090676
  redir => l:messages
  messages
  redir END
  return l:messages
endfunction

function! AssertLastLogMessage(message)
  let l:lastLogMessage = split(GetAllLogMessages(), "\n")[-1]
  Expect l:lastLogMessage ==# a:message
endfunction

function! JenkinsFoundJenkinsfilePath() "{{{
  let l:jenkinsfileFilename = "Jenkinsfile"
  if filereadable(l:jenkinsfileFilename)
    return l:jenkinsfileFilename
  else
    if CurrentFilePathLooksLikeJenkinsfile(l:currentFilename) && filereadable(l:currentFilename)
      return l:currentFilename
    else
      " we will later check empty() to see if we found a path
      return ''
    endif
  endif
endfunction "}}}

unlet g:loaded_vim_jenkins
source plugin/jenkins.vim

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
    it 'returns 1'
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

describe 'JenkinsFoundJenkinsfilePath()'
  context 'with Jenkinsfile'
    before
      !touch Jenkinsfile
    end
    it 'finds it'
      Expect JenkinsFoundJenkinsfilePath() ==# 'Jenkinsfile'
    end
  end
end

describe 'JenkinsFoundJenkinsfilePath() in tmp/test'
  before
    call delete('tmp/test', 'rf')
    call mkdir('tmp/test', 'p')
    cd tmp/test
    !rm Jenkinsfile
  end

  after
    cd -
  end

  context 'with Jenkinsfile in tmp/test'
    before
      new
      w Jenkinsfile
    end
    after
      close!
    end
    it 'finds it'
      Expect JenkinsFoundJenkinsfilePath() ==# 'Jenkinsfile'
    end
  end

  context 'with hot.jenkinsfile'
    before
      new
      w hot.jenkinsfile
    end
    after
      close!
    end
    it 'finds it'
      Expect JenkinsFoundJenkinsfilePath() =~# 'hot.jenkinsfile$'
    end
  end
end

describe 'JenkinsHasBuildPlanPathInJenkinsfile()'
  before
    call delete('tmp/test', 'rf')
    call mkdir('tmp/test', 'p')
    cd tmp/test
  end

  after
    cd -
  end

  context 'with path'
    before
      new
      put! = '// BUILD_PLAN_PATH: /job/hot-dir/job/hot-app/main'
      w Jenkinsfile
    end
    after
      close!
    end
    it 'finds it'
      Expect JenkinsHasBuildPlanPathInJenkinsfile('Jenkinsfile') to_be_true
    end
  end

  context 'with no path'
    before
      new
      w Jenkinsfile
    end
    after
      close!
    end
    it 'finds nothing since nothing is there'
      Expect JenkinsHasBuildPlanPathInJenkinsfile('Jenkinsfile') to_be_false
    end
  end
end

describe 'JenkinsBuildPlanPathFromJenkinsfile()'
  before
    call delete('tmp/test', 'rf')
    call mkdir('tmp/test', 'p')
    cd tmp/test
  end

  after
    cd -
  end

  context 'with path'
    before
      new
      put! = '// BUILD_PLAN_PATH: /job/hot-dir/job/hot-app/main'
      w Jenkinsfile
    end
    after
      close!
    end
    it 'finds it'
      Expect JenkinsBuildPlanPathFromJenkinsfile('Jenkinsfile') ==# '/job/hot-dir/job/hot-app/main'
    end
  end

  context 'with no path'
    before
      new
      w Jenkinsfile
    end
    after
      close!
    end
    it 'finds nothing since nothing is there'
      Expect JenkinsBuildPlanPathFromJenkinsfile('Jenkinsfile') ==# ''
    end
  end
end

describe 'JenkinsJsonParse()'
  before
    call delete('tmp/test', 'rf')
    call mkdir('tmp/test', 'p')
    cd tmp/test
  end

  after
    cd -
  end

  context 'with hot json'
    before
      !touch Jenkinsfile
    end
    it 'parses it'
      Expect JenkinsJsonParse('{"hot": "json"}') ==# {"hot": "json"}
      Expect JenkinsJsonParse('{"hot": "json"}')["hot"] ==# "json"
    end
  end
end

describe 'JenkinsChomp()'
  it 'removes trailing newlines'
    Expect JenkinsChomp("hey\n\n\n") ==# 'hey'
  end
end

describe 'JenkinsValidateJenkinsFile()'
  before
    call delete('tmp/test', 'rf')
    call mkdir('tmp/test', 'p')
    cd tmp/test
  end

  after
    cd -
  end

  context 'when no Jenkinsfile'
    it 'prints an error'
      call JenkinsValidateJenkinsFile()
      call AssertLastLogMessage("This functionality requires a Jenkinsfile")
    end
  end
  " context 'when no Jenkinsfile'
  "   before
  "     new
  "     put! = '// BUILD_PLAN_PATH: /job/hot-dir/job/hot-app/main'
  "     w Jenkinsfile
  "   end
  "   after
  "     close!
  "   end
  "   it 'finds it'
  "     Expect JenkinsBuildPlanPathFromJenkinsfile('Jenkinsfile') ==# '/job/hot-dir/job/hot-app/main'
  "   end
  " end
  "
  " context 'with no path'
  "   before
  "     new
  "     w Jenkinsfile
  "   end
  "   after
  "     close!
  "   end
  "   it 'finds nothing since nothing is there'
  "     Expect JenkinsBuildPlanPathFromJenkinsfile('Jenkinsfile') ==# ''
  "   end
  " end
end

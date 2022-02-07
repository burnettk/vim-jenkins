" jenkins.vim
" Maintainer:	Kevin Burnett
" Last Change: 2021

if exists("g:loaded_vim_jenkins")
  finish
endif
let g:loaded_vim_jenkins = 1

if !exists('g:jenkins_url')
  let g:jenkins_url = 'http://jenkins'
endif

function! CurrentFilePathLooksLikeJenkinsfile(currentFilename) "{{{
  return a:currentFilename =~ ".jenkinsfile$" || a:currentFilename =~ "Jenkinsfile$"
endfunction "}}}

function! JenkinsFoundJenkinsfilePath() "{{{
  let l:jenkinsfileFilename = "Jenkinsfile"
  if filereadable(l:jenkinsfileFilename)
    return l:jenkinsfileFilename
  else
    let l:currentFilename = expand('%:p')
    if CurrentFilePathLooksLikeJenkinsfile(l:currentFilename) && filereadable(l:currentFilename)
      return l:currentFilename
    else
      " we will later check empty() to see if we found a path
      return ''
    endif
  endif
endfunction "}}}

function! JenkinsHasBuildPlanPathInJenkinsfile(fullJenkinsfilePath) "{{{
  return match(readfile(a:fullJenkinsfilePath), "BUILD_PLAN_PATH") != -1
endfunction "}}}"

function! JenkinsBuildPlanPathFromJenkinsfile(fullJenkinsfilePath) "{{{
  let l:findBuildPlanCommand = 'grep BUILD_PLAN_PATH ' . a:fullJenkinsfilePath . ' | sed -e "s/.*BUILD_PLAN_PATH: //g"'
  return JenkinsChomp(system(l:findBuildPlanCommand))
endfunction "}}}"

" LAST BUILD RESULT
function! JenkinsShowLastBuildResult() "{{{
  let l:basic_auth_options = ''
  if exists('g:jenkins_username')
    let l:basic_auth_options = '-u ' . g:jenkins_username . ':' . g:jenkins_password
  endif

  let l:fullJenkinsfilePath = JenkinsFoundJenkinsfilePath()
  if !empty(l:fullJenkinsfilePath)
    " check if Jenkinsfile includes BUILD_PLAN_PATH. otherwise error.
    if JenkinsHasBuildPlanPathInJenkinsfile(l:fullJenkinsfilePath)
      let l:jenkins_build_plan_path_from_jenkinsfile = JenkinsBuildPlanPathFromJenkinsfile(l:fullJenkinsfilePath)

      let l:jenkins_build_plan_api_path = l:jenkins_build_plan_path_from_jenkinsfile . '/lastCompletedBuild/api/json'
      let l:jenkins_build_plan_url = g:jenkins_url . l:jenkins_build_plan_api_path
      call JenkinsLogStuff('Fetching: ' . l:jenkins_build_plan_url)

      let l:build_info_response = JenkinsChomp(JenkinsShellOutToCurl('curl -s ' . l:jenkins_build_plan_url . ' ' . l:basic_auth_options))
      let l:build_info = JenkinsJsonParse(JenkinsChomp(l:build_info_response))
      call JenkinsLogStuff(l:build_info['fullDisplayName'])
      call JenkinsLogStuff(l:build_info['result'])
    else
      call JenkinsLogStuff('Jenkinsfile must include a BUILD_PLAN_PATH to use the show last build function')
    endif
  else
    call JenkinsNoJenkinsfileError()
  endif
endfunction "}}}

command! JenkinsShowLastBuildResult call JenkinsShowLastBuildResult()

let g:jenkins_enable_mappings = get(g:, 'jenkins_enable_mappings', 1)

if g:jenkins_enable_mappings == 1
  nnoremap <Leader>jb :JenkinsShowLastBuildResult<CR>
endif


" REBUILD BUILDNUM
function! JenkinsRebuild(buildNumber) "{{{
  let l:basic_auth_options = ''
  if exists('g:jenkins_username')
    let l:basic_auth_options = '-u ' . g:jenkins_username . ':' . g:jenkins_password
  endif

  let l:fullJenkinsfilePath = JenkinsFoundJenkinsfilePath()
  if !empty(l:fullJenkinsfilePath)
    " check if Jenkinsfile includes BUILD_PLAN_PATH. otherwise error.
    if JenkinsHasBuildPlanPathInJenkinsfile(l:fullJenkinsfilePath)
      " check if build number is a number
      if a:buildNumber !~# '^\d\+$'
        call JenkinsLogStuff('Requires build number')
      else
        let l:basic_auth_options = ''
        if exists('g:jenkins_username')
          let l:basic_auth_options = '-u ' . g:jenkins_username . ':' . g:jenkins_password
        endif
        let l:jenkins_build_plan_path_from_jenkinsfile = JenkinsBuildPlanPathFromJenkinsfile(l:fullJenkinsfilePath)
        let l:jenkins_job_name = JenkinsChomp(substitute(system(l:findBuildPlanCommand),'^.*job/','',''))
  
        " Thanks nirzari
        " https://github.com/nirzari/groovy-scripts
        let l:rebuild_groovy = 'import hudson.model.*\n
          \import jenkins.model.Jenkins\n
          \
          \
          \def jobName = \"' . l:jenkins_job_name . '\"\n
          \
          \def job = Jenkins.instance.getItemByFullName(jobName)\n
          \def build = ' . a:buildNumber . '\n
          \
          \def my_job = job.getBuildByNumber(build)\n
          \def actions = my_job.getActions(ParametersAction)\n
          \println(my_job)\n
          \job.scheduleBuild2(0, actions.toArray(new ParametersAction[actions.size()]))
          \println(\"\")'

        let l:jenkins_script_url = g:jenkins_url . '/scriptText'
        call JenkinsLogStuff('Triggering rebuild')
        execute '!echo -e "' . l:rebuild_groovy . '" > /tmp/rebuild.groovy ; curl ' . l:basic_auth_options . ' --data-urlencode "script=$(< /tmp/rebuild.groovy)" ' . l:jenkins_script_url
      endif
    else
      call JenkinsLogStuff('Jenkinsfile must include a BUILD_PLAN_PATH to use the show last build function')
    endif
  else
    call JenkinsNoJenkinsfileError()
  endif
endfunction "}}}

command! -nargs=1 JenkinsRebuild  call JenkinsRebuild(<f-args>)


" LAST BUILD LOG
function! JenkinsShowLastBuildLog() "{{{
  let l:basic_auth_options = ''
  if exists('g:jenkins_username')
    let l:basic_auth_options = '-u ' . g:jenkins_username . ':' . g:jenkins_password
  endif

  let l:fullJenkinsfilePath = JenkinsFoundJenkinsfilePath()
  if !empty(l:fullJenkinsfilePath)
    if JenkinsHasBuildPlanPathInJenkinsfile(l:fullJenkinsfilePath)
      let l:jenkins_build_plan_path_from_jenkinsfile = JenkinsBuildPlanPathFromJenkinsfile(l:fullJenkinsfilePath)

      let l:jenkins_build_plan_api_path = l:jenkins_build_plan_path_from_jenkinsfile . '/lastBuild/consoleText'
      let l:jenkins_build_plan_url = g:jenkins_url . l:jenkins_build_plan_api_path
      call JenkinsLogStuff('Fetching: ' . l:jenkins_build_plan_url)

      let l:last_build_log = JenkinsChomp(JenkinsShellOutToCurl('curl -s ' . l:jenkins_build_plan_url . ' ' . l:basic_auth_options))
      echo l:last_build_log
    else
      call JenkinsLogStuff('Jenkinsfile must include a BUILD_PLAN_PATH to use the show last build function')
    endif
  else
    call JenkinsNoJenkinsfileError()
  endif
endfunction "}}}

command! JenkinsShowLastBuildLog call JenkinsShowLastBuildLog()

if g:jenkins_enable_mappings == 1
  nnoremap <Leader>jl :JenkinsShowLastBuildLog<CR>
endif


function JenkinsLogStuff(logMessage) "{{{
  echom a:logMessage
  if exists('g:jenkins_log_messages_to_disk_for_tests')
    if g:jenkins_log_messages_to_disk_for_tests == 'true' || g:jenkins_log_messages_to_disk_for_tests == true
      call JenkinsMylog(a:logMessage, 'jenkins.log')
    endif
  endif
endfunction "}}}

" http://stackoverflow.com/questions/23089736/how-do-i-append-text-to-a-file-with-vim-script
function! JenkinsMylog(message, file)
  let l:operation = 'w >>'
  if !filereadable(a:file)
    let l:operation = 'w'
  endif
  new
  setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
  put=a:message
  execute l:operation a:file
  q
endfun

function JenkinsShellOutToCurl(curlCommand) "{{{
  return system(a:curlCommand)
endfunction "}}}

function JenkinsCopyJenkinsfileIntoPlace(fullJenkinsfilePath) "{{{
  execute 'silent !cp ' . a:fullJenkinsfilePath . ' /tmp/Jenkinsfile && perl -pi -e "s/^\@Library\(.*$//g" /tmp/Jenkinsfile && perl -pi -e "s/^import .*$//g" /tmp/Jenkinsfile'
endfunction "}}}

function! JenkinsValidateJenkinsFile() "{{{
  let l:fullJenkinsfilePath = JenkinsFoundJenkinsfilePath()
  if !empty(l:fullJenkinsfilePath)
    let l:basic_auth_options = ''

    if !exists('g:jenkins_validation_username')
      let g:jenkins_validation_username = g:jenkins_username
    endif
    if !exists('g:jenkins_validation_password')
      let g:jenkins_validation_password = g:jenkins_password
    endif

    if exists('g:jenkins_validation_username')
      let l:basic_auth_options = '-u ' . g:jenkins_validation_username . ':' . g:jenkins_validation_password
    endif

    if !exists('g:jenkins_validation_url')
      let g:jenkins_validation_url = g:jenkins_url
    endif

    " This is the only way that works. Let's just write a function that
    " verifies it gets the gigantic string to execute and then mock the
    " function to get the input for testing.
    execute '!cp ' . l:fullJenkinsfilePath . ' /tmp/Jenkinsfile && perl -pi -e "s/^\@Library\(.*$//g" /tmp/Jenkinsfile && perl -pi -e "s/^import .*$//g" /tmp/Jenkinsfile && curl -X POST -F "jenkinsfile=</tmp/Jenkinsfile" ' . g:jenkins_validation_url . '/pipeline-model-converter/validate ' . l:basic_auth_options
    return
    """" NOTE: note the return above, since the rest of this code doesn't work

    call JenkinsCopyJenkinsfileIntoPlace(l:fullJenkinsfilePath)
    if v:shell_error == '0'
      " silent !clear
      " let l:curl_command = 'curl -s -X POST -F "jenkinsfile=</tmp/Jenkinsfile" ' . g:jenkins_validation_url . '/pipeline-model-converter/validate ' . l:basic_auth_options
      " let l:validation_result = JenkinsChomp(JenkinsShellOutToCurl(l:curl_command))
      " echo l:validation_result
      let l:curl_command = 'curl -X POST -F "jenkinsfile=</tmp/Jenkinsfile" ' . g:jenkins_validation_url . '/pipeline-model-converter/validate ' . l:basic_auth_options
      execute '! ' . l:curl_command
      return
    else
      " echom 'v:shell_error'
      " echom v:shell_error
    endif
  else
    call JenkinsNoJenkinsfileError()
  endif
endfunction "}}}

command! JenkinsValidateJenkinsFile call JenkinsValidateJenkinsFile()

if g:jenkins_enable_mappings == 1
  nnoremap <Leader>rj :JenkinsValidateJenkinsFile<CR>
endif

" Helper functions

" credit to http://vi.stackexchange.com/questions/2867/how-do-you-chomp-a-string-in-vim
function! JenkinsChomp(string)
  return substitute(a:string, '\n\+$', '', '')
endfunction

" credit to tpope
function! JenkinsJsonParse(string) abort
  let string = type(a:string) == type([]) ? join(a:string, ' ') : a:string
  if exists('*json_decode')
    return json_decode(string)
  endif
  let [null, false, true] = ['', 0, 1]
  let stripped = substitute(string,'\C"\(\\.\|[^"\\]\)*"','','g')
  if stripped !~# "[^,:{}\\[\\]0-9.\\-+Eaeflnr-u \n\r\t]"
    try
      return eval(substitute(string,"[\r\n]"," ",'g'))
    catch
    endtry
  endif
  throw "invalid JSON: ".string
endfunction

function! JenkinsNoJenkinsfileError() "{{{
  call JenkinsLogStuff('This functionality requires a Jenkinsfile')
endfunction "}}}

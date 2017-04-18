" jenkins.vim
" Maintainer:	Kevin Burnett
" Last Change: 2017 April 12

if !exists('g:jenkins_url')
  let g:jenkins_url = 'http://jenkins'
endif

function! JenkinsShowLastBuildResult() "{{{
  let l:basic_auth_options = ''
  if exists('g:jenkins_username')
		let l:basic_auth_options = '-u ' . g:jenkins_username . ':' . g:jenkins_password
	endif

  if JenkinsHasJenkinsfile()
		if JenkinsJenkinsfileIncludesBuildUrl()
			let l:jenkins_build_plan_path_from_jenkinsfile = JenkinsChomp(system('grep BUILD_PLAN_PATH Jenkinsfile | sed -e "s/.*BUILD_PLAN_PATH: //g"'))

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

nnoremap <Leader>jb :JenkinsShowLastBuildResult<CR>


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

function! JenkinsValidateJenkinsFile() "{{{
  if JenkinsHasJenkinsfile()
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

		execute '!curl -X POST -F "jenkinsfile=<Jenkinsfile" ' . g:jenkins_validation_url . '/pipeline-model-converter/validate ' . l:basic_auth_options
	else
		call JenkinsNoJenkinsfileError()
	endif
endfunction "}}}

command! JenkinsValidateJenkinsFile call JenkinsValidateJenkinsFile()

nnoremap <Leader>jj :JenkinsValidateJenkinsFile<CR>


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

function! JenkinsJenkinsfileIncludesBuildUrl() "{{{
	let l:jenkinsfileFilename = "Jenkinsfile"
	return JenkinsHasJenkinsfile() && match(readfile(l:jenkinsfileFilename), "BUILD_PLAN_PATH") != -1
endfunction "}}}

function! JenkinsHasJenkinsfile() "{{{
	let l:jenkinsfileFilename = "Jenkinsfile"
	return filereadable(l:jenkinsfileFilename)
endfunction "}}}

function! JenkinsNoJenkinsfileError() "{{{
	call JenkinsLogStuff('This functionality requires a Jenkinsfile')
endfunction "}}}

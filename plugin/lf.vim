" forked from
" https://github.com/longkey1/vim-ranger
"

if !exists('g:lf_executable')
    let g:lf_executable = 'lf'
endif

if !executable(g:lf_executable)
    finish
endif

if !exists('g:lf_open_mode')
    let g:lf_open_mode = 'tabe'
endif

function! s:LfChooserForAncientVim(dirname)
    let temp = tempname()
    if has("gui_running")
        exec 'silent !xterm -e ' . g:lf_executable . ' -selection-path=' . shellescape(temp) . ' ' . a:dirname
    else
        exec 'silent !' . g:lf_executable . ' -selection-path=' . shellescape(temp) . ' ' . a:dirname
    endif
    if !filereadable(temp)
        " quit window if nothing to read, probably user closed lf
        quit
    endif
    let names = readfile(temp)
    if empty(names)
        " quit window if nothing to open.
        quit
    endif
    " Edit the first item.
    exec 'edit ' . fnameescape(names[0])
    filetype detect
    " open any remaning items in new tabs
    for name in names[1:]
        exec g:lf_open_mode . ' ' . fnameescape(name)
        filetype detect
    endfor
    redraw!
endfunction

function! s:LfChooserForNeoVim(dirname)
    let s:callback = {'tempname': tempname()}
    function! s:callback.on_exit(id, exit_status, event) dict abort
        if exists('g:lf_on_exit')
          exec g:lf_on_exit
        endif
        try
            if filereadable(self.tempname)
                let names = readfile(self.tempname)
                exec 'edit ' . fnameescape(names[0])
                for name in names[1:]
                    exec g:lf_open_mode . ' ' . fnameescape(name)
                endfor
            endif
        endtry
    endfunction
    let cmd = g:lf_executable . ' -selection-path='.s:callback.tempname.' '.shellescape(a:dirname)
    call termopen(cmd, s:callback)
    startinsert
endfunction

function! s:LfChooser(dirname)
    if isdirectory(a:dirname)
        if has('nvim')
            call s:LfChooserForNeoVim(a:dirname)
        else
            call s:LfChooserForAncientVim(a:dirname)
        endif
    endif
endfunction

au BufEnter * silent call s:LfChooser(expand("<amatch>"))
let g:loaded_netrwPlugin = 'disable'

" Use Vim settings instead of Vi defaults (must be first, changes other options).
set nocompatible

" Make buffers non-readonly when using vimdiff.
if &diff
    set noreadonly
endif

" Automatically reload files changed outside of Vim.
set autoread
augroup autoreload
    autocmd!
    autocmd CursorHold,CursorHoldI * checktime
    autocmd FocusGained,BufEnter * checktime
augroup END
set updatetime=200

" Use a dark background with syntax highlighting in color terminals.
if &t_Co > 1 && !has("gui_running")
    set background=dark
    set notermguicolors
    syntax enable
endif

" Clear the PAGER variable so :! commands don't pipe through a pager.
let $PAGER=''

" Allow backspacing over indentation, line breaks, and insert-mode start.
set backspace=indent,eol,start

" Use UTF-8 encoding.
set encoding=utf-8

" Enable auto-indent and smart indent for new lines.
set autoindent
set smartindent

" Use 4-space-wide tabs expanded to spaces.
set tabstop=4
set expandtab
set shiftwidth=4

" Keep 500 lines of command history.
set history=500

" Show the cursor position in the status line.
set ruler

" Search incrementally as you type.
set incsearch

" Show partial commands in the status line.
set showcmd

" Briefly jump to the matching bracket when one is inserted.
set showmatch

" Use case-insensitive search.
set ignorecase

" Automatically save before commands like :next and :make.
set autowrite

" Use Q for formatting instead of Ex mode.
map Q gq

" Enable filetype detection, plugins, and language-dependent indenting.
if has("autocmd")
    filetype plugin indent on

    augroup vimrcEx
    autocmd!

    " Wrap text files at 78 characters.
    autocmd FileType text setlocal textwidth=78

    " Jump to the last known cursor position when reopening a file.
    " Skip in diff mode so vimdiff/git difftool start at the first hunk.
    autocmd BufReadPost *
        \ if !&diff && line("'\"") > 0 && line("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif

    augroup END
endif

" Use 4-space indentation for Python files.
augroup pythonindent
    autocmd!
    autocmd FileType python setl sw=4 sts=4 et
augroup END

" Toggle search highlighting with F1.
nnoremap <F1> :set invhls hls?<CR>
set invhls

" Toggle line wrapping with F2.
nnoremap <F2> :set wrap!<CR>

" Toggle block comments with F11 (uncomment) and F12 (comment) per filetype.
augroup commentkeys
    autocmd!
    autocmd BufNewFile,BufRead *.pl,*.sh,*.py vmap <F11> :-1/^# /s///<CR>
    autocmd BufNewFile,BufRead *.pl,*.sh,*.py vmap <F12> :-1/^/s//# /<CR>
    autocmd BufNewFile,BufRead *.m,*.tex,*.sty,*.bib vmap <F11> :-1/^%/s///<CR>
    autocmd BufNewFile,BufRead *.m,*.tex,*.sty,*.bib vmap <F12> :-1/^/s//%/<CR>
    autocmd BufNewFile,BufRead *.sc vmap <F11> :-1/^;/s///<CR>
    autocmd BufNewFile,BufRead *.sc vmap <F12> :-1/^/s//;/<CR>
    autocmd BufNewFile,BufRead *.h,*.c,*.cpp vmap <F11> :-1/^\/\//s///<CR>
    autocmd BufNewFile,BufRead *.h,*.c,*.cpp vmap <F12> :-1/^/s//\/\//<CR>
augroup END

" Detect Python filetype and set comment keys for scripts using `uv run` shebang.
augroup uvrundetect
    autocmd!
    autocmd BufRead,BufNewFile * if getline(1) =~ '^#!.*uv run.*python' | set filetype=python | endif
    autocmd BufRead,BufNewFile * if getline(1) =~ '^#!.*uv run.*python' | vmap <F11> :-1/^# /s///<CR> | endif
    autocmd BufRead,BufNewFile * if getline(1) =~ '^#!.*uv run.*python' | vmap <F12> :-1/^/s//# /<CR> | endif
augroup END

" Fix terminal escape codes for Shift and Ctrl arrow keys.
set <S-Up>=O1;2A
set <S-Down>=O1;2B
set <S-Right>=O1;2C
set <S-Left>=O1;2D
set <C-Right>=O1;5C
set <C-Left>=O1;5D

" Resize the current split by 5 lines/columns with Shift+arrow keys.
" Direction is position-aware: the border moves in the arrow's direction.
nnoremap <silent> <S-Up>     :call <SID>Resize('+')<CR>
nnoremap <silent> <S-Down>   :call <SID>Resize('-')<CR>
nnoremap <silent> <S-Left>   :call <SID>Resize('<')<CR>
nnoremap <silent> <S-Right>  :call <SID>Resize('>')<CR>

function! s:Resize(dir)
    let this = winnr()

    if '+' == a:dir || '-' == a:dir
        wincmd k
        let up = winnr()
        if up != this
            wincmd j
            let x = 'bottom'
        else
            let x = 'top'
        endif
    elseif '>' == a:dir || '<' == a:dir
        wincmd h
        let left = winnr()
        if left != this
            wincmd l
            let x = 'right'
        else
            let x = 'left'
        endif
    endif

    if ('+' == a:dir && 'bottom' == x) || ('-' == a:dir && 'top' == x)
        execute "5wincmd +"
    elseif ('-' == a:dir && 'bottom' == x) || ('+' == a:dir && 'top' == x)
        execute "5wincmd -"
    elseif ('<' == a:dir && 'left' == x) || ('>' == a:dir && 'right' == x)
        execute "5wincmd <"
    elseif ('>' == a:dir && 'left' == x) || ('<' == a:dir && 'right' == x)
        execute "5wincmd >"
    endif
endfunction

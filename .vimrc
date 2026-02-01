if &diff
    set noreadonly
endif

set autoread
augroup autoreload
    autocmd!
    autocmd CursorHold,CursorHoldI * checktime
    autocmd FocusGained,BufEnter * checktime
augroup END
set updatetime=500

set showmatch
"so $HOME/.myfiletypes.vim

let $PAGER=''

" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

if &t_Co > 1 && !has("gui_running")
	set background=dark
	set notermguicolors
	syntax enable
"    set hlsearch
endif


" allow backspacing over everything in insert mode
set backspace=indent,eol,start

"if has("vms")
"  set nobackup  " do not keep a backup file, use versions instead
"else
"  set backup    " keep a backup file
"endif

" Required by YouCompleteMe
set encoding=utf-8

set ai           " autoindent
set smartindent  " smart indent
"set cindent      " enable C indent

set tabstop=4    " set tab to 4 spaces
set et           " expandtab: spaces as tabs
set sw=4         " shiftwidth: number of spaces in a tab

"set visualbell   " Silence the bell, use a flash instead
"set vb t_vb=     " No bell or flash

set history=500  " keep 50 lines of command line history
set ruler        " show the cursor position all the time
set incsearch    " do incremental searching
set showcmd      " Show (partial) command in status line.
set showmatch    " Show matching brackets.
set ignorecase   " Do case insensitive matching
set autowrite    " Automatically save before commands like :next and :make
"set invhls       " Disable highlighted searching by default. Alt: set hls

"colorscheme desert
"colorscheme koehler

" Don't use Ex mode, use Q for formatting
map Q gq


" Only do this part when compiled with support for autocommands.
if has("autocmd")
  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  augroup END

"else
"  set autoindent        " always set autoindenting on

endif " has("autocmd")




" Use F1 to toggle highlighting of seach results
nnoremap <F1> :set invhls hls?<CR>
set invhls "set hls

nnoremap <F2> :set wrap!<CR>

" Set handy commenting feature
" Perl and shell scripts
autocmd BufNewFile,BufRead *.pl,*.sh,*.py vmap <F11> :-1/^# /s///<CR>
autocmd BufNewFile,BufRead *.pl,*.sh,*.py vmap <F12> :-1/^/s//# /<CR>
" Matlab
autocmd BufNewFile,BufRead *.m,*.tex,*.sty,*.bib vmap <F11> :-1/^%/s///<CR>
autocmd BufNewFile,BufRead *.m,*.tex,*.sty,*.bib vmap <F12> :-1/^/s//%/<CR>
" Scheme
autocmd BufNewFile,BufRead *.sc vmap <F11> :-1/^;/s///<CR>
autocmd BufNewFile,BufRead *.sc vmap <F12> :-1/^/s//;/<CR>
" C, C++
autocmd BufNewFile,BufRead *.h,*.c,*.cpp vmap <F11> :-1/^\/\//s///<CR>
autocmd BufNewFile,BufRead *.h,*.c,*.cpp vmap <F12> :-1/^/s//\/\//<CR>

" Detect Python filetype for scripts using `uv run` shebang
autocmd BufRead,BufNewFile * if getline(1) =~ '^#!.*uv run.*python' | set filetype=python | endif
autocmd BufRead,BufNewFile * if getline(1) =~ '^#!.*uv run.*python' | vmap <F11> :-1/^# /s///<CR> | endif
autocmd BufRead,BufNewFile * if getline(1) =~ '^#!.*uv run.*python' | vmap <F12> :-1/^/s//# /<CR> | endif


"set t_ku=OA
"set t_kd=OB
"set t_kr=OC
"set t_kl=OD

set <S-Up>=O1;2A
set <S-Down>=O1;2B
set <S-Right>=O1;2C
set <S-Left>=O1;2D

"set <C-Up>=O1;5A
"set <C-Down>=O1;5B
set <C-Right>=O1;5C
set <C-Left>=O1;5D



" Window resizing mappings
nnoremap <S-Up>     :normal <c-r>=Resize('+')<cr><cr>
nnoremap <S-Down>   :normal <c-r>=Resize('-')<cr><cr>
nnoremap <S-Left>   :normal <c-r>=Resize('<')<cr><cr>
nnoremap <S-Right>  :normal <c-r>=Resize('>')<cr><cr>

function! Resize(dir)
    let this = winnr()

    if '+' == a:dir || '-' == a:dir
        execute "normal <c-w>k"
        let up = winnr()
        if up != this
            execute "normal \<c-w>j"
            let x = 'bottom'
        else
            let x = 'top'
        endif
    elseif '>' == a:dir || '<' == a:dir
        execute "normal <c-w>h"
        let left = winnr()
        if left != this
            execute "normal \<c-w>l"
            let x = 'right'
        else
            let x = 'left'
        endif
    endif

    if ('+' == a:dir && 'bottom' == x) || ('-' == a:dir && 'top' == x)
        return "5\<c-v>\<c-w>+"
    elseif ('-' == a:dir && 'bottom' == x) || ('+' == a:dir && 'top' == x)
        return "5\<c-v>\<c-w>-"
    elseif ('<' == a:dir && 'left' == x) || ('>' == a:dir && 'right' == x)
        return "5\<c-v>\<c-w><"
    elseif ('>' == a:dir && 'left' == x) || ('<' == a:dir && 'right' == x)
        return "5\<c-v>\<c-w>>"
    else
        echo "oops. check your ~/.vimrc"
        return ""
    endif
endfunction

"" Matlab tie-ins
"" make sure to run: bash ~/smlv/code/ext/matlab/fabrice/install.sh
"source $VIMRUNTIME/macros/matchit.vim
"filetype indent on
"autocmd BufEnter *.m    compiler mlint
"" Execute file being edited with F5:
"autocmd BufNewFile,BufRead *.m map <buffer> <F5> :w<CR>:!matlab -nodesktop -nosplash -r "try,run %,catch ME,disp([ME.identifier ' : ' ME.message]);for i=1:length(ME.stack)-1,disp([ME.stack(i).file ' : ' num2str(ME.stack(i).line)]);end;end;disp('press [enter] to continue');pause;quit;" <CR> <CR>



au FileType python setl sw=4 sts=4 et

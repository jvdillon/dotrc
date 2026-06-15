" Portable across vim (vim.basic), vim.tiny, and Neovim.
" - vim.basic / Neovim: full configuration, verified working in both.
" - vim.tiny: compiled without +eval, so it cannot run let/if/function/autocmd.
"   The basic :set/:map commands above the 'if 1' block still apply; the
"   eval-dependent block is parsed and skipped (no errors) -- see its comment.
" Terminal key codes for Shift/Ctrl arrows are guarded to real Vim (Neovim
" decodes them natively); the resize and comment features work in vim and nvim.

" Use Vim settings instead of Vi defaults (must be first, changes other options).
set nocompatible

" --- Basic options ---------------------------------------------------------
" These are plain :set / :map commands that work in every build, including
" vim.tiny (no +eval). Everything that needs +eval lives in the 'if 1' block
" below, which non-eval builds (vim.tiny) parse and skip without errors.

" Automatically reload files changed outside of Vim.
set autoread
set updatetime=200

" Allow backspacing over indentation, line breaks, and insert-mode start.
set backspace=indent,eol,start

" Use UTF-8 encoding.
set encoding=utf-8

" Enable auto-indent for new lines. (Filetype indent plugins, enabled below via
" 'filetype plugin indent on', handle language-specific cases; 'smartindent' is
" a legacy C-only heuristic that misindents other filetypes, so it is omitted.)
set autoindent

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

" Toggle search highlighting with F1 (and enable it by default).
nnoremap <F1> :set invhls hls?<CR>
set invhls

" Toggle line wrapping with F2.
nnoremap <F2> :set wrap!<CR>

" Use Q for formatting instead of Ex mode.
nnoremap Q gq
xnoremap Q gq

" --- Eval-dependent configuration ------------------------------------------
" 'if 1' is the canonical guard (see vim's own defaults.vim): builds with +eval
" run this block; vim.tiny lacks +eval, parses the if/endif, and skips the body
" instead of erroring (E319) on every let/function/autocmd inside.
if 1

" Make buffers non-readonly when using vimdiff.
if &diff
    set noreadonly
endif

" Reload files changed outside of Vim (needs autocmd for the triggers).
augroup autoreload
    autocmd!
    autocmd CursorHold,CursorHoldI * checktime
    autocmd FocusGained,BufEnter * checktime
augroup END

" Remove boldface from highlighting while keeping the colours. For each bold
" group, resolve its effective colour (following links) and re-apply it with the
" bold attribute cleared.
function! s:Unbold()
    for l:g in getcompletion('', 'highlight')
        let l:id = synIDtrans(hlID(l:g))
        if synIDattr(l:id, 'bold', 'gui') ==# '1' || synIDattr(l:id, 'bold', 'cterm') ==# '1'
            let l:gfg = synIDattr(l:id, 'fg#', 'gui')
            let l:cfg = synIDattr(l:id, 'fg', 'cterm')
            let l:gbg = synIDattr(l:id, 'bg#', 'gui')
            let l:cbg = synIDattr(l:id, 'bg', 'cterm')
            let l:c = 'highlight ' . l:g . ' cterm=NONE gui=NONE'
            if l:gfg != '' | let l:c .= ' guifg=' . l:gfg | endif
            if l:cfg != '' | let l:c .= ' ctermfg=' . l:cfg | endif
            if l:gbg != '' | let l:c .= ' guibg=' . l:gbg | endif
            if l:cbg != '' | let l:c .= ' ctermbg=' . l:cbg | endif
            execute l:c
        endif
    endfor
endfunction

" Use a dark background with syntax highlighting in color terminals.
if &t_Co > 1 && !has("gui_running")
    " Tell the colorscheme the terminal is dark so it picks dark-suited colors.
    set background=dark

    " Turn on syntax highlighting while keeping any custom :highlight overrides.
    syntax enable

    " Use the terminal's 256-color palette; comment out to use 24-bit RGB (default).
    set notermguicolors

    " De-bolding is potentially useful when termguicolors is enabled, ie, not
    " disabled. We de-bold the highlighting now and after any later
    " :colorscheme (Neovim sets one after sourcing this file), so the
    " de-bolding sticks.
    " augroup unbold
    "     autocmd!
    "     autocmd ColorScheme * call s:Unbold()
    " augroup END
    " call s:Unbold()
endif

" Clear the PAGER variable so :! commands don't pipe through a pager.
let $PAGER=''

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

" Filetype mappings (highlighting for lark lives in .vim/syntax/lark.vim).
" NB: do NOT name this augroup 'filetypedetect' -- that is the runtime's own
" detection group; reusing it makes ':doautocmd filetypedetect BufRead <file>'
" (fired by the runtime/plugins) warn "No matching autocommands" for any file
" not matching the patterns below. Use a private name.
augroup vimrc_ftdetect
    autocmd!
    autocmd BufRead,BufNewFile *.lark set filetype=lark
    autocmd BufRead,BufNewFile *.csl  set filetype=xml
augroup END

" Highlight fenced code blocks inside Markdown by language. This drives Vim's
" builtin markdown syntax (which otherwise renders fences as plain text); under
" Neovim, Treesitter handles fenced code via injection and ignores this -- so
" both editors highlight Markdown code blocks the same. 'name=ft' maps a fence
" label to a syntax file (e.g. ```sh and ```bash both use the 'sh' syntax).
let g:markdown_fenced_languages = [
    \ 'python', 'sh=bash', 'bash=sh', 'c', 'cpp', 'rust',
    \ 'json', 'yaml', 'toml', 'javascript', 'typescript',
    \ 'html', 'css', 'java', 'ruby', 'lua', 'vim',
    \ ]

" Block comment/uncomment with F12/F11 over the visual selection.
" Keyed off &filetype (not 'commentstring', which is unreliably populated and
" differs between vim and nvim) via one prefix table, so behavior is identical
" in both editors and covers every listed filetype without per-extension autocmds.
let g:comment_prefix = {
    \ 'python': '# ', 'sh': '# ', 'perl': '# ',
    \ 'plaintex': '%', 'tex': '%', 'matlab': '%', 'bib': '%',
    \ 'scheme': '; ', 'lisp': '; ',
    \ 'lua': '-- ', 'sql': '-- ', 'haskell': '-- ',
    \ 'vim': '" ',
    \ 'c': '// ', 'cpp': '// ', 'scala': '// ', 'rust': '// ',
    \ 'javascript': '// ', 'typescript': '// ',
    \ }

" a:uncomment=0 prepends the prefix; =1 strips one leading prefix. The :range
" is the visual selection: starting a command-line from visual mode inserts
" '<,'> automatically, which the function's 'range' attribute receives as
" a:firstline/a:lastline. 'e' flag silences the no-match error so uncommenting
" an already-bare line is a harmless no-op.
function! s:Comment(uncomment) range
    let l:p = get(g:comment_prefix, &filetype, '')
    if empty(l:p)
        echohl WarningMsg | echo 'No comment prefix for filetype: ' . &filetype | echohl None
        return
    endif
    let l:esc = escape(l:p, '/\')
    if a:uncomment
        execute a:firstline . ',' . a:lastline . 's/^' . l:esc . '//e'
    else
        execute a:firstline . ',' . a:lastline . 's/^/' . l:esc . '/e'
    endif
endfunction

xnoremap <silent> <F11> :call <SID>Comment(1)<CR>
xnoremap <silent> <F12> :call <SID>Comment(0)<CR>

" Treat `uv run ... python` shebang scripts (often extensionless) as Python.
augroup uvrundetect
    autocmd!
    autocmd BufRead,BufNewFile *
        \ if getline(1) =~ '^#!.*uv run.*python' | set filetype=python | endif
augroup END

" Teach real Vim the terminal's escape sequences for Shift/Ctrl arrow keys, so
" the split-resize mappings below can bind to <S-Up> etc. Guarded to real Vim:
" Neovim decodes these keys natively and has no t_xx/termcap override mechanism,
" so the block is skipped (and unneeded) there -- resize works in nvim regardless.
"
" The leading char of each RHS is a literal <Esc> (0x1b), required by the
" 'set <key>=' idiom; if it gets stripped (copy-paste, or an editor that eats
" control bytes) the mapping silently binds the wrong key. Keep it.
"
" The bytes after <Esc> are terminal-specific. These 'O'-prefixed values match
" one xterm-style terminal; a generic xterm uses '[' instead (e.g. <Esc>[1;2A)
" -- compare `infocmp` kUP/kDN/kLFT/kRIT. If Shift-arrow resize is inert in real
" Vim, adjust these to match your terminal. (Verified working under Neovim via native keys;
" the real-Vim path depends on your terminal emitting exactly these sequences.)
if !has('nvim')
    set <S-Up>=O1;2A
    set <S-Down>=O1;2B
    set <S-Right>=O1;2C
    set <S-Left>=O1;2D
    set <C-Right>=O1;5C
    set <C-Left>=O1;5D
endif

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

endif " --- end eval-dependent block ----------------------------------------

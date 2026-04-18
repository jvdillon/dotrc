" Recommended way to 'install' nvim:
"   alias vi='nvim'
"   alias vim='nvim'
"
" You could set as system default but this might break things expecting vim.
"
" Install nvim as system wide alternative:
"   sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 100
"   sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 100
"
" List alternatives:
"   sudo update-alternatives --config vi
"   sudo update-alternatives --config vim
"
" Uninstall nvim as system wide default:
"   sudo update-alternatives --remove vi /usr/bin/nvim
"   sudo update-alternatives --remove vim /usr/bin/nvim
"
" Restore vim as system wide default:
"   sudo update-alternatives --set vi /usr/bin/vim.basic
"   sudo update-alternatives --set vim /usr/bin/vim.basic

" Load .vimrc and vim's runtime files for maximum compatibility.
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" Only show the status line when there are multiple windows.
set laststatus=1

" Show file info messages when opening a file.
set shortmess-=F

" Require explicit :hide instead of silently hiding modified buffers.
set nohidden

" Disable mouse support to match vim's default.
set mouse=

" Disable TreeSitter highlighting and use vim's built-in colorscheme.
autocmd BufEnter * lua vim.treesitter.stop()
if has('nvim-0.10')
  colorscheme vim
endif

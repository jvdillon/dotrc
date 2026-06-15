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
" We originally were disabling treesitter until we figured out how to align
" TS with "old school vim".
" autocmd BufEnter * lua vim.treesitter.stop()

" Treesitter highlighting (Neovim only). Colors come from 'colorscheme vim',
" which links every @treesitter.* group to a classic Vim highlight group, so
" Neovim looks like Vim while Treesitter does the (more accurate) parsing.
" Real Vim has no Treesitter and ignores all of this -- it stays on vim-syntax.
if has('nvim-0.10')
  colorscheme vim

  " sudo apt install neovim-treesitter
  lua << EOF
do
  -- Align Treesitter to Vim-syntax's look. Key difference: Vim leaves ordinary
  -- identifiers/arguments/calls/punctuation UNCOLOURED (default fg) and colours
  -- only keywords, strings, comments, numbers, types and definitions. Treesitter
  -- colours every token, so plain words land on the comment colour. Send those
  -- "ordinary" captures to Normal to restore Vim's uncoloured baseline.
  -- Re-applied on every :colorscheme.
  local function align_treesitter_to_vim()
    local to_normal = {
      '@variable', '@variable.parameter', '@variable.member', '@variable.builtin',
      '@property', '@field', '@parameter', '@function.call', '@function.method.call',
      '@constructor', '@module', '@punctuation.bracket', '@punctuation.delimiter',
      '@operator', '@punctuation.special', '@attribute', '@label',
    }
    for _, grp in ipairs(to_normal) do
      pcall(vim.api.nvim_set_hl, 0, grp, { link = 'Normal' })
    end
    -- @spell/@nospell are spell-region overlays, not colours; keep them blank so
    -- they don't blank out the underlying @comment colour.
    pcall(vim.api.nvim_set_hl, 0, '@spell', {})
    pcall(vim.api.nvim_set_hl, 0, '@nospell', {})
  end
  vim.api.nvim_create_autocmd('ColorScheme', { callback = align_treesitter_to_vim })
  align_treesitter_to_vim()

  local ok, ts = pcall(require, 'nvim-treesitter')
  if ok then
    -- Languages to keep highlighted. Parsers for these are compiled on demand.
    local want = {
      'python', 'lua', 'vim', 'vimdoc', 'bash', 'c', 'cpp', 'rust',
      'json', 'yaml', 'toml', 'markdown', 'markdown_inline',
      'javascript', 'typescript', 'tsx', 'html', 'css',
      'latex', 'bibtex', 'java', 'ruby', 'fortran',
    }
    -- Idempotent: only install parsers not already present (no recompile, no
    -- network on subsequent startups once each .so exists).
    local missing = {}
    for _, lang in ipairs(want) do
      if #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.so', false) == 0 then
        missing[#missing + 1] = lang
      end
    end
    if #missing > 0 then
      pcall(function() ts.install(missing) end)  -- async; compiles in background
    end
    -- Start Treesitter highlighting for any buffer whose parser is available.
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('ts_highlight', { clear = true }),
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end
end
EOF

endif

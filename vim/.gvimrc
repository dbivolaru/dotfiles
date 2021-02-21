"=====================================================
" GUI settings
"=====================================================

set guifont=Monospace\ 11
set guioptions=aikcm
set guioptions-=m
set guicursor+=i:block-Cursor/lCursor
set lines=999 columns=999
augroup HandleGUI
  autocmd!
  au GUIEnter * sim ~x " start maximized
augroup END


"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
"                                                                              "
"                       __   _ _ _ __ ___  _ __ ___                            "
"                       \ \ / / | '_ ` _ \| '__/ __|                           "
"                        \ V /| | | | | | | | | (__                            "
"                         \_/ |_|_| |_| |_|_|  \___|                           "
"                                                                              "
"                                                                              "
"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

" Force python3 for plugins
if has('python3')
endif

" Virtualenv support
py3 << EOF
import os
import sys
if 'VIRTUAL_ENV' in os.environ:
  project_base_dir = os.environ['VIRTUAL_ENV']
  activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
  execfile(activate_this, dict(__file__=activate_this))
EOF

" Be iMproved
set nocompatible

"=====================================================
" Vundle settings
"=====================================================
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

" Navigation
Plugin 'scrooloose/nerdtree'
Plugin 'kien/ctrlp.vim'

" Syntax highlighting
Plugin 'w0rp/ale'

" Colors and indentation
Plugin 'sickill/vim-monokai'
Plugin 'Yggdroot/indentLine'

" Session management
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-session'

" Language support
Plugin 'davidhalter/jedi-vim'
Plugin 'tmhedberg/SimpylFold'

call vundle#end()
filetype plugin indent on

"=====================================================
" General settings
"=====================================================

" Syntax
syntax enable                   " Enable syntax highlighting
colorscheme monokai             " Use syntax highlighting color scheme
let python_highlight_all=1      " Python syntax highlighting

" Screen
set number                      " Show line numbers
set ruler                       " Show bottom part cursor position (ruler)
set ttyfast                     " Terminal acceleration
"set lazyredraw                 " Don't refresh screen when doing macros
set backspace=indent,eol,start  " Make sure BS can delete indent, EOL and lines
set scrolloff=10                " Scroll earlier by 10 lines instead of screen edge
set wildmenu                    " Visual autocomplete for command menu
"set clipboard=unnamedplus      " Use system clipboard
set signcolumn=yes              " Always show sign column (syntastic)
set nosol                       " Don't change cursor column when scrolling

" Tabs
set encoding=utf-8  " Use UTF-8 encoding
set ts=4            " Tabs have 4 spaces
set shiftwidth=4    " Shift >> << by 4 spaces
set autoindent      " Indent on next line
set expandtab       " Expand tabs to spaces
set smarttab        " Set tabs for shifttabs logic
set showmatch       " Match parantheses
au FileType sh setlocal noexpandtab
au Filetype vim set ts=2 | set shiftwidth=2

" Backup / swap files
set nobackup            " No backup files
set nowritebackup       " No backup while editing
set noswapfile          " No swap files

" Buffers / windows
set hidden              " When switching buffers, don't save or ask anything
set switchbuf=useopen   " Jumping buffers when using quickfix
set splitbelow          " Open horizontal splits down
set splitright          " Open vertical splits to the right

" Cursor
set nocursorline    " Show no line by default - only in active win
augroup CursorLineOnlyInActiveWindow
  autocmd!
  autocmd VimEnter,BufEnter,WinEnter * setlocal cursorline
  autocmd BufLeave,WinLeave * setlocal nocursorline
augroup END

augroup AutoResizeWindows
  autocmd!
  au VimResized * wincmd =
augroup END

" Fast ESC key in Insert mode
set ttimeoutlen=10
augroup FastEscape
  autocmd!
  au InsertEnter * set timeoutlen=0
  au InsertLeave * set timeoutlen=1000
augroup END

"=====================================================
" Code folding
"=====================================================

set tags=tags;~

set foldmethod=syntax   " Fold based on syntax
set foldcolumn=3        " Display 3 fold columns
set foldlevel=1         " Default fold level

" Keyboard folding of code
nnoremap <space> za
vnoremap <space> zf

" Replace default tags goto with list if many matches
nnoremap <C-]> g<C-]>

"=====================================================
" GUI settings
"=====================================================

if has('gui_running')
  set guifont=DejaVu_Sans_Mono_for_Powerline:h12:cANSI:qDRAFT
  set guioptions-=T  " no toolbar
  set guioptions-=t  " no tear-off menus
  au GUIEnter * sim ~x " start maximized
endif

"=====================================================
" airline settings
"=====================================================

set laststatus=2    " Always show bottom status
set showtabline=2   " Always show top tabline
set noshowmode
set noshowcmd

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

let g:airline_theme='powerlineish'
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#formatter='unique_tail'
let g:airline#extensions#tabline#buffer_nr_show=1
let g:airline#extensions#tabline#show_buffers=1
let g:airline#extensions#tabline#show_splits=0
let g:airline#extensions#tabline#show_tabs=0
let g:airline#extensions#tabline#show_tab_nr=0
let g:airline#extensions#tabline#show_tab_type=0
let g:airline#extensions#tabline#show_close_button=0
let g:airline#extensions#ctrlp#show_adjacent_modes=1

"=====================================================
" ale syntax checking
"=====================================================

"autocmd FileType python set completeopt-=preview " Do not show any preview window in the bottom

let g:ale_sign_column_always=1
let g:ale_sign_error='EE'
let g:ale_sign_warning = 'WW'

nnoremap <silent> <F7> :ALEPreviousWrap<CR>
nnoremap <silent> <F8> :ALENextWrap<CR>

"=====================================================
" Other keyboard shortcuts
"=====================================================

" If we forgot to sudo before an edit, then this allows to use w!! to save it
cmap w!! %!sudo tee > /dev/null %

" Keyboard jumping from insert mode
inoremap <silent> <C-w> <C-o><C-w>
inoremap <C-a> <C-o>^
inoremap <C-e> <C-o>$

" Search-replace for word under cursor
nnoremap <Leader>h :%s/\<<C-r><C-w>\>//g<Left><Left>

" Clear search highlighting
nnoremap <silent> // :nohlsearch<CR>

" Buffer close but keep window Ctrl-F4
nnoremap <silent> <Esc>[1;5S :lclose<BAR>cclose<BAR>bp<CR>:bd#<CR>

" Buffer show
nnoremap <Leader>b :ls<CR>:b<Space>

" Delete line anywhere using Shift-Del
inoremap <silent> <Esc>[3;2~ <C-o>dd
nnoremap <silent> <Esc>[3;2~ dd

" Save anywhere (remember to do stty -ixon in bashrc)
inoremap <silent> <C-s> <C-o>:update<CR>
nnoremap <silent> <C-s> :update<CR>

" Quit shortcut to be useable with sessions - save current and quit all
nnoremap <silent> <S-z><S-z> :update<BAR>qa<CR>
nnoremap <silent> <S-z><S-q> :qa<CR>

" Switch between buffers
nnoremap <silent> <F5> :bprev<CR>
nnoremap <silent> <F6> :bnext<CR>

" Switch between tabs
nnoremap <silent> <F9> :tabp<CR>
nnoremap <silent> <F10> :tabn<CR>

" Update time stamps etc. before saving
function! PythonFileUpdater()
  exec 'norm mz'
  retab " Replace tabs with spaces
  try
    exec '1,20 s/__updated__\s*=\s*''\S*''/__updated__ = '''.strftime('%Y-%m-%d').'''/i'
  catch
    silent! exec '/__updated__/s/__updated__\s*=\s*''\S*''/__updated__ = '''.strftime('%Y-%m-%d').'''/i'
  finally
    exec 'norm `z'
  endtry
endfunction
augroup AutomaticFileUpdaters
  autocmd!
  au BufWritePre * if &ft == 'python' | call PythonFileUpdater() | endif
augroup END

"=====================================================
" vim-ctrlp settings
"=====================================================

let g:ctrlp_map='<C-p>'
let g:ctrlp_cmd='CtrlPLastMode'

"=====================================================
" NERDTree settings
"=====================================================

let g:NERDTreeWinSize=60 " Bigger window size
let g:NERDTreeWinPos="right" " Open always to the right
let g:NERDTreeIgnore=['\.pyc$', '\.pyo$', '__pycache__$', '\~$'] " Ignore files in NERDTree
let g:NERDTreeQuitOnOpen=1 " If you open a file then close NERDTree
let g:NERDTreeAutoDeleteBuffer=1 " If you delete a file then delete the buffer also
let g:NERDTreeMinimalUI=1 " Don't show help ? info
let g:NERDTreeDirArrows=1 " Use arrows for the tree
let g:NERDTreeShowHidden=0 " By default, hide hidden files; show with <S-i>

" Open NERDTree if closed, close if open; default within same folder as the
" current file
function! NERDTreeOpenCWDClose()
  if exists('g:NERDTree') && g:NERDTree.IsOpen()
    NERDTreeClose
  elseif bufexists(expand('%'))
    NERDTreeFind " If you use NERDTree %:p:h then it will not show hidden . files
  else
    NERDTree
  endif
endfunction

" NERDTree key with support for local window cursor highlighting
" NERDTree is very ping-pongy related to window switching so we just disable them
nnoremap <silent> <C-n> :call NERDTreeOpenCWDClose()<CR>

" Close NERDTree if it's the only one open in a tab
au BufEnter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

" Close NERDTree before saving session
au VimLeavePre * if exists('g:NERDTree') && g:NERDTree.IsOpen() | NERDTreeClose | endif | lclose | cclose

"=====================================================
" vim-session settings
"=====================================================

let g:session_autoload='yes'
let g:session_autosave='yes'
let g:session_verbose_messages=0
let g:session_persist_font=0
let g:session_persist_colors=0

"=====================================================
" JEDI settings
"=====================================================

let g:pymode_rope=0  " Faster in case python mode is installed
let g:jedi#popup_on_dot=0 " This seems too laggy, so we disable
let g:jedi#popup_select_first=1 " Saves one key strokei
let g:jedi#show_call_signatures=0 " This seems too lagy, so we disable
let g:jedi#show_call_signatures_delay=0 " Show signature immediately

" Call signature scan get quite slow with big libraries like pandas
"autocmd FileType python call jedi#configure_call_signatures()

"=====================================================
" SimplyFold settings
"=====================================================

let g:SimpylFold_docstring_preview=1
let g:SimpylFold_fold_docstring=0
let g:SimpylFold_fold_import=0


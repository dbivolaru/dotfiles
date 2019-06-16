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
Plugin 'scrooloose/nerdtree'

" Navigation
Plugin 'kien/ctrlp.vim'

" Syntax highlighting
Plugin 'w0rp/ale'

" Colors and indentation
Plugin 'flazz/vim-colorschemes'
Plugin 'Yggdroot/indentLine'

" Session management
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-session'

call vundle#end()
filetype plugin indent on

"=====================================================
" General settings
"=====================================================

" Syntax
syntax enable               " Enable syntax highlighting
colorscheme Monokai         " Use syntax highlighting color scheme
let python_highlight_all=1  " Python syntax highlighting

" Screen
set number                      " Show line numbers
set ruler                       " Show bottom part cursor position (ruler)
set ttyfast                     " Terminal acceleration
set lazyredraw                  " Don't refresh screen when doing macros
set backspace=indent,eol,start  " Make sure BS can delete indent, EOL and lines
set scrolloff=10                " Scroll earlier by 10 lines instead of screen edge
set wildmenu                    " Visual autocomplete for command menu
"set clipboard=unnamedplus       " Use system clipboard
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

" If we forgot to sudo before an edit, then this allows to use w!! to save it
cmap w!! %!sudo tee > /dev/null %

" Cursor
set nocursorline    " Show no line by default - only in active win
augroup CursorLineOnlyInActiveWindow
  autocmd!
  au VimEnter,BufEnter * setlocal cursorline
  au BufLeave * setlocal nocursorline
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

set foldmethod=syntax   " Fold based on syntax
set foldnestmax=10      " Maximum 10 levels of folding
set foldlevel=1         " Default fold level

" Keyboard folding of code
nnoremap <space> za

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

let g:powerline_pycmd="py3"
set laststatus=2    " Always show bottom powerline
"set showtabline=2   " ALways show top tabline

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

let g:airline_theme='powerlineish'
let g:airline_powerline_fonts=1

"=====================================================
" python-mode
"=====================================================

let g:pymode_python = 'python3'

"=====================================================
" ale syntax checking
"=====================================================

let g:ale_sign_column_always = 1
let g:ale_completion_enabled = 1

"=====================================================
" Other keyboard shortcuts
"=====================================================

" Keyboard jumping from insert mode
inoremap <C-w> <C-o><C-w>

" Clear search highlighting
nnoremap <silent> // :nohlsearch<CR>

" Buffer list - disabled, see vim-ctrlp
"nnoremap <C-b> :ls<CR>:b<Space>

" Buffer close but keep window Ctrl-F4
nnoremap <silent> <Esc>[1;5S :lclose<BAR>:cclose<BAR>bp<CR>:bd#<CR>

" Delete line anywhere using Shift-Del
inoremap <silent> <Esc>[3;2~ <C-o>dd
nnoremap <silent> <Esc>[3;2~ dd

" Save anywhere (remember to do stty -ixon in bashrc)
inoremap <silent> <C-s> <C-o>:update<CR>
nnoremap <silent> <C-s> :update<CR>

" Quit shortcut to be useable with sessions - save current and quit all
nnoremap <silent> <S-z><S-z> :update<BAR>qa<CR>
nnoremap <silent> <S-z><S-q> :qa<CR>

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
" YouCompleteMe settings
"=====================================================

set completeopt-=preview " Do not show any preview window in the bottom

nmap <F2> :ALEDocumentation<CR>
nmap <F3> :ALEGoToDefinition<CR>
nmap <F4> :ALEFindReferences<CR>

"=====================================================
" vim-ctrlp settings
"=====================================================

let g:ctrlp_map='<C-p>'
let g:ctrlp_cmd='CtrlPBuffer'

"=====================================================
" NERDTree settings
"=====================================================

let NERDTreeWinSize=40                                      " Bigger window size
let g:NERDTreeWinPos="right"                              " Open always to the right
let NERDTreeIgnore=['\.pyc$', '\.pyo$', '__pycache__$', '\~$']   " Ignore files in NERDTree

" NERDTree key with support for local window cursor highlighting
" NERDTree is very ping-pongy related to window switching so we just disable them
nnoremap <silent> <C-n> :setlocal nocursorline<BAR>set ei=BufEnter,BufLeave<BAR>try<BAR>NERDTreeToggle<BAR>finally<BAR>set ei=<BAR>endtry<BAR>setlocal cursorline<CR>
nnoremap <silent> <C-m> :setlocal nocursorline<BAR>set ei=BufEnter,BufLeave<BAR>try<BAR>NERDTreeFocus<BAR>finally<BAR>set ei=<BAR>endtry<BAR>setlocal cursorline<CR>

" Close NERDTree before saving session
au VimLeavePre * if exists('g:NERDTree') && g:NERDTree.IsOpen() | NERDTreeToggle | endif | lclose | cclose

"=====================================================
" vim-session settings
"=====================================================

let g:session_autoload='yes'
let g:session_autosave='yes'
let g:session_verbose_messages=0
let g:session_persist_font=0
let g:session_persist_colors=0


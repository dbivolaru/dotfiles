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

" Be iMproved
set nocompatible
set shiftwidth=4    " Shift >> << by 4 spaces

"=====================================================
" Vundle settings
"=====================================================
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

" Navigation
Plugin 'kien/ctrlp.vim'

" Language support
Plugin 'Valloric/YouCompleteMe'

" Colors
Plugin 'flazz/vim-colorschemes'

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
set number          " Show line numbers
set ruler           " Show bottom part cursor position (ruler)
set ttyfast         " Terminal acceleration
set lazyredraw      " Don't refresh screen when doing macros
set backspace=indent,eol,start
set scrolloff=10    " Scroll earlier by 10 lines instead of screen edge
set wildmenu        " Visual autocomplete for command menu
set clipboard=unnamedplus " Use system clipboard

" Tabs
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
  au VimEnter,WinEnter * setlocal cursorline
  au WinLeave * setlocal nocursorline
  au BufWinLeave * nested :lclose
augroup END

"=====================================================
" Code folding
"=====================================================

set foldmethod=syntax   " Fold based on syntax
set foldnestmax=10      " Maximum 10 levels of folding
set foldlevel=2         " Default fold level

" Keyboard folding of code
nnoremap <space> za

"=====================================================
" vim-powerline settings (installed with dnf)
"=====================================================

set laststatus=2    " Always show bottom powerline
"set showtabline=2   " ALways show top tabline

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

"=====================================================
" syntastic settings
"=====================================================

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list=1
let g:syntastic_auto_loc_list=0
let g:syntastic_check_on_open=1
let g:syntastic_check_on_wq=0
"let g:syntastic_aggregate_errors=1          " Display checker-name for that error-message

let g:syntastic_python_checkers=['flake8']
let g:syntastic_python_python_exec='python3'

" Toggle checking if it's too slow
nnoremap <F10> :SyntasticToggleMode<CR>

" Check file explicitly
nnoremap <silent> <F11> :SyntasticCheck<CR>

" Toggle Errors window with keyboard
function! SyntasticToggleErrors()
  :SyntasticSetLoclist
  if empty(filter(tabpagebuflist(), 'getbufvar(v:val, "&buftype") is# "quickfix"'))
    lclose
    lopen
  else
    lclose
  endif
endfunction
nnoremap <silent> <F12> <Esc>:<C-u>call SyntasticToggleErrors()<CR>

"=====================================================
" Other keyboard shortcuts
"=====================================================

" Keyboard jumping for windows
nnoremap <C-j> <C-w><C-j>
nnoremap <C-k> <C-w><C-k>
nnoremap <C-l> <C-w><C-l>
nnoremap <C-h> <C-w><C-h>
inoremap <C-w> <C-o><C-w>

" Clear search highlighting
nnoremap <silent> // :nohlsearch<CR>

" Buffer list - disabled, see vim-ctrlp
"nnoremap <C-B> :ls<CR>:b<Space>

" Buffer close but keep window Ctrl-F4
nnoremap <silent> <Esc>[1;5S :lclose<BAR>bp<CR>:bd#<CR>

" Delete line anywhere using Shift-Del
inoremap <silent> <Esc>[3;2~ <C-o>dd
nnoremap <silent> <Esc>[3;2~ dd

" Save anywhere (remember to do stty -ixon in bashrc)
inoremap <silent> <C-s> <Esc>:update<CR>
nnoremap <silent> <C-s> :update<CR>

" Quit shortcut to be useable with sessions - save current and quit all
nnoremap <silent> <S-z><S-z> :update<BAR>qa<CR>
nnoremap <silent> <S-z><S-q> :qa<CR>

" Update time stamps etc. before saving
augroup AutomaticFileUpdaters
  autocmd!
  au BufWritePre * if &ft == 'python' | exec 'norm mz' | exec '1,20 s#\(__updated__\s*=\s*''\)\S*\(''\)#\1'.strftime('%Y-%m-%d').'\2#i' | exec 'norm `z' | endif
augroup END

"=====================================================
" YouCompleteMe settings
"=====================================================

nmap <F2> :YcmCompleter GetDoc<CR>
nmap <F3> :YcmCompleter GoToDefinition<CR>
nmap <F4> :YcmCompleter GoToReferences<CR>

"=====================================================
" vim-ctrlp settings
"=====================================================

let g:ctrlp_map='<C-p>'
let g:ctrlp_cmd='CtrlPMRU'

nnoremap <silent> <C-b> :CtrlPBuffer<CR>

"=====================================================
" NERDTree settings
"=====================================================

let NERDTreeWinSize=40                                      " Bigger window size
let g:NERDTreeWinPos="right"                              " Open always to the right
let NERDTreeIgnore=['\.pyc$', '\.pyo$', '__pycache__$']     " Ignore files in NERDTree

" NERDTree key with support for local window cursor highlighting
" NERDTree is very ping-pongy related to window switching so we just disable them
nnoremap <silent> <C-n> :setlocal nocursorline<BAR>set ei=WinEnter,WinLeave<BAR>try<BAR>NERDTreeToggle<BAR>finally<BAR>set ei=<BAR>endtry<BAR>setlocal cursorline<CR>
nnoremap <silent> <C-m> :setlocal nocursorline<BAR>set ei=WinEnter,WinLeave<BAR>try<BAR>NERDTreeFocus<BAR>finally<BAR>set ei=<BAR>endtry<BAR>setlocal cursorline<CR>

" Close NERDTree before saving session
au VimLeavePre * if exists('g:NERDTree') && g:NERDTree.IsOpen() | NERDTreeToggle | endif

"=====================================================
" vim-session settings
"=====================================================

let g:session_autoload='yes'
let g:session_autosave='yes'
let g:session_verbose_messages=0
let g:session_persist_font=0
let g:session_persist_colors=0


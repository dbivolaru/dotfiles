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

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

"=====================================================
" Vundle settings
"=====================================================
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

" Support for G commands and []/gc keybinds
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-unimpaired'
Plugin 'tpope/vim-commentary'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-abolish'

" Navigation
Plugin 'scrooloose/nerdtree'
Plugin 'kien/ctrlp.vim'
Plugin 'majutsushi/tagbar'

" Syntax highlighting
Plugin 'w0rp/ale'

" Colors and indentation
Plugin 'sickill/vim-monokai'
Plugin 'Yggdroot/indentLine'

" Session management
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-session'

" Language support
Plugin 'voithos/vim-python-matchit'
Plugin 'davidhalter/jedi-vim'
Plugin 'tmhedberg/SimpylFold'
Plugin 'goerz/jupytext.vim'

" Status
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

call vundle#end()
filetype plugin indent on

" Load bundled plugins
packadd matchit
if exists(':Man') != 2
  runtime ftplugin/man.vim
endif

"=====================================================
" General settings
"=====================================================

" Syntax
syntax enable                   " Enable syntax highlighting
colorscheme monokai             " Use syntax highlighting color scheme
let python_highlight_all=1      " Python syntax highlighting

" Screen
set title                       " Modify terminal title
let &titlestring='vim - ' . $USER . '@' . split($HOSTNAME, '\.')[0] . ':%F%( %)%h%w%m%r'
set number                      " Show line numbers
set ruler                       " Show bottom part cursor position (ruler)
set ttyfast                     " Terminal acceleration
set lazyredraw                  " Don't refresh screen when doing macros
set norelativenumber            " Faster display do not use relativenumbers
set synmaxcol=300               " Disable syntax highlighting after 200 cols (faster)
syntax sync minlines=300        " Maximum # of lines to read for determining syntax highlighing
set backspace=indent,eol,start  " Make sure BS can delete indent, EOL and lines
set scrolloff=10                " Scroll earlier by 10 lines instead of screen edge
set sidescroll=1                " Horizontal scroll 1 by 1 (fast terminal)
set sidescrolloff=5             " Scroll horizontally earlier by 5 columns
set wildmenu                    " Visual autocomplete for command menu
set signcolumn=yes              " Always show sign column (syntastic)
set nosol                       " Don't change cursor column when scrolling
set incsearch                   " Incremental search
set complete-=i                 " No include files in completion
set mouse=nvi                   " Use mouse if available
set history=1000                " More history

" Command timeouts
set notimeout ttimeout
set ttimeoutlen=0

" Horizontal scrolling, or lack thereof
if &diff == 0
  set wrap
  set linebreak
  set breakindent
  let &showbreak='↪ '
endif

" Tabs
set encoding=utf-8  " Use UTF-8 encoding
set ts=4            " Tabs have 4 spaces
set shiftwidth=4    " Shift >> << by 4 spaces
set autoindent      " Indent on next line
set expandtab       " Expand tabs to spaces
set smarttab        " Set tabs for shifttabs logic
set showmatch       " Match parantheses
set list            " Show trailing characters
set listchars=tab:•-•,trail:•,extends:»,precedes:«
augroup FileTypeHandling
  autocmd!
  au FileType sh setlocal noexpandtab
  au Filetype vim set ts=2 | set shiftwidth=2
  " au FileType python set completeopt-=preview
  au FileType qf wincmd J
  au FileType man wincmd L
  au FileType help wincmd L
augroup END

" Backup / swap files / grep
set nobackup            " No backup files
set nowritebackup       " No backup while editing
set noswapfile          " No swap files
set modelines=5         " Scan only 5 lines if modeline is enabled
set nomodeline          " No modeline by default
set wildignore+=*/__pycache__/*,*/venv/*,*/build/*,*/dist/*,*/.git/*,*/*.log,*.ipynb,*.pyc*
let &grepprg='rg --vimgrep --smart-case -g ''!*.{log,ipynb}'''

" Buffers / windows
set hidden              " When switching buffers, don't save or ask anything
set confirm             " Ask instead of fail
set switchbuf=useopen   " Jumping buffers when using quickfix
set splitbelow          " Open horizontal splits down
set splitright          " Open vertical splits to the right
set autoread            " File changed, read it
set ignorecase          " Searches are case insensitive by default
set smartcase           " Case sensitive if upper letter specified

" Cursor
set nocursorcolumn  " Show no column by default
set nocursorline    " Show no line by default - only in active win

" Session (in case using manually mksession)
set sessionoptions-=help
set sessionoptions-=options
set viewoptions-=options

augroup CursorLineOnlyInActiveWindow
  autocmd!
  au VimEnter,BufEnter,WinEnter * setlocal cursorline
  au BufLeave,WinLeave * setlocal nocursorline
augroup END

" Auto-resize windows when vim or terminal is resized
augroup AutoResizeWindows
  autocmd!
  au VimResized * wincmd =
augroup END

" When saving in hex mode, ensure to convert to xxd first
augroup HexMode
  autocmd!
  au BufWritePre *
      \ if exists('b:xxd_mode') && b:xxd_mode == 1 | let b:xxd_view = winsaveview() |
      \ silent! exe '%!xxd -r' | endif
  au BufWritePost *
      \ if exists('b:xxd_mode') && b:xxd_mode == 1 | let b:xxd_modified = &modified |
      \ silent! exe '%!xxd -g 1' | let &modified = b:xxd_modified | unlet b:xxd_modified |
      \ call winrestview(b:xxd_view) | unlet b:xxd_view | endif
augroup END

"=====================================================
" Code folding
"=====================================================

set foldmethod=syntax   " Fold based on syntax
set foldcolumn=0        " Display zero (was 3) fold columns
set foldlevel=1         " Default fold level
set foldminlines=5      " Fold at least 5 lines

"=====================================================
" airline settings
"=====================================================

set laststatus=0    " Always show bottom status
set showtabline=2   " Always show top tabline
set noshowmode
set showcmd
set shm=fimnrxoOsI

let g:airline_theme='powerlineish'
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#formatter='short_home'
let g:airline#extensions#tabline#buffer_nr_show=1
let g:airline#extensions#tabline#show_buffers=1
let g:airline#extensions#tabline#show_splits=0
let g:airline#extensions#tabline#show_tabs=0
let g:airline#extensions#tabline#show_tab_nr=0
let g:airline#extensions#tabline#show_tab_type=0
let g:airline#extensions#tabline#show_close_button=0
let g:airline#extensions#ctrlp#show_adjacent_modes=0
let g:airline#extensions#virtualenv#enabled=1
let g:airline#extensions#ale#enabled=1
let g:airline#extensions#tagbar#enabled=1
au User AirlineAfterInit let g:airline_section_x=g:airline#section#create_right(['filetype'])
au User AirlineAfterInit let g:airline_section_y=g:airline#section#create_right(['bookmark', 'tagbar', 'vista', 'gutentags', 'gen_tags', 'omnisharp', 'grepper'])
au User AirlineAfterInit let g:airline_section_z=g:airline#section#create(['linenr', 'maxlinenr', ':%v'])
let g:airline_skip_empty_sections=1
let g:airline_mode_map = {
      \ '__'     : '-',
      \ 'c'      : 'C',
      \ 'i'      : 'I',
      \ 'ic'     : 'I-COMPL',
      \ 'ix'     : 'I-COMPL',
      \ 'n'      : 'N',
      \ 'multi'  : 'M',
      \ 'ni'     : '(N)',
      \ 'no'     : 'N',
      \ 'R'      : 'R',
      \ 'Rv'     : 'R-VIRTUAL',
      \ 's'      : 'S',
      \ 'S'      : 'S-LINE',
      \ ''     : 'S-BLOCK',
      \ 't'      : 'T',
      \ 'v'      : 'V',
      \ 'V'      : 'V-LINE',
      \ ''     : 'V-BLOCK',
      \ }

"=====================================================
" ale syntax checking
"=====================================================

let g:ale_sign_column_always=1
let g:ale_sign_error=' ✘'
let g:ale_sign_warning=' ⚠'
let g:ale_echo_msg_error_str='✘ '
let g:ale_echo_msg_warning_str='⚠ '
let g:ale_echo_msg_info_str='I '
let g:ale_echo_msg_format='%severity%%linter%: %code%: %s'
let g:ale_set_loclist=1
let g:ale_open_list=0
let g:ale_set_quickfix=0

"=====================================================
" Other keyboard shortcuts
"=====================================================

" If we forgot to sudo before an edit, then this allows to use w!! to save it
function! SudoSave()
  if &modified
    let l:view = winsaveview()
    redraw!
    silent exe '%!sudo tee > /dev/null %'
    set nomodified
    edit
    call winrestview(l:view)
    redraw!
  endif
endfunction
cnoremap w!! call SudoSave()

" Setup shortcuts at VimEnter
function! AddOtherShortcuts()
  " Movement on big linebreak'ed lines; conisder autocompletion handling
  nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')
  nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
  vnoremap <expr> j (v:count == 0 ? 'gj' : 'j')
  vnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
  nnoremap <Down> gj
  nnoremap <Up> gk
  vnoremap <Down> gj
  vnoremap <Up> gk
  inoremap <expr> <Down> (pumvisible() ? '<Down>' : '<C-\><C-o>gj')
  inoremap <expr> <Up> (pumvisible() ? '<Up>' : '<C-\><C-o>gk')

  " Keyboard folding of code
  nnoremap <silent> <Space> za
  vnoremap <silent> <Space> zf

  " Replace default tags goto with list if many matches
  nnoremap <C-]> g<C-]>

  " Keyboard jumping from insert mode; avoid messing up autocompletion C-e
  " Note: this overwrites C-a re-insert text and C-e insert character from below
  "       we replace C-a with M-. to insert last inserted text
  "       we replace C-e with M-e to insert character from next line
  inoremap <C-b> <Home>
  inoremap <C-a> <C-\><C-o>^
  cnoremap <C-a> <Home>
  inoremap <expr> <C-e> (pumvisible() ? '<C-e>' : '<End>')
  inoremap <M-.> <C-r>.
  inoremap <M-e> <C-e>
  inoremap <M-y> <C-y>

  " Write undo history when making a new line; with autocompletion handling
  inoremap <expr> <CR> (pumvisible() ? '<C-y>' : '<C-g>u<CR>')
  inoremap <expr> <C-u> (pumvisible() ? '<C-u>' : '<C-g>u<C-u>')

  " Write undo history when using register commands
  " This works well with autocompletion without using <expr> pumvisible()
  inoremap <C-r> <C-g>u<C-r>
  inoremap <C-w> <C-g>u<C-w>

  " Additional motions - function name
  onoremap <silent> F :<C-u>normal! 0f(hviw<CR>

  " DiffOrig
  nnoremap <Leader>o :DiffOrig

  " Modeline magic
  nnoremap <Leader>m :setl modeline <BAR>e<CR>
  nnoremap <Leader>M :setl nomodeline <BAR>e<CR>

  " Search word under cursor
  nnoremap <Leader>f /\V\<<C-r>=escape(expand('<cword>'), '/\?')<CR>\>
  nnoremap <Leader>F /\V<C-r>=escape(expand('<cWORD>'), '/\?')<CR>

  " Search selected text in visual mode
  vnoremap * y/\V<C-r>=escape(@", '/\?')<CR>
  vnoremap # y?\V<C-r>=escape(@", '/\?')<CR>
  vnoremap <Leader>f ygv/\V<C-r>=escape(@", '/\?')<CR>

  " Search-replace for word under cursor
  nnoremap <Leader>h :%s/\V\<<C-r>=escape(expand('<cword>'), '/\?')<CR>\>//gc<Left><Left><Left>
  nnoremap <Leader>H :%s/\V<C-r>=escape(expand('<cWORD>'), '/\?')<CR>//gc<Left><Left><Left>
  vnoremap <Leader>h ygv:%s/\V<C-r>=escape(@", '/\?')<CR>//gc<Left><Left><Left>

  " Find in files (needs vim-fugitive for git_dir function)
  nnoremap <Leader>gf :cexpr[]<BAR>silent! execute "grep!
                \ <C-r>=shellescape(fnamemodify(get(b:, 'git_dir', '.'), ':h'))<CR>
                \ -we <C-r>=shellescape(expand('<cword>'))<CR>
                \ "<BAR>cwindow<BAR>redraw!<S-Left><Left><Left>
  nnoremap <Leader>gF :cexpr[]<BAR>silent! execute "grep!
                \ <C-r>=shellescape(fnamemodify(get(b:, 'git_dir', '.'), ':h'))<CR>
                \ -e <C-r>=shellescape(expand('<cWORD>'))<CR>
                \ "<BAR>cwindow<BAR>redraw!<S-Left><Left><Left>
  vnoremap <Leader>gf ygv:cexpr[]<BAR>silent! execute "grep!
                \ <C-r>=shellescape(fnamemodify(get(b:, 'git_dir', '.'), ':h'))<CR>
                \ -we <C-r>=shellescape(@")<CR>
                \ "<BAR>cwindow<BAR>redraw!<S-Left><Left><Left>

  " Replace in qf found files with \gf or \gF
  nnoremap <Leader>gh :cdo %s/\V\<<C-r>=escape(expand('<cword>'), '/\?')<CR>\>//gc<Left><Left><Left>
  nnoremap <Leader>gH :cdo %s/\V<C-r>=escape(expand('<cWORD>'), '/\?')<CR>//gc<Left><Left><Left>
  vnoremap <Leader>gh ygv:cdo %s/\V<C-r>=escape(@", '/\?')<CR>//gc<Left><Left><Left>

  " Clear search highlighting
  nnoremap <silent> // :nohlsearch<CR>

  " Find tags in files (needs vim-fugitive for git_dir function)
  nnoremap <Leader>t :lexpr[]<BAR>lvimgrep! /\C\vTODO\|FIXME/j % <BAR>lopen<CR>
  nnoremap <Leader>gt :cexpr[]<BAR>silent! execute "grep!
                \ <C-r>=shellescape(fnamemodify(get(b:, 'git_dir', '.'), ':h'))<CR>
                \ -e 'TODO\\<BAR>FIXME'"<BAR>cwindow<BAR>redraw!<CR>

  " Filer quicklist
  nnoremap <Leader>q :call setqflist(filter(getqflist(), "bufname(v:val['bufnr']) =~# ''"))<Left><Left><Left><Left>

  " Buffer show
  nnoremap <Leader>b :ls<CR>:b<Space>

  " Wrap-around loclist (this over-rides vim-unimpaired functionality)
  command! -range=1 -bang Lnext try | <count>lnext<bang> | catch /E553/ | lfirst<bang> <count> | endtry
  command! -range=1 -bang Lprev try | <count>lprev<bang> | catch /E553/ | llast<bang> <count> | endtry
  nmap <silent> [l :<C-U>exe (v:count ? v:count : "")."Lprev"<CR>zv
  nmap <silent> ]l :<C-U>exe (v:count ? v:count : "")."Lnext"<CR>zv

  " Save anywhere
  silent !stty -ixon
  inoremap <silent> <C-s> <C-\><C-o>:update<CR>
  nnoremap <silent> <C-s> :update<CR>

  " Default vim action is to close the preview only; do the rest as well
  nnoremap <silent> <C-w>z :lclose<BAR>cclose<BAR>pclose<CR>
  nnoremap <silent> <C-w><C-z> :lclose<BAR>cclose<BAR>pclose<CR>

  " Quit shortcut to be useable with sessions - save current and quit all
  nnoremap <silent> ZZ :xa!<CR>
  nnoremap <silent> ZQ :qa!<CR>

  " Buffer close but keep window; if inside quickfix, just close it
  nnoremap <silent> <Leader>c :lclose<BAR>cclose<BAR>pclose<BAR>b#<BAR>bd#<CR>

  " NERDTree
  nnoremap <silent> <C-n> :call NERDTreeOpenCWDClose()<CR>

  " Tagbar
  nnoremap <silent> <C-j> :call tagbar#ToggleWindow('fjc')<CR>

  " Fugitive
  nnoremap <silent> <Leader>gg :G<CR>
  hi diffAdded ctermfg=green ctermbg=NONE cterm=NONE guifg=green guibg=NONE gui=NONE
  hi diffRemoved ctermfg=red ctermbg=NONE cterm=NONE guifg=red guibg=NONE gui=NONE

  " Edit this file
  nnoremap <silent> <Leader>v :e $MYVIMRC<CR>
  nnoremap <silent> <Leader>V :source $MYVIMRC<CR>

  " Hex mode
  nnoremap <silent> <Leader>x :if exists('b:xxd_mode') && b:xxd_mode == 1<BAR>
                \ echo "Already in hex mode!"<BAR>else<BAR>setlocal binary<BAR>
                \ edit!<BAR>let b:xxd_prev_ft = &ft<BAR>let b:xxd_modified = &modified<BAR>
                \ silent! exe '%!xxd -g 1'<BAR>
                \ let &modified = b:xxd_modified<BAR>unlet b:xxd_modified<BAR>
                \ let b:xxd_mode = 1<BAR>setlocal ft=xxd<BAR>endif<CR>
  nnoremap <silent> <Leader>X :if exists('b:xxd_mode') && b:xxd_mode == 1<BAR>
                \ let &l:ft = b:xxd_prev_ft<BAR>let b:xxd_modified = &modified<BAR>
                \ silent! exe '%!xxd -r'<BAR>
                \ let &modified = b:xxd_modified<BAR>unlet b:xxd_modified<BAR>
                \ let b:xxd_mode = 0<BAR>file<BAR>
                \ else<BAR>echo "Not in hex mode!"<BAR>endif<CR>

  redraw!
endfunction

augroup OtherShortcuts
  autocmd!
  au VimEnter * call AddOtherShortcuts()
augroup END

" Update time stamps etc. before saving
function! PythonFileUpdater()
  let l:view = winsaveview()
  retab " Replace tabs with spaces
  try
    exec '1,20 s/__updated__\s*=\s*''\S*''/__updated__ = '''.strftime('%Y-%m-%d').'''/i'
  catch
    silent! exec '| /__updated__/s/__updated__\s*=\s*''\S*''/__updated__ = '''.strftime('%Y-%m-%d').'''/i'
  finally
    call winrestview(l:view)
  endtry
endfunction

augroup AutomaticFileUpdaters
  autocmd!
  au BufWritePre * if &ft == 'python' | try | undojoin | call PythonFileUpdater() | catch /^Vim\%((\a\+)\)\=:E790/ | endtry | endif
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
  elseif filereadable(expand('%')) " Show file, if exists
    NERDTreeFind
  elseif isdirectory(expand('%:p:h')) " Show directory of file instead
    NERDTree %:p:h
  elseif isdirectory(expand('%:p:h:h')) " Show parent directory instead
    NERDTree %:p:h
  else
    NERDTree " File, directory and parent actually do not exist
  endif
endfunction

augroup AutoClose
  autocmd!
  " Close NERDTree if it's the only one open in a tab
  au BufEnter * if winnr("$") == 1 && exists('g:NERDTree') && g:NERDTree.IsOpen() | q | endif

  " Close other stuff before saving session
  au VimLeavePre * call tagbar#CloseWindow() | NERDTreeClose | lclose | cclose | pclose
augroup END

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
let g:jedi#use_splits_not_buffers = "left"

" Keyboard shortcuts
let g:jedi#completions_command = "<C-Space>"

let g:jedi#goto_command = "<leader>d"
let g:jedi#goto_assignments_command = "<leader>a"
let g:jedi#goto_stubs_command = "<leader>s"
let g:jedi#usages_command = "<leader>n"

let g:jedi#rename_command = "<leader>r"
let g:jedi#documentation_command = "K"

" Call signature scan get quite slow with big libraries like pandas
" autocmd FileType python call jedi#configure_call_signatures()

"=====================================================
" SimpylFold settings
"=====================================================

let g:SimpylFold_docstring_preview=1
let g:SimpylFold_fold_docstring=0
let g:SimpylFold_fold_import=0

"=====================================================
" vim-virtualenv settings
"=====================================================

let g:virtualenv_auto_activate=1

"=====================================================
" Tagbar settings
"=====================================================

let g:tagbar_zoomwidth = 60 " Bigger window size
let g:tagbar_compact = 1 " Don't show help ? info
let g:tagbar_autoshowtag = 1 " Expand folds to show current tag

"=====================================================
" Faster background clearing
"=====================================================

if has('gui_running') || has('nvim')
  hi Normal guifg=#f8f8f2 guibg=#272822
elseif &term == 'xterm-kitty'
  " Set the terminal default background and foreground colors, thereby
  " improving performance by not needing to set these colors on empty cells.
  hi Normal guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE
  let &t_ti = &t_ti . "\033]10;#f8f8f2\007\033]11;#272822\007"
  let &t_te = &t_te . "\033]110\007\033]111\007"
  let &t_RV = ""

  " Disable kitty keyboard protocol as we use legacy VT mode
  " Also, we disable xterm:mok2 mode
  " This was added by some people using emacs who wanted additional key combinations
  " Ref: https://invisible-island.net/xterm/modified-keys.html
  " Meta keys should work as long as they are sent 8bit (kitty.conf), as it should be
  set keyprotocol=
  set term=xterm-256color
endif

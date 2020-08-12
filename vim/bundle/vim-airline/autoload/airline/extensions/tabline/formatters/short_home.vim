" MIT License. Copyright (c) 2020 Dorian Bivolaru
" vim: et ts=2 sts=2 sw=2

scriptencoding utf-8

let s:fnamecollapse = get(g:, 'airline#extensions#tabline#fnamecollapse', 1)

function! airline#extensions#tabline#formatters#short_home#format(bufnr, buffers)
  let _ = ''

  let name = bufname(a:bufnr)
  if empty(name)
    let _ = '[No Name]'
  elseif name =~ 'term://'
    " Neovim Terminal
    let _ = substitute(name, '\(term:\)//.*:\(.*\)', '\1 \2', '')
  elseif empty(win_findbuf(a:bufnr))
    " Display parent folder and filename only
    let _ = fnamemodify(name, ':p:~:h:t') . '/' . fnamemodify(name, ':t')
  else
    " Buffer is shown in a window, so we only show it's name
    let _ = fnamemodify(name, ':t')
  endif

  return airline#extensions#tabline#formatters#default#wrap_name(a:bufnr, _)
endfunction

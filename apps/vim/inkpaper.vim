" inkpaper: warm paper, black ink, one red accent. Works with background=light and dark.
hi clear
if exists('syntax_on') | syntax reset | endif
let g:colors_name = 'inkpaper'

if &background ==# 'dark'
  let s:bg = '#141414' | let s:surf = '#1E1E1E' | let s:line = '#2A2826'
  let s:fg = '#E9E4DA' | let s:muted = '#5C5853' | let s:soft = '#8A8580' | let s:acc = '#C8473A'
  let s:str = '#8E907F' | let s:num = '#B3A283' | let s:typ = '#858C96' | let s:fn = '#CFC9BE'
else
  let s:bg = '#F2EEE6' | let s:surf = '#E7E2D8' | let s:line = '#DDD7CC'
  let s:fg = '#1A1A1A' | let s:muted = '#8A8580' | let s:soft = '#5C5853' | let s:acc = '#B23A2E'
  let s:str = '#5F6152' | let s:num = '#7D6E52' | let s:typ = '#565D68' | let s:fn = '#3A3836'
endif

function! s:hi(group, fg, bg, attr) abort
  execute 'hi' a:group 'guifg=' . a:fg 'guibg=' . a:bg 'gui=' . a:attr 'cterm=' . a:attr
endfunction

call s:hi('Normal',       s:fg,    s:bg,   'NONE')
call s:hi('Comment',      s:soft,  'NONE', 'italic')
call s:hi('Constant',     s:num,   'NONE', 'NONE')
call s:hi('String',       s:str,   'NONE', 'NONE')
call s:hi('Character',    s:str,   'NONE', 'NONE')
call s:hi('Identifier',   s:fg,    'NONE', 'NONE')
call s:hi('Function',     s:fn,    'NONE', 'NONE')
call s:hi('Statement',    s:fg,    'NONE', 'bold')
call s:hi('Operator',     s:soft,  'NONE', 'NONE')
call s:hi('PreProc',      s:soft,  'NONE', 'NONE')
call s:hi('Type',         s:typ,   'NONE', 'NONE')
call s:hi('Special',      s:soft,  'NONE', 'NONE')
call s:hi('Delimiter',    s:soft,  'NONE', 'NONE')
call s:hi('Underlined',   s:fg,    'NONE', 'underline')
call s:hi('Todo',         s:acc,   'NONE', 'bold')
call s:hi('Error',        s:acc,   'NONE', 'bold')
call s:hi('ErrorMsg',     s:acc,   'NONE', 'bold')
call s:hi('WarningMsg',   s:num,   'NONE', 'NONE')
call s:hi('Title',        s:fg,    'NONE', 'bold')
call s:hi('Directory',    s:fg,    'NONE', 'bold')
call s:hi('LineNr',       s:muted, 'NONE', 'NONE')
call s:hi('CursorLineNr', s:fg,    'NONE', 'bold')
call s:hi('CursorLine',   'NONE',  s:surf, 'NONE')
call s:hi('ColorColumn',  'NONE',  s:surf, 'NONE')
call s:hi('SignColumn',   s:muted, s:bg,   'NONE')
call s:hi('Visual',       'NONE',  s:line, 'NONE')
call s:hi('Search',       s:fg,    s:line, 'underline')
call s:hi('IncSearch',    s:bg,    s:acc,  'NONE')
call s:hi('MatchParen',   s:acc,   'NONE', 'bold')
call s:hi('NonText',      s:line,  'NONE', 'NONE')
call s:hi('SpecialKey',   s:line,  'NONE', 'NONE')
call s:hi('Folded',       s:soft,  s:surf, 'NONE')
call s:hi('StatusLine',   s:fg,    s:surf, 'NONE')
call s:hi('StatusLineNC', s:muted, s:surf, 'NONE')
call s:hi('VertSplit',    s:line,  s:bg,   'NONE')
call s:hi('WinSeparator', s:line,  s:bg,   'NONE')
call s:hi('TabLine',      s:soft,  s:surf, 'NONE')
call s:hi('TabLineFill',  'NONE',  s:surf, 'NONE')
call s:hi('TabLineSel',   s:fg,    s:bg,   'bold')
call s:hi('Pmenu',        s:fg,    s:surf, 'NONE')
call s:hi('PmenuSel',     s:bg,    s:fg,   'NONE')
call s:hi('PmenuSbar',    'NONE',  s:surf, 'NONE')
call s:hi('PmenuThumb',   'NONE',  s:muted,'NONE')
call s:hi('DiffAdd',      s:str,   s:surf, 'NONE')
call s:hi('DiffChange',   s:num,   s:surf, 'NONE')
call s:hi('DiffDelete',   s:acc,   s:surf, 'NONE')
call s:hi('DiffText',     s:fg,    s:line, 'bold')
call s:hi('SpellBad',     'NONE',  'NONE', 'undercurl')

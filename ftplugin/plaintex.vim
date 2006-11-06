" plain TeX filetype plugin
"  Maintainer:  Benji Fisher PhD   <benji@member.AMS.org>
"  Version:     0.2 for Vim 7.0+
"  Last Change: Mon Nov 06 12:00 PM 2006 EST
"  URL:		http://www.vim.org/scripts/script.php?script_id=1685

" Documentation:
"  The documentation is in a separate file, doc/ft-plaintex.txt .
"  TODO:  A map to invoke a viewer (xdvi or xpdf or ...)

" Credits:
"  Vim editor by Bram Moolenaar (Thanks, Bram!)

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif
" b:did_ftplugin will be defined in the default ftplugin.

" Avoid problems if running in 'compatible' mode.
let s:save_cpo = &cpo
set cpo&vim

" Customization: {{{

" Either edit this file directly or else copy the following section to a file
" plaintex.vimrc in your ftplugin directory, normally the same directory as
" this file.  If your system administrator has installed this file, you should
" install plaintex.vimrc in your after/ftplugin/ directory so that your
" choices override the system defaults.  See
"   :help ftplugin-overrule
"   :help 'runtimepath'
" for details.
"
" If you have edited this file directly, and you are going to replace it with
" an updated version, you should first write out the section below to a
" separate vimrc file.
" ==================== file plaintex.vimrc ====================
" User Configuration file for plaintex.vim .
  " " Open and close quotes:
  " let g:Tex_SmartQuotes = {'open': "``", 'close': "''"}
  " " Produce DVI or PDF output:
  " let g:Tex_DefaultTargetFormat = 'dvi'
  " let g:Tex_DefaultTargetFormat = 'pdf'
  " " Top-level menu, such as '&Plugin.&TeX'
  " let g:Tex_menuRoot = 'Te&X'
  " " Override the default key mappings for italic, bold, etc:
  " let g:Tex_Keymaps = {'jump': '<C-J>', 'bold': '<C-B>', 'italic': '<C-T>'}
" ==================== end: plaintex.vimrc ====================

" source the user configuration file(s): }}}
runtime! ftplugin/<sfile>:t:r.vimrc

" Set the compiler.  First specify dvi or pdf output (to use tex or pdftex).
" The default may change, so it is best to set this explicitly.
if !exists("g:Tex_DefaultTargetFormat")
  let g:Tex_DefaultTargetFormat = 'dvi'
endif
compiler plaintex

" Function Definitions:
" The functions do not have to be re-defined if this file was :source'd when
" some other plain TeX file was loaded.
if !exists("*s:TeXquotes") " {{{

" TeXquotes: inserts `` or '' instead of "
" TODO:  Deal with nested quotes.
" The :imap that calls this function should insert a ", move the cursor to
" the left of that character, then call this with <C-R>= .
function! s:TeXquotes() " {{{
  let view = winsaveview()
  let l = line(".")
  let c = col(".")
  " In math mode, or when preceded by a \, just move the cursor past the
  " already-inserted " character.
  if synIDattr(synID(l, c, 1), "name") =~ "^plaintexMath"
	\ || (c > 1 && getline(l)[c-2] == '\')
    return "\<Right>"
  endif
  " Find the appropriate open-quote and close-quote strings.
  if exists("b:Tex_SmartQuotes")
    let open = b:Tex_SmartQuotes['open']
    let close = b:Tex_SmartQuotes['close']
  elseif exists("g:Tex_SmartQuotes")
    let open = g:Tex_SmartQuotes['open']
    let close = g:Tex_SmartQuotes['close']
  else
    let open = "``"
    let close = "''"
  endif
  let boundary = '\|'
  " Some languages use ",," as an open- or close-quote string, and we want to
  " avoid confusing ordinary "," with a quote boundary.
  if exists("b:TeX_strictquote")
    let strictquote = b:TeX_strictquote
  elseif exists("g:TeX_strictquote")
    let strictquote = g:TeX_strictquote
  endif
  if exists("strictquote")
    if( strictquote == "open" || strictquote == "both" )
      let boundary = '\<' . boundary
    endif
    if( strictquote == "close" || strictquote == "both" )
      let boundary = boundary . '\>'
    endif
  endif
  " Eventually return q; set it to the default value now.
  let q = open
  while 1	" Look for preceding quote (open or close), ignoring
    " math mode and '\"' .
    call search(open . boundary . close . '\|^$\|"', "bw")
    if synIDattr(synID(line("."), col("."), 1), "name") !~ "^texMath"
	  \ && (col(".") == 1 || getline(".")[col(".")-2] != '\')
      break
    endif
  endwhile
  " Now, test whether we actually found a _preceding_ quote; if so, is it
  " an open quote?
  if ( line(".") < l || line(".") == l && col(".") < c )
	\ && strpart(getline("."), col(".")-1) =~ '\V\^' . escape(open, '\')
    let q = close
  endif
  " Restore the original view.
  call winrestview(view)
  " Start with <Del> to remove the " put in by the :imap .
  return "\<Del>" . q
endfunction " }}}

" Search forwards (a:dir == 'f') or backwards (a:dir == 'b') for the marker
" '<+' .  If it is immediately followed by '+>', then delete and enter Insert
" mode.  If there is any text in between the opening and closing marker, then
" mark the whole string in Select mode.
function! s:Jump(dir, ...) " {{{
  let startpos = getpos(".")
  let spat = a:0 ? '<+' . a:1 : '<+'
  let sflags = (a:dir == 'b') ? 'bw' : 'cw'
  if search(spat, sflags) == 0
    return
  endif
  let [buf, line, col, off] = getpos(".")
  if strpart(getline(line), col - 1, 4) == '<++>'
    normal! 4x
    if col(".") == col
      startinsert
    else
      startinsert!
    endif
  else
    let [endl, endc] = searchpos('+>', 'enW')
    if endl == 0
      call setpos(".", startpos)
      return
    endif
    " call setpos("'<", [buf, line, col, off])
    call setpos("''", [buf, endl, endc, off])
    execute "normal! v``\<C-G>"
  endif
endfun " }}}

" Create matching mappings and menu entries.  For example,
" :call s:Map('ic', '&Foo.&Bar', '<C-F>b', 'FooBar')
" will execute the menu commands
" :imenu <buffer> Te&X.&Foo.&Bar<Tab><C-F>b FooBar
" :cmenu <buffer> Te&X.&Foo.&Bar<Tab><C-F>b FooBar
" and the map commands
" :imap <buffer> <C-F>b FooBar
" :cmap <buffer> <C-F>b FooBar
fun! s:Map(modes, menu, key, rhs) " {{{
  let root = exists("g:Tex_menuRoot") ? g:Tex_menuRoot . "." : 'Te&X.'
  let key = strlen(a:key) ? '<Tab>' . a:key : ''
  for mode in split(a:modes, '\zs')
    execute mode . "menu" root . a:menu . key a:rhs
    if strlen(a:key)
      execute mode . "map <buffer>" a:key a:rhs
    endif
  endfor
endfun " }}}

endif " }}}

" Key Mappings:
" Make a Dictionary of Dictionaries to describe the key maps.
let s:Keymaps = {}
let s:Keymaps.bold = {'key': '<C-B>', 'open': '{\bf ', 'close': '}'}
let s:Keymaps.italic = {'key': '<C-T>', 'open': '{\it ', 'close': '\/}'}
if exists("g:Tex_Keymaps")
" The user wants to override one or more of the default key bindings.
  for style in keys(g:Tex_Keymaps)
    if get(s:Keymaps, style, {}) != {}
      s:Keymaps[style].key = g:Tex_Keymaps[key]
    endif
  endfor
endif

" Define 'smart quote' mappings and jumps to <+ +> markers:
call s:Map('i', 'Smart\ Quotes', '"', '<C-V>"<Left><C-R>=<SID>TeXquotes()<CR>')
let s:jump = exists("g:Tex_Keymaps") ?
      \ get(g:Tex_Keymaps, 'jump', '<C-J>') : '<C-J>'
let s:jumpback = exists("g:Tex_Keymaps") ?
      \ get(g:Tex_Keymaps, 'jumpback', '') : ''
call s:Map('n', 'Next\ Marker', s:jump, ":call <SID>Jump('f')<CR>")
call s:Map('i', 'Next\ Marker', s:jump, "<C-O>:call <SID>Jump('f')<CR>")
call s:Map('n', 'Prev\ Marker', s:jumpback, ":call <SID>Jump('b')<CR>")
call s:Map('i', 'Prev\ Marker', s:jumpback, "<C-O>:call <SID>Jump('b')<CR>")

" Define a menu item for each entry in s:Keymaps.  If the key field exists and
" is a non-empty String, also define maps in Visual, Normal, and Insert modes.
for [menu, style] in items(s:Keymaps)
  let rhs = style.open . "<+!+>" . style.close . "<++>"
	\ . '<C-\><C-N>:call <SID>Jump("b", "!")<CR>x<BS>'
  call s:Map('i', menu, style.key, rhs)
  let rhs = "c" . style.open . '<C-R>"' . style.close . '<C-\><C-N>'
  call s:Map('v', menu, style.key, rhs)
  let rhs = "viw" . style.key
  call s:Map('n', menu, style.key, rhs)
endfor

let &cpo = s:save_cpo

" vim:sts=2:sw=2:fdm=marker:

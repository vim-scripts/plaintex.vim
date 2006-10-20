" Vim compiler file
" Language:     plain TeX (file type plaintex)
" Maintainer:   Benji Fisher, Ph.D. <benji@member.AMS.org>
" Last Change: Tue Sep 26 04:00 PM 2006 EDT

" based on the default compiler/tex.vim by Artem Chuprina

if exists("current_compiler")
  finish
endif

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

" Following the default compiler/tex.vim , prefer to use "make" if a Makefile
" can be found; allow the user to override with a global or buffer-local
" variable.  If not using "make", then decide whether to use "tex" or
" "pdftex".  Check for the global variable g:Tex_DefaultTargetFormat , which
" is defined if the user has installed LaTeX-suite.  If not defined, default
" to PDF; this default may be changed in a later version of this file.
if exists('b:tex_ignore_makefile') || exists('g:tex_ignore_makefile') ||
      \(!filereadable('Makefile') && !filereadable('makefile'))
  if exists('g:Tex_DefaultTargetFormat') && g:Tex_DefaultTargetFormat !=? 'pdf'
    let current_compiler = 'tex'
  else
    let current_compiler = 'pdftex'
  endif
  let &l:makeprg = current_compiler . ' \\nonstopmode \\input %:r'
else
  let current_compiler = 'make'
endif

let s:cpo_save = &cpo
set cpo-=C

if 0
" The errorformat is cribbed from the default compiler/tex.vim and then hacked
" to replace LaTeX-specific items with plain TeX-isms.
CompilerSet errorformat=
      \%E!\ %m,
      \%Cl.%l\ %m,
      \%+C\ \ %m.,
      \%+C%.%#-%.%#,
      \%+C%.%#[]%.%#,
      \%+C[]%.%#,
      \%+C%.%#%[{}\\]%.%#,
      \%+C<%.%#>%.%#,
      \%C\ \ %m,
      \%-GThis\ is\ TeX%.%#,
      \%-GThis\ is\ pdfTeX%.%#,
      \%-GOutput\ written\ on%.%#,
      \%-GTranscript\ written\ on%.%#,
      \%-GType\ \ H\ <return>%m,
      \%-G\ ...%.%#,
      \%-G%.%#\ (C)\ %.%#,
      \%-G(see\ the\ transcript%.%#),
      \%-G\\s%#,
      \%-O(%*[^()])%r,
      \%+O%*[^()](%*[^()])%r,
      \%+P(%f%r,
      \%+P\ %\\=(%f%r,
      \%+P%*[^()](%f%r,
      \%+P[%\\d%[^()]%#(%f%r,
      \%+Q)%r,
      \%+Q%*[^()])%r,
      \%+Q[%\\d%*[^()])%r
else
  CompilerSet errorformat=
	\%-GThis\ is\ TeX%.%#,
	\%-GThis\ is\ pdfTeX%.%#,
	\%-G(see\ the\ transcript\ file%.%#,
	\%-GOutput\ written\ on%.%#,
	\%-GTranscript\ written\ on%.%#,
	\%-G\\s%#,
	\%+P(%f%r,
	\%-Q%*[^()])%r,
	\%E%>!\ %m,
	\%C%>l.%l\ %m,
	\%C%>l.%l%m,
	\%-Z%p,
	\%C%><%.%#>%.%#,
	\%C%.%#,
	\%-O%.%#
endif

let &cpo = s:cpo_save
unlet s:cpo_save

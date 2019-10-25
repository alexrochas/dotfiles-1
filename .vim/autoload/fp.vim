" Heavily truncate a file path
"
" /path/to/file.js -> /p/t/file.js
" /home/path/to/file.js -> ~/p/t/file.js
fu! fp#ShortPath(path)
    let l:sep = '/'

    let l:file = fnamemodify(a:path, ':t')
    let l:path = fnamemodify(a:path, ':p:~:h')
    let l:head = l:path[0] is '/' ? l:path[0] : ''

    let l:segs = split(l:path, l:sep)
    let l:mods = map(l:segs, 'v:val[0]')
    let l:ret = join(l:mods, l:sep)

    return l:head . l:ret . l:sep . l:file
endfu

" Vim only has quickfix/loclist autocommands that trigger when specific
" commands are run and not when the actual contents change. This makes it hard
" to react to changes that happen behind the scenes (e.g., setqflist()).
fu! fp#OnChanged(Fn, Cb)
    let l:lastret = v:null
    let l:Fn = a:Fn
    let l:Cb = a:Cb

    fu! Wrapper(...) closure
        let l:newret = l:Fn(a:000)
        if l:lastret isnot v:null && l:lastret != l:newret
            call l:Cb(l:lastret, a:000)
        endif
        let l:lastret = l:newret
    endfu

    return funcref('Wrapper')
endfu

let s:QfChanged = fp#OnChanged({-> getqflist({'changedtick': 1, 'id': 0})},
    \ {-> execute('silent doautocmd <nomodeline> User QfChanged')})
let s:LlChanged = fp#OnChanged({-> getloclist(0, {'changedtick': 1, 'id': 0})},
    \ {-> execute('silent doautocmd <nomodeline> User LlChanged')})

fu! fp#StartQfWatchers()
    call timer_start(1000, s:QfChanged, {'repeat': -1})
    call timer_start(1000, s:LlChanged, {'repeat': -1})
endfu

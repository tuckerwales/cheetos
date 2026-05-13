# Vim

## Modes
- `i` — insert before cursor
- `a` — insert after cursor
- `I` — insert at line start
- `A` — insert at line end
- `o` — new line below
- `O` — new line above
- `Esc` — back to normal mode
- `v` — visual
- `V` — visual line
- `Ctrl-v` — visual block

## Movement
- `h j k l` — left / down / up / right
- `w` — next word
- `b` — previous word
- `e` — end of word
- `0` — line start
- `^` — first non-blank
- `$` — line end
- `gg` — top of file
- `G` — bottom of file
- `{` `}` — paragraph up / down
- `Ctrl-d` / `Ctrl-u` — half-page down / up
- `Ctrl-f` / `Ctrl-b` — page down / up
- `%` — matching bracket

## Editing
- `x` — delete char
- `dd` — delete line
- `dw` — delete word
- `d$` — delete to end of line
- `yy` — yank line
- `yw` — yank word
- `p` — paste after
- `P` — paste before
- `u` — undo
- `Ctrl-r` — redo
- `r<char>` — replace char
- `R` — replace mode
- `cw` — change word
- `cc` — change line
- `>>` — indent
- `<<` — outdent
- `.` — repeat last change

## Search & Replace
- `/pattern` — search forward
- `?pattern` — search backward
- `n` — next match
- `N` — previous match
- `*` — search word under cursor
- `:%s/old/new/g` — replace all in file
- `:%s/old/new/gc` — replace with confirm

## Files & Buffers
- `:w` — write
- `:q` — quit
- `:wq` — write + quit
- `:q!` — quit without saving
- `:e file` — edit file
- `:bn` / `:bp` — next / prev buffer
- `:ls` — list buffers
- `Ctrl-^` — toggle last buffer

## Windows
- `:sp` — horizontal split
- `:vsp` — vertical split
- `Ctrl-w h/j/k/l` — move between splits
- `Ctrl-w q` — close split
- `Ctrl-w =` — equalize sizes

## Marks & Jumps
- `ma` — set mark a
- `'a` — jump to line of mark a
- `Ctrl-o` — jump back
- `Ctrl-i` — jump forward

## Macros
- `qa` — start recording macro a
- `q` — stop recording
- `@a` — play macro a
- `@@` — replay last macro

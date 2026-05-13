# tmux

> Default prefix is `Ctrl-b`.

## Sessions
- `tmux new -s name` — start named session
- `tmux ls` — list sessions
- `tmux attach -t name` — attach to session
- `tmux kill-session -t name` — kill session
- `prefix d` — detach
- `prefix $` — rename session
- `prefix s` — list / switch sessions

## Windows
- `prefix c` — new window
- `prefix ,` — rename window
- `prefix n` / `prefix p` — next / prev window
- `prefix 0..9` — switch by number
- `prefix w` — list windows
- `prefix &` — kill window

## Panes
- `prefix %` — split vertical
- `prefix "` — split horizontal
- `prefix arrow` — switch pane
- `prefix o` — next pane
- `prefix z` — zoom pane toggle
- `prefix x` — kill pane
- `prefix {` / `prefix }` — swap pane
- `prefix space` — next layout
- `prefix Ctrl-arrow` — resize pane (hold)

## Copy Mode
- `prefix [` — enter copy mode
- `space` — start selection
- `enter` — copy selection
- `prefix ]` — paste
- `q` — exit copy mode
- `/` — search forward
- `?` — search backward

## Misc
- `prefix ?` — show all key bindings
- `prefix :` — command prompt
- `prefix t` — show clock
- `:source-file ~/.tmux.conf` — reload config

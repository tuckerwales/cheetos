# Bash

## Navigation & Files
- `pwd` — current directory
- `cd -` — previous directory
- `pushd <dir>` / `popd` — directory stack
- `ls -lah` — long, all, human sizes
- `tree -L 2` — recursive listing (depth 2)
- `du -sh *` — size per item
- `df -h` — disk usage

## Redirection & Pipes
- `cmd > file` — stdout to file (overwrite)
- `cmd >> file` — append
- `cmd 2> file` — stderr to file
- `cmd &> file` — both to file
- `cmd1 | cmd2` — pipe
- `cmd1 |& cmd2` — pipe stdout + stderr
- `cmd < file` — stdin from file
- `cmd <<< "string"` — here-string

## Variables
- `VAR=value` — assign (no spaces)
- `export VAR=value` — export to env
- `"$VAR"` — quote to preserve spaces
- `${VAR:-default}` — default if unset
- `${VAR:=default}` — assign default if unset
- `${VAR#prefix}` / `${VAR%suffix}` — strip
- `$(cmd)` — command substitution

## Control Flow
```
if [[ "$x" == "y" ]]; then ... ; fi
for f in *.txt; do echo "$f"; done
while read -r line; do ...; done < file
case "$x" in a) ... ;; b) ... ;; esac
```

## Tests
- `[[ -f file ]]` — file exists
- `[[ -d dir ]]` — directory exists
- `[[ -z "$s" ]]` — empty string
- `[[ -n "$s" ]]` — non-empty
- `[[ "$a" == "$b" ]]` — equal
- `(( n > 0 ))` — arithmetic

## Job Control
- `cmd &` — run in background
- `jobs` — list jobs
- `fg %1` — foreground job 1
- `bg %1` — background job 1
- `Ctrl-Z` — suspend; `Ctrl-C` — interrupt
- `nohup cmd &` — survive logout

## Shortcuts
- `Ctrl-R` — reverse history search
- `Ctrl-A` / `Ctrl-E` — line start / end
- `Ctrl-U` / `Ctrl-K` — kill to start / end
- `Ctrl-W` — kill word
- `!!` — last command; `!$` — last arg
- `^old^new` — rerun replacing old with new

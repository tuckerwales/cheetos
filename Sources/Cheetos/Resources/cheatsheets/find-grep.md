# Find & Grep

## find — by name
- `find . -name '*.md'` — by name (case sensitive)
- `find . -iname '*.MD'` — case insensitive
- `find . -path '*/node_modules' -prune -o -print` — exclude dir
- `find . -maxdepth 2 -name '*.js'` — limit depth

## find — by type / size / time
- `find . -type f` — files only
- `find . -type d` — directories only
- `find . -size +10M` — larger than 10MB
- `find . -size -1k` — smaller than 1KB
- `find . -mtime -7` — modified within 7 days
- `find . -mmin -60` — modified within 60 min
- `find . -newer ref.txt` — newer than file

## find — actions
- `find . -name '*.tmp' -delete` — delete matches
- `find . -name '*.log' -exec rm {} +` — exec on each
- `find . -name '*.png' -exec mv {} dest/ \;` — one-at-a-time
- `find . -type f -print0 | xargs -0 grep foo` — null-safe pipe

## grep — basics
- `grep 'pat' file` — search in file
- `grep -r 'pat' .` — recursive
- `grep -rn 'pat' .` — with line numbers
- `grep -rni 'pat' .` — + case insensitive
- `grep -rl 'pat' .` — list matching files
- `grep -rL 'pat' .` — list non-matching files
- `grep -c 'pat' file` — count matches
- `grep -v 'pat' file` — invert match

## grep — context & patterns
- `grep -A 3 'pat' file` — 3 lines after
- `grep -B 3 'pat' file` — 3 lines before
- `grep -C 3 'pat' file` — 3 lines around
- `grep -E 'a|b'` — extended regex (or `egrep`)
- `grep -F 'literal'` — fixed string (fast)
- `grep -w 'word'` — whole word
- `grep --include='*.py' -r 'pat' .` — only .py files
- `grep --exclude-dir=node_modules -r 'pat' .` — skip dir

## Faster alternatives
- `rg 'pat'` — ripgrep, respects .gitignore
- `rg -t py 'pat'` — restrict by type
- `fd '<pat>'` — fast find replacement
- `fd -e md` — by extension

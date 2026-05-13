# Git

## Setup
- `git init` — initialize repo
- `git clone <url>` — clone repo
- `git remote -v` — list remotes
- `git remote add origin <url>` — add remote

## Daily
- `git status` — show changes
- `git add <file>` — stage file
- `git add -p` — stage hunks interactively
- `git commit -m "msg"` — commit staged
- `git commit -a -m "msg"` — stage tracked + commit
- `git commit --amend` — amend last commit
- `git diff` — unstaged diff
- `git diff --staged` — staged diff
- `git log --oneline --graph --decorate` — pretty log

## Branches
- `git branch` — list branches
- `git switch <name>` — switch branch
- `git switch -c <name>` — create + switch
- `git branch -d <name>` — delete branch
- `git branch -D <name>` — force delete

## Merge & Rebase
- `git merge <branch>` — merge into current
- `git rebase <branch>` — rebase onto branch
- `git rebase -i HEAD~N` — interactive rebase last N
- `git rebase --continue` — resume after fixing conflicts
- `git rebase --abort` — cancel rebase
- `git cherry-pick <sha>` — apply single commit

## Sync
- `git fetch` — fetch refs
- `git pull --rebase` — pull with rebase
- `git push` — push current branch
- `git push -u origin <branch>` — set upstream

## Undo
- `git restore <file>` — discard working changes
- `git restore --staged <file>` — unstage
- `git reset --soft HEAD~1` — undo commit, keep changes staged
- `git reset --hard HEAD~1` — discard last commit + changes
- `git revert <sha>` — create reverting commit

## Stash
- `git stash` — stash changes
- `git stash -u` — include untracked
- `git stash list` — list stashes
- `git stash pop` — apply + drop
- `git stash apply` — apply, keep stash

## Inspect
- `git show <sha>` — show commit
- `git blame <file>` — line authorship
- `git log -p <file>` — history with patches
- `git reflog` — ref history (recovery)

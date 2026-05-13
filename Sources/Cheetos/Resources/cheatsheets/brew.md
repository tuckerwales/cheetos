# Homebrew

## Packages
- `brew install <pkg>` — install formula
- `brew install --cask <app>` — install GUI app
- `brew uninstall <pkg>` — remove
- `brew reinstall <pkg>` — reinstall
- `brew list` — installed formulae
- `brew list --cask` — installed casks
- `brew leaves` — explicitly installed (no deps)
- `brew deps <pkg>` — dependencies
- `brew uses --installed <pkg>` — reverse deps

## Search & Info
- `brew search <term>` — search
- `brew info <pkg>` — details + caveats
- `brew home <pkg>` — open homepage

## Update & Upgrade
- `brew update` — refresh formulae
- `brew outdated` — list upgradable
- `brew upgrade` — upgrade all
- `brew upgrade <pkg>` — upgrade one
- `brew pin <pkg>` / `brew unpin <pkg>` — hold version

## Services
- `brew services list` — service status
- `brew services start <pkg>` — start at login
- `brew services stop <pkg>` — stop service
- `brew services restart <pkg>` — restart
- `brew services run <pkg>` — start without login persistence

## Cleanup & Doctor
- `brew cleanup` — remove old versions
- `brew cleanup -s` — also clear cache
- `brew autoremove` — remove unused deps
- `brew doctor` — diagnose issues
- `brew config` — show config
- `brew --prefix` — install prefix (e.g. /opt/homebrew)

## Taps
- `brew tap` — list taps
- `brew tap <user/repo>` — add tap
- `brew untap <user/repo>` — remove tap

# SSH

## Connect
- `ssh user@host` — connect
- `ssh -p 2222 user@host` — custom port
- `ssh -i ~/.ssh/key user@host` — specific key
- `ssh -v user@host` — verbose (debug)
- `ssh user@host <cmd>` — run remote command

## Keys
- `ssh-keygen -t ed25519 -C "you@host"` — generate key
- `ssh-keygen -p -f <key>` — change passphrase
- `ssh-keygen -lf <key>` — fingerprint
- `ssh-copy-id user@host` — install public key on host
- `ssh-add ~/.ssh/key` — add to agent
- `ssh-add -l` — list loaded keys

## Tunnels
- `ssh -L 8080:localhost:80 user@host` — local forward
- `ssh -R 8080:localhost:80 user@host` — remote forward
- `ssh -D 1080 user@host` — SOCKS proxy
- `ssh -N -f user@host` — background, no shell
- `ssh -J jump@host user@target` — jump host

## Copy Files
- `scp file user@host:/path` — copy to remote
- `scp user@host:/path file` — copy from remote
- `scp -r dir user@host:/path` — recursive
- `rsync -avz dir user@host:/path` — sync (preferred)
- `rsync -avz --delete src/ user@host:/dst/` — mirror

## Config (~/.ssh/config)
```
Host myserver
  HostName 1.2.3.4
  User alice
  Port 2222
  IdentityFile ~/.ssh/id_ed25519
  ForwardAgent yes
```
- Use with `ssh myserver`

## Troubleshoot
- `ssh -vvv user@host` — max verbosity
- `ssh-keyscan host` — fetch host key
- Permissions: `chmod 700 ~/.ssh`, `chmod 600 ~/.ssh/id_*`

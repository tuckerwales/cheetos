# curl

## Basics
- `curl <url>` — GET, print body
- `curl -O <url>` — save as remote filename
- `curl -o file <url>` — save as `file`
- `curl -L <url>` — follow redirects
- `curl -I <url>` — HEAD only (headers)
- `curl -v <url>` — verbose
- `curl -s <url>` — silent (no progress)
- `curl -sS <url>` — silent but show errors

## Methods & Data
- `curl -X POST <url>` — explicit method
- `curl -d 'a=1&b=2' <url>` — form POST
- `curl -d @file.json <url>` — body from file
- `curl --data-urlencode 'q=hello world' <url>` — URL-encode
- `curl -F 'file=@photo.png' <url>` — multipart upload
- `curl -G -d 'q=foo' <url>` — GET with query params

## Headers & Auth
- `curl -H 'Content-Type: application/json' <url>` — header
- `curl -H 'Authorization: Bearer <token>' <url>` — bearer
- `curl -u user:pass <url>` — basic auth
- `curl --cookie 'k=v' <url>` — send cookie
- `curl -c jar.txt -b jar.txt <url>` — save + send cookies

## JSON
- `curl -H 'Content-Type: application/json' -d '{"x":1}' <url>` — POST JSON
- `curl -s <url> | jq` — pretty JSON
- `curl -s <url> | jq '.field'` — extract field

## TLS & Debug
- `curl -k <url>` — skip cert verification
- `curl --cacert ca.pem <url>` — custom CA
- `curl -w '%{http_code}\n' -o /dev/null -s <url>` — just status
- `curl -w '@format.txt' <url>` — custom timing output
- `curl --resolve host:443:1.2.3.4 https://host/` — override DNS

## Misc
- `curl --limit-rate 100k <url>` — throttle
- `curl --max-time 10 <url>` — total timeout
- `curl -C - -O <url>` — resume download
- `curl -x http://proxy:8080 <url>` — via proxy

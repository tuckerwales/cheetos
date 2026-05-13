# Kubectl

## Context & Config
- `kubectl config get-contexts` — list contexts
- `kubectl config use-context <name>` — switch context
- `kubectl config current-context` — show current
- `kubectl config set-context --current --namespace=<ns>` — set default ns

## Get / Describe
- `kubectl get pods` — list pods
- `kubectl get pods -A` — all namespaces
- `kubectl get pods -o wide` — extra columns
- `kubectl get pods -w` — watch
- `kubectl get all` — pods, services, deployments
- `kubectl describe pod <name>` — detailed info
- `kubectl explain <resource>` — schema docs

## Logs & Exec
- `kubectl logs <pod>` — pod logs
- `kubectl logs -f <pod>` — follow logs
- `kubectl logs <pod> -c <container>` — multi-container
- `kubectl logs --previous <pod>` — last crashed instance
- `kubectl exec -it <pod> -- sh` — shell into pod
- `kubectl exec <pod> -- <cmd>` — one-off command

## Apply / Delete
- `kubectl apply -f <file>` — apply manifest
- `kubectl apply -f <dir>/` — apply directory
- `kubectl delete -f <file>` — delete from manifest
- `kubectl delete pod <name>` — delete pod
- `kubectl edit <resource> <name>` — edit live

## Rollouts
- `kubectl rollout status deploy/<name>` — watch rollout
- `kubectl rollout history deploy/<name>` — history
- `kubectl rollout undo deploy/<name>` — rollback
- `kubectl rollout restart deploy/<name>` — restart

## Port Forward & Copy
- `kubectl port-forward <pod> 8080:80` — forward port
- `kubectl port-forward svc/<name> 8080:80` — forward service
- `kubectl cp <pod>:/path ./local` — copy from pod
- `kubectl cp ./local <pod>:/path` — copy to pod

## Scale & Debug
- `kubectl scale deploy/<name> --replicas=3` — scale
- `kubectl top pod` — resource usage
- `kubectl top node` — node usage
- `kubectl get events --sort-by=.lastTimestamp` — events

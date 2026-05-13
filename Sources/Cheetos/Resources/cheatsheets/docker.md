# Docker

## Images
- `docker images` — list images
- `docker pull <image>` — fetch image
- `docker build -t <name> .` — build from Dockerfile
- `docker rmi <image>` — remove image
- `docker image prune` — remove dangling images
- `docker tag <src> <dst>` — tag image

## Containers
- `docker ps` — running containers
- `docker ps -a` — all containers
- `docker run <image>` — run container
- `docker run -it <image> sh` — interactive shell
- `docker run -d -p 8080:80 <image>` — detached + port map
- `docker run --rm <image>` — auto-remove on exit
- `docker stop <id>` — stop container
- `docker rm <id>` — remove container
- `docker container prune` — remove stopped containers

## Inspect
- `docker logs <id>` — show logs
- `docker logs -f <id>` — follow logs
- `docker exec -it <id> sh` — shell into running container
- `docker inspect <id>` — full metadata
- `docker stats` — live resource usage
- `docker top <id>` — processes in container

## Volumes & Networks
- `docker volume ls` — list volumes
- `docker volume create <name>` — create volume
- `docker volume rm <name>` — remove volume
- `docker network ls` — list networks
- `docker network create <name>` — create network

## Compose
- `docker compose up` — start services
- `docker compose up -d` — start detached
- `docker compose down` — stop + remove
- `docker compose logs -f` — follow logs
- `docker compose ps` — list services
- `docker compose build` — build images
- `docker compose exec <svc> sh` — shell into service

## Cleanup
- `docker system df` — disk usage
- `docker system prune` — remove unused data
- `docker system prune -a --volumes` — aggressive cleanup

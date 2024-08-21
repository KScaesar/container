## docker compose up

```bash
# prefect server
docker compose -p prefect --profile server -f "./deploy/docker-compose.yml" --env-file "./template-.env" up -d

# bcs cronjob
docker compose -p prefect --profile cron -f "./deploy/docker-compose.yml" up -d
```
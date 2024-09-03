
## poetry usage

[Poetry + pyenv 實戰心得：常用指令與注意事項](https://kyomind.medium.com/poetry-pyenv-practical-tips-3d167fd26e5a)

### manage dependency

```bash
# install poetry
pipx install poetry
poetry self add poetry-plugin-export

# install dependency
poetry install
or
pip install -r requirements.txt

# export dependency
awk '/^pywin32/ {print "# " $0; next} {print}' "poetry.lock" > tmpfile && mv tmpfile "poetry.lock"
poetry export --without-hashes | awk '{ print $1 }' FS=';' > requirements.txt
```

[pywin32 issue](https://stackoverflow.com/questions/77124656/architecture-dependent-requirements-with-poetry)

## setup service

### container

```bash
# prefect
docker compose -p project --profile prefect -f "./deploy/docker-compose.yml" up -d

# app
docker compose -p project --profile app -f "./deploy/docker-compose.yml" up -d --build

# close service
docker compose -p project --profile app -f "./deploy/docker-compose.yml" down
or
docker compose -p project --profile prefect --profile app -f "./deploy/docker-compose.yml" down
```

### local

```bash
# prefect
docker compose -p project --profile prefect -f "./deploy/docker-compose.yml" up -d

# app
PREFECT_API_URL=http://127.0.0.1:4200/api python example.py
```

## deployment

先使用 prefect ui 或 cli 暫停 app 運作.  
`docker exec prefect-server prefect deployment pause-schedule <FLOW_NAME>/<DEPLOYMENT_NAME>`

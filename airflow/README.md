## 啟動 Airflow

https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html#fetching-docker-compose-yaml

```bash
cp example-.env .env
echo -e "AIRFLOW_UID=$(id -u)" > .env

docker-compose up airflow-init

# 啟動所有服務（Scheduler, Worker, Webserver 等）
docker-compose --profile flower up -d

# Stop Airflow
docker compose down
```

## Endpoint

### 外部存取端點 (Host 存取)

- **Airflow Web UI**: <http://localhost:8080>
- **Flower (Celery 監控)**: <http://localhost:5555>
- **PostgreSQL**: <http://localhost:5433>

### 內部通訊端點 (容器間互相存取)

- **Metadata DB**: `postgres:5432`
- **Redis (Broker)**: `redis:6379`
- **Airflow API Server**: `airflow-apiserver:8080`
- **Internal Execution API**: `http://airflow-apiserver:8080/execution/`

## airflow cli

> [!NOTE]
> Airflow 3.x 的 `airflow` CLI 設計為在容器內部執行（直連 PostgreSQL），
> 不支援從 host 透過環境變數遠端呼叫。請使用 `docker exec` 執行 CLI 指令。

```bash
# 列出所有 DAGs
docker exec airflow-airflow-apiserver-1 airflow dags list
```

### REST API（需要 JWT Token）

```bash
export AIRFLOW_API_SERVER_URL="http://localhost:8080"
airflow_login() {
  export AIRFLOW_API_TOKEN=$(curl -s -X POST "$AIRFLOW_API_SERVER_URL/auth/token" \
    -H "Content-Type: application/json" \
    -d '{"username":"airflow","password":"airflow","grant_type":"password"}' \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['access_token'])")
  echo "✅ Airflow token 已設定"
}

# 查詢 DAGs
curl -s -H "Authorization: Bearer $AIRFLOW_API_TOKEN" $AIRFLOW_API_SERVER_URL/api/v2/dags | jq
```

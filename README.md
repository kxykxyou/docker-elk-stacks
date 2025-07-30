# ELK Stack + OpenTelemetry Collector

自動化部署 ELK Stack 和 OpenTelemetry Collector。

## 快速開始

**系統需求**: Docker Engine 18.06.0+, Docker Compose 2.0.0+, 4GB+ RAM

**docker-elk官方參考文檔**: [docker-elk-src/README.md](./docker-elk-src/README.md)

### 環境變數設定

```bash
# 1. 設定 ELK Stack 環境變數
cp docker-elk-src/.env.example docker-elk-src/.env
# 編輯 docker-elk-src/.env，修改密碼或Elastic版本

# 2. 設定 OpenTelemetry Collector 版本（可選）
cp opentelemetry-collector/.env.example opentelemetry-collector/.env
# 編輯 opentelemetry-collector/.env 當中的版本
```

### 啟動 docker containers
```bash
# 啟動
# 順序啟動: 檢查.env → 檢核 ElasticSearch 或 OTEL Collector 版本 → ElasticSearch 初始化 → ELK Stask: Fleet + APM + LogStash up → OTEL Collector up
./start-elk-otel.sh


# 停止
# OTEL Collector down -> ELK Stacks down
./stop-elk-otel.sh
```



## 服務端點

| 服務 | URL |
|------|-----|
| Kibana | http://localhost:5601 |
| Elasticsearch | http://localhost:9200 |
| Fleet | http://localhost:8220 |
| LogStash | http://localhost:5044 |
| APM Server | http://localhost:8200 |
| OpenTelemetry GRPC | http://localhost:4317 |
| OpenTelemetry HTTP | http://localhost:4318 |

**登入**: 開啟Kibana，使用 .env 當中寫入的密碼

## 疑難排解
- **Elastic License試用過期**: `docker volume ls` 找出 elasticsearch對應的volume，刪除後重新啟動。
- **端口衝突**: 確保 9200, 5601, 8200, 8220, 5044, 4317, 4318 未被佔用  
- **記憶體不足**: 建議 4GB+ RAM，調整 Docker Desktop 記憶體限制

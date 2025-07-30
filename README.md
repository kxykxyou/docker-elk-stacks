# ELK Stack + OpenTelemetry Collector

自動化部署 ELK Stack 和 OpenTelemetry Collector。

## 快速開始

**系統需求**: Docker Engine 18.06.0+, Docker Compose 2.0.0+, 4GB+ RAM

**參考文檔**: [docker-elk-src/README.md](./docker-elk-src/README.md)

```bash
# 啟動
./start-elk-otel.sh

# 停止
./stop-elk-otel.sh
```

## 配置

**必須修改預設密碼 `changeme`**

```bash
# 1. 設定 ELK Stack 環境變數
cp docker-elk-src/.env.example docker-elk-src/.env
# 編輯 docker-elk-src/.env，修改密碼或Elastic版本

# 2. 設定 OpenTelemetry Collector 版本（可選）
cp opentelemetry-collector/.env.example opentelemetry-collector/.env
# 編輯 opentelemetry-collector/.env 當中的版本
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

## 腳本功能

- 版本驗證 (自動使用 `latest`)
- 順序啟動: .env → 版本驗證 → ES 初始化 → ELK Stack + Fleet + APM → OpenTelemetry

**檢查服務狀態**:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(elastic|kibana|logstash|fleet|apm|otel)"
curl http://localhost:9200/_cluster/health?pretty
```

## 疑難排解
- **Elastic License試用過期**: `docker volume ls` 找出 elasticsearch對應的volume，刪除後重新啟動。
- **端口衝突**: 確保 9200, 5601, 8200, 8220, 5044, 4317, 4318 未被佔用  
- **記憶體不足**: 建議 4GB+ RAM，調整 Docker Desktop 記憶體限制

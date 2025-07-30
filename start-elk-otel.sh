#!/bin/bash

set -e

# 獲取腳本所在目錄
PROJECT_ROOT="$(dirname "$(realpath "$0")")"

# 版本驗證函數
validate_version() {
    local version="$1"
    local service_name="$2"
    
    # 檢查是否為 latest
    if [ "$version" = "latest" ]; then
        echo "✅ $service_name 版本: $version (合法)"
        return 0
    fi
    
    # 檢查是否符合 x.y.z 或 x.y.z-suffix 格式
    if echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'; then
        echo "✅ $service_name 版本: $version (合法)"
        return 0
    else
        echo "⚠️  $service_name 版本 '$version' 不合法，使用 latest"
        return 1
    fi
}

echo "🚀 啟動 ELK Stack 和 OpenTelemetry Collector..."

# 步驟 1: 檢查並載入 docker-elk .env 文件
echo "📁 檢查 docker-elk .env 文件..."
cd "${PROJECT_ROOT}/docker-elk-src"

if [ ! -f ".env" ]; then
    echo "❌ .env 文件不存在，請先創建 .env 文件; cp .env.example .env"
    exit 1
fi

echo "✅ .env 文件存在，載入環境變數..."

# 載入環境變數
set -a
source .env
set +a

# 驗證 ELASTIC_VERSION
if [ -n "$ELASTIC_VERSION" ]; then
    if ! validate_version "$ELASTIC_VERSION" "Elasticsearch"; then
        export ELASTIC_VERSION="latest"
    fi
else
    echo "⚠️  ELASTIC_VERSION 未設定，使用 latest"
    export ELASTIC_VERSION="latest"
fi

# 步驟 2: 啟動 ELK Stack
echo "🔧 執行 docker compose setup..."
docker compose up setup

echo "🚀 啟動 ELK Stack..."
docker compose \
  -f docker-compose.yml \
  -f extensions/fleet/fleet-compose.yml \
  -f extensions/fleet/agent-apmserver-compose.yml \
  up -d

# 步驟 3: 啟動 OpenTelemetry Collector
echo "🔌 設定 OpenTelemetry Collector..."
cd "${PROJECT_ROOT}/opentelemetry-collector"

# 讀取並驗證版本設定
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
    echo "✅ 已載入 OpenTelemetry Collector 環境變數"
    
    # 驗證 OTEL_COLLECTOR_VERSION
    if [ -n "$OTEL_COLLECTOR_VERSION" ]; then
        if ! validate_version "$OTEL_COLLECTOR_VERSION" "OpenTelemetry Collector"; then
            export OTEL_COLLECTOR_VERSION="latest"
        fi
    else
        echo "⚠️  OTEL_COLLECTOR_VERSION 未設定，使用 latest"
        export OTEL_COLLECTOR_VERSION="latest"
    fi
else
    echo "⚠️  .env 文件不存在，使用 latest 版本"
    OTEL_COLLECTOR_VERSION="latest"
fi

# 設定 APM_HOST 環境變數
export APM_HOST="apm-server"

echo "🚀 啟動 OpenTelemetry Collector (版本: ${OTEL_COLLECTOR_VERSION})..."
docker run --rm -d \
  -p 4317:4317 \
  -p 4318:4318 \
  --network=docker-elk-src_elk \
  -v "${PWD}/config.yaml:/etc/otel-collector-config.yaml" \
  -e APM_HOST="${APM_HOST}" \
  otel/opentelemetry-collector:${OTEL_COLLECTOR_VERSION} \
  --config=/etc/otel-collector-config.yaml

echo "✅ 完成！服務已啟動"
echo "📊 Kibana: http://localhost:5601"
echo "🔍 Elasticsearch: http://localhost:9200"
echo "📈 APM Server: http://localhost:8200" 
echo "📈 OTEL Collector GRPC Server: http://localhost:4317" 
echo "📈 OTEL Collector HTTP Server: http://localhost:4318" 
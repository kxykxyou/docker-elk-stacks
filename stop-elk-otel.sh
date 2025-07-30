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
        return 0
    fi
    
    # 檢查是否符合 x.y.z 或 x.y.z-suffix 格式
    if echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'; then
        return 0
    else
        return 1
    fi
}

echo "🛑 停止 ELK Stack 和 OpenTelemetry Collector..."

# 停止 OpenTelemetry Collector
echo "🔌 停止 OpenTelemetry Collector..."

# 讀取並驗證版本設定
cd "${PROJECT_ROOT}/opentelemetry-collector"
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
    
    # 驗證 OTEL_COLLECTOR_VERSION
    if [ -n "$OTEL_COLLECTOR_VERSION" ]; then
        if ! validate_version "$OTEL_COLLECTOR_VERSION" "OpenTelemetry Collector"; then
            export OTEL_COLLECTOR_VERSION="latest"
        fi
    else
        export OTEL_COLLECTOR_VERSION="latest"
    fi
else
    OTEL_COLLECTOR_VERSION="latest"
fi

docker stop $(docker ps -q --filter "ancestor=otel/opentelemetry-collector:${OTEL_COLLECTOR_VERSION}") 2>/dev/null || echo "OpenTelemetry Collector 未運行"

# 停止 ELK Stack
echo "🛑 停止 ELK Stack..."
cd "${PROJECT_ROOT}/docker-elk-src"

docker compose \
  -f docker-compose.yml \
  -f extensions/fleet/fleet-compose.yml \
  -f extensions/fleet/agent-apmserver-compose.yml \
  down

echo "✅ 所有服務已停止" 
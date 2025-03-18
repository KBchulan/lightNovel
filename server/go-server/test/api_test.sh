#!/bin/bash

# 设置基础URL
BASE_URL="http://localhost:8080/api/v1"
DEVICE_ID="test-device-001"
DEVICE_ID_2="test-device-002"
NOVEL_ID="67d8130d6670f3409cdecdb8"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 测试函数
test_endpoint() {
    echo -e "\n${GREEN}Testing: $1${NC}"
    echo "Command: $2"
    eval $2
    echo -e "\n"
}

# WebSocket测试函数
test_websocket() {
    echo -e "\n${GREEN}Testing WebSocket: $1${NC}"
    echo "Command: $2"
    timeout 5 $2
    echo -e "\n"
}

echo "=== 开始API测试 ==="

# 1. 系统监控接口测试
# test_endpoint "健康检查" "curl -i $BASE_URL/health"
# test_endpoint "性能指标" "curl -i $BASE_URL/metrics"

# 2. 小说相关接口测试
## 2.1 基本功能测试
# test_endpoint "获取小说列表" "curl -i \"$BASE_URL/novels?page=1&size=10\""
# test_endpoint "搜索小说" "curl -i \"$BASE_URL/novels/search?keyword=百合&page=1&size=10\""
# test_endpoint "最新小说" "curl -i \"$BASE_URL/novels/latest?limit=10\""
# test_endpoint "热门小说" "curl -i \"$BASE_URL/novels/popular?limit=10\""
# test_endpoint "小说详情" "curl -i $BASE_URL/novels/$NOVEL_ID"
# test_endpoint "卷列表" "curl -i $BASE_URL/novels/$NOVEL_ID/volumes"
# test_endpoint "章节列表" "curl -i $BASE_URL/novels/$NOVEL_ID/volumes/1/chapters"
# test_endpoint "章节内容" "curl -i $BASE_URL/novels/$NOVEL_ID/volumes/1/chapters/1"
# 
## 2.2 边界值测试
# test_endpoint "小说列表-最大分页" "curl -i \"$BASE_URL/novels?page=1&size=50\""
# test_endpoint "小说列表-最小分页" "curl -i \"$BASE_URL/novels?page=1&size=1\""
# test_endpoint "搜索-最大结果" "curl -i \"$BASE_URL/novels/search?keyword=test&page=1&size=50\""
# test_endpoint "最新小说-最大数量" "curl -i \"$BASE_URL/novels/latest?limit=50\""
# test_endpoint "热门小说-最大数量" "curl -i \"$BASE_URL/novels/popular?limit=50\""

# 3. 用户相关接口测试
test_endpoint "获取书签" "curl -i -H \"X-Device-ID: $DEVICE_ID\" $BASE_URL/user/bookmarks"
test_endpoint "获取阅读历史" "curl -i -H \"X-Device-ID: $DEVICE_ID\" $BASE_URL/user/history"
test_endpoint "更新阅读进度" "curl -i -X PATCH -H \"X-Device-ID: $DEVICE_ID\" -H \"Content-Type: application/json\" -d '{\"novelId\":\"$NOVEL_ID\",\"volumeNumber\":1,\"chapterNumber\":1,\"position\":100}' $BASE_URL/user/progress"

# 4. WebSocket测试
# if command -v websocat &> /dev/null; then
#     test_websocket "WebSocket连接测试" "websocat ws://localhost:8080/api/v1/ws"
#     test_websocket "带设备ID的WebSocket连接" "websocat ws://localhost:8080/api/v1/ws -H \"X-Device-ID: $DEVICE_ID\""
# else
#     echo -e "${RED}websocat 未安装，跳过 WebSocket 测试${NC}"
#     echo "可以通过以下命令安装 websocat："
#     echo "cargo install websocat"
#     echo "或访问: https://github.com/vi/websocat/releases"
# fi

echo "=== API测试完成 ==="


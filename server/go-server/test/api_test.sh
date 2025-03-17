#!/bin/bash

# 设置基础URL
BASE_URL="http://localhost:8080/api/v1"
DEVICE_ID="test-device-001"
NOVEL_ID="65c0b2d55c44c6d2a8d8b123"

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

echo "=== 开始API测试 ==="

# 1. 系统监控接口测试
test_endpoint "健康检查" "curl -i $BASE_URL/health"
test_endpoint "性能指标" "curl -i $BASE_URL/metrics"

# 2. 小说相关接口测试
test_endpoint "获取小说列表" "curl -i \"$BASE_URL/novels?page=1&size=10\""
test_endpoint "搜索小说" "curl -i \"$BASE_URL/novels/search?keyword=%E4%BA%94%E5%8D%83&page=1&size=10\""
test_endpoint "最新小说" "curl -i \"$BASE_URL/novels/latest?limit=10\""
test_endpoint "热门小说" "curl -i \"$BASE_URL/novels/popular?limit=10\""
test_endpoint "小说详情" "curl -i $BASE_URL/novels/$NOVEL_ID"
test_endpoint "卷列表" "curl -i $BASE_URL/novels/$NOVEL_ID/volumes"
test_endpoint "章节列表" "curl -i $BASE_URL/novels/$NOVEL_ID/volumes/1/chapters"
test_endpoint "章节内容" "curl -i $BASE_URL/novels/$NOVEL_ID/volumes/1/chapters/1"

# 3. 用户相关接口测试
test_endpoint "获取书签" "curl -i -H \"X-Device-ID: $DEVICE_ID\" $BASE_URL/user/bookmarks"
test_endpoint "更新阅读进度" "curl -i -X PATCH -H \"X-Device-ID: $DEVICE_ID\" -H \"Content-Type: application/json\" -d '{\"novelId\":\"$NOVEL_ID\",\"volumeId\":1,\"chapterId\":1,\"position\":100}' $BASE_URL/user/progress"

echo "=== API测试完成 ==="

echo "=== 开始压力测试 ==="

# 确保已安装wrk
if ! command -v wrk &> /dev/null; then
    echo "正在安装wrk..."
    sudo apt-get install -y wrk
fi

# 压力测试函数
stress_test() {
    echo -e "\n${GREEN}压力测试: $1${NC}"
    echo "Command: $2"
    eval $2
    echo -e "\n"
}

# 1. 小说列表接口压测（高并发）
stress_test "小说列表接口" "wrk -t32 -c1000 -d60s \"$BASE_URL/novels?page=1&size=10\""

# 2. 搜索接口压测（高并发）
stress_test "搜索接口" "wrk -t32 -c1000 -d60s \"$BASE_URL/novels/search?keyword=%E4%BA%94%E5%8D%83\""

# 3. 阅读进度更新接口压测（高并发）
stress_test "阅读进度更新" "wrk -t32 -c1000 -d60s -s <(echo 'wrk.method = \"PATCH\"; wrk.body = \"{\\\"novelId\\\":\\\"$NOVEL_ID\\\",\\\"volumeId\\\":1,\\\"chapterId\\\":1,\\\"position\\\":100}\"; wrk.headers[\"Content-Type\"] = \"application/json\"; wrk.headers[\"X-Device-ID\"] = \"$DEVICE_ID\"') $BASE_URL/user/progress"

# 4. 极限测试（超高并发）
echo -e "\n${GREEN}开始极限测试 - 2000并发连接${NC}"
stress_test "极限并发测试" "wrk -t32 -c2000 -d120s \"$BASE_URL/novels?page=1&size=10\""

echo "=== 压力测试完成 ===" 
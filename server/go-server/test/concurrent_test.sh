#!/bin/bash

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

# 1. 基本接口压测
## 1.1 小说列表接口压测（高并发）
stress_test "小说列表接口" "wrk -t32 -c1000 -d60s \"$BASE_URL/novels?page=1&size=10\""

## 1.2 搜索接口压测（高并发）
stress_test "搜索接口" "wrk -t32 -c1000 -d60s \"$BASE_URL/novels/search?keyword=%E4%BA%94%E5%8D%83\""

## 1.3 阅读进度更新接口压测（高并发）
stress_test "阅读进度更新" "wrk -t32 -c1000 -d60s -s <(echo 'wrk.method = \"PATCH\"; wrk.body = \"{\\\"novelId\\\":\\\"$NOVEL_ID\\\",\\\"volumeId\\\":1,\\\"chapterId\\\":1,\\\"position\\\":100}\"; wrk.headers[\"Content-Type\"] = \"application/json\"; wrk.headers[\"X-Device-ID\"] = \"$DEVICE_ID\"') $BASE_URL/user/progress"

# 2. 边界值压测
## 2.1 最大分页压测
stress_test "最大分页测试" "wrk -t32 -c1000 -d30s \"$BASE_URL/novels?page=1&size=50\""

## 2.2 最小分页压测
stress_test "最小分页测试" "wrk -t32 -c1000 -d30s \"$BASE_URL/novels?page=1&size=1\""

## 2.3 最大搜索结果压测
stress_test "最大搜索结果" "wrk -t32 -c1000 -d30s \"$BASE_URL/novels/search?keyword=%E4%BA%94%E5%8D%83&size=50\""

# 3. 设备相关压测
## 3.1 多设备并发测试
stress_test "多设备-阅读历史" "wrk -t32 -c1000 -d30s -H \"X-Device-ID: test-device-001\" \"$BASE_URL/user/history\""
stress_test "多设备-书签" "wrk -t32 -c1000 -d30s -H \"X-Device-ID: test-device-002\" \"$BASE_URL/user/bookmarks\""

## 3.2 不同设备类型测试
stress_test "移动端设备" "wrk -t32 -c1000 -d30s -H \"X-Device-ID: mobile-001\" -H \"User-Agent: Mozilla/5.0 (iPhone)\" \"$BASE_URL/user/history\""
stress_test "PC端设备" "wrk -t32 -c1000 -d30s -H \"X-Device-ID: pc-001\" -H \"User-Agent: Mozilla/5.0 (Windows NT 10.0)\" \"$BASE_URL/user/history\""

# 4. WebSocket压测
if command -v wrk2 &> /dev/null; then
    stress_test "WebSocket连接" "wrk2 -t32 -c1000 -d30s -R2000 ws://localhost:8080/ws"
else
    echo -e "${RED}wrk2 未安装，跳过 WebSocket 压测${NC}"
    echo "可以通过以下命令安装 wrk2："
    echo "git clone https://github.com/giltene/wrk2.git"
    echo "cd wrk2 && make"
fi

# 5. 极限测试（超高并发）
echo -e "\n${GREEN}开始极限测试 - 2000并发连接${NC}"
stress_test "极限并发测试-小说列表" "wrk -t32 -c2000 -d120s \"$BASE_URL/novels?page=1&size=10\""
stress_test "极限并发测试-搜索" "wrk -t32 -c2000 -d120s \"$BASE_URL/novels/search?keyword=%E4%BA%94%E5%8D%83\""
stress_test "极限并发测试-阅读历史" "wrk -t32 -c2000 -d120s -H \"X-Device-ID: test-device-001\" \"$BASE_URL/user/history\""

# 6. 性能指标验证
check_performance() {
    local result=$1
    local min_qps=1000
    local max_latency=100

    if echo "$result" | grep -q "Requests/sec.*>.*$min_qps" && \
       echo "$result" | grep -q "Latency.*<.*$max_latency"; then
        echo -e "${GREEN}性能测试通过${NC}"
    else
        echo -e "${RED}性能测试未达标${NC}"
    fi
}

echo "=== 压力测试完成 ===" 
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
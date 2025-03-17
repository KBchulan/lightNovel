#!/bin/bash

# 设置基础URL
BASE_URL="http://localhost:8080/api/v1"

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

# 健康检查接口
test_endpoint "Health Check" "curl -i $BASE_URL/health"

# 指标接口
test_endpoint "Metrics" "curl -i $BASE_URL/metrics"

# 小说相关接口
test_endpoint "Get All Novels" "curl -i $BASE_URL/novels"
test_endpoint "Search Novels" "curl -i \"$BASE_URL/novels/search?keyword=败北\""
test_endpoint "Get Latest Novels" "curl -i \"$BASE_URL/novels/latest?limit=5\""
test_endpoint "Get Popular Novels" "curl -i \"$BASE_URL/novels/popular?limit=5\""

# 获取特定小说信息（需要替换为实际的小说ID）
NOVEL_ID="67d81304fd91902fcc3aee4a"
test_endpoint "Get Novel by ID" "curl -i $BASE_URL/novels/$NOVEL_ID"
test_endpoint "Get Volumes" "curl -i $BASE_URL/novels/$NOVEL_ID/volumes"
test_endpoint "Get Chapters" "curl -i $BASE_URL/novels/$NOVEL_ID/volumes/1/chapters"
test_endpoint "Get Chapter Content" "curl -i $BASE_URL/novels/$NOVEL_ID/volumes/1/chapters/1"

# 用户相关接口（需要JWT token）
TOKEN="your_jwt_token_here"
test_endpoint "Get User Bookmarks" "curl -i -H \"Authorization: Bearer $TOKEN\" $BASE_URL/user/bookmarks"
test_endpoint "Update Reading Progress" "curl -i -X PATCH -H \"Authorization: Bearer $TOKEN\" -H \"Content-Type: application/json\" -d '{\"novelId\":\"$NOVEL_ID\",\"volumeId\":1,\"chapterId\":1,\"position\":0}' $BASE_URL/user/progress" 
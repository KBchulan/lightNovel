# 轻小说服务器

基于Go语言开发的高性能轻小说API服务器，支持小说内容管理和阅读进度同步。

## 技术栈

- Go 1.23+
- Gin Web Framework
- MongoDB
- Redis
- Rate Limiter

## 核心功能

1. 小说管理

   - 小说列表、搜索、详情
   - 最新小说、热门小说
   - 卷章节内容管理
2. 用户功能

   - 基于设备ID的书签管理
   - 阅读进度同步
3. 系统功能

   - Redis缓存加速
   - 请求频率限制
   - 系统监控指标

## 性能指标

在标准测试环境下（4核8G）：

- QPS: 36k-52k
- 平均响应时间: 11-25ms
- 并发连接数: 400+
- 数据吞吐量: 22-32MB/s

## 环境要求

- Go 1.23+
- MongoDB 4.0+
- Redis 6.0+
- 内存: 1GB+
- 系统: Linux (推荐)

## 配置说明

配置文件: `config/config.yaml`

```yaml
server:
  port: "8080"
  mode: "release"

database:
  uri: "mongodb://localhost:27017"
  database: "lightnovel"

redis:
  host: "localhost"
  port: "6379"
  db: 0

rate_limit:
  requests: 100
  duration: "1m"

cache:
  ttl: "15m"
```

## 项目结构

```
go-server/
├── api/            # API 处理器
│   └── v1/         # API v1 版本
├── config/         # 配置文件
├── internal/       # 内部包
│   ├── models/     # 数据模型
│   └── service/    # 业务逻辑
├── pkg/            # 公共包
│   ├── database/   # 数据库相关
│   └── middleware/ # 中间件
└── test/           # 测试文件
    └── api_test.sh # API测试脚本
```

## API测试

项目提供了完整的API测试脚本，位于 `test/api_test.sh`。使用方法：

```bash
# 添加执行权限
chmod +x test/api_test.sh

# 运行测试脚本
./test/api_test.sh
```

## 日志格式

服务器日志格式如下：

```
[GIN] 2025/03/17 - 15:04:05 | 200 |      8.254ms |      172.0.0.1 | GET    /api/v1/health
```

日志字段说明：

- 时间戳
- 状态码
- 响应时间
- 客户端IP
- 请求方法
- 请求路径

## API文档

### 小说相关

```
GET /api/v1/novels              # 获取小说列表
GET /api/v1/novels/search       # 搜索小说
GET /api/v1/novels/latest       # 最新更新
GET /api/v1/novels/popular      # 热门小说
GET /api/v1/novels/:id          # 获取小说详情
GET /api/v1/novels/:id/volumes  # 获取卷列表
```

### 用户相关

```
GET /api/v1/user/bookmarks     # 获取书签
PATCH /api/v1/user/progress    # 更新阅读进度
```

### 系统监控

```
GET /api/v1/health            # 健康检查
GET /api/v1/metrics           # 性能指标
```

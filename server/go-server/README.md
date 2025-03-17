# 轻小说服务器

这是一个基于Go语言开发的轻小说阅读API服务器，提供小说内容管理和用户阅读进度同步等功能。

## 技术栈

- Go 1.23+
- Gin Web Framework
- MongoDB
- Redis
- Rate Limiter

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

## 核心模块说明

### 数据库 (MongoDB)
- 作用：存储小说内容、用户信息和阅读进度
- 集合：
  - novels: 小说基本信息
  - volumes: 小说卷信息
  - chapters: 章节内容
  - users: 用户信息
  - bookmarks: 用户书签
  - reading_progress: 阅读进度

### 缓存 (Redis)
- 作用：缓存热门接口响应，减轻数据库压力
- 缓存内容：
  - 小说列表
  - 章节内容
  - 热门小说
  - 最新更新

### 中间件 (pkg/middleware)
- ErrorHandler: 统一错误处理
- SecurityHeaders: 安全响应头
- CORS: 跨域支持
- RateLimiter: 请求频率限制
- Cache: Redis缓存

### API模块 (api/v1)
- NovelHandler: 小说相关接口
  - 获取小说列表
  - 搜索小说
  - 获取章节内容
  - 最新更新
  - 热门小说
- UserHandler: 用户相关接口
  - 书签管理
  - 阅读进度同步
- HealthHandler: 系统监控
  - 健康检查
  - 性能指标

### 配置模块 (config)
- 作用：管理服务器配置
- 配置项：
  - 服务器端口
  - 数据库连接
  - Redis设置
  - 限流参数

### 监控模块 (api/v1/health)
- 作用：系统状态监控
- 指标：
  - 内存使用
  - Goroutine数量
  - 运行时间
  - GC统计

## 功能特性

1. 小说管理
   - 获取小说列表
   - 搜索小说
   - 获取最新小说
   - 获取热门小说
   - 获取小说详情
   - 获取卷列表
   - 获取章节列表
   - 获取章节内容

2. 用户功能
   - 书签管理
   - 阅读进度同步

3. 系统功能
   - 健康检查
   - 系统指标监控
   - 请求限流
   - Redis缓存
   - 日志记录

## 中间件

1. 错误处理中间件
   - 统一错误响应格式
   - 错误日志记录

2. 安全中间件
   - CORS支持
   - 安全响应头
   - XSS防护

3. 限流中间件
   - 基于令牌桶算法
   - 可配置限流规则

4. 缓存中间件
   - Redis缓存支持
   - 可配置缓存时间

5. 日志中间件
   - 请求日志记录
   - 响应时间统计
   - 状态码统计

## API测试

项目提供了完整的API测试脚本，位于 `test/api_test.sh`。使用方法：

```bash
# 添加执行权限
chmod +x test/api_test.sh

# 运行测试脚本
./test/api_test.sh
```

测试脚本包含了所有API接口的测试用例，包括：
- 健康检查接口
- 系统指标接口
- 小说相关接口
- 用户相关接口

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

## 环境要求

- Go 1.23+
- MongoDB 4.0+
- Redis 6.0+

## 配置说明

配置文件位于 `config/config.yaml`，主要配置项：

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
  password: ""
  db: 0

rate_limit:
  requests: 100
  duration: "1m"

cache:
  ttl: "15m"
```

## 运行

```bash
# 启动服务器
go run main.go

# 使用测试脚本测试API
./test/api_test.sh
```

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

## 安全特性

1. 请求频率限制
2. 安全响应头
3. CORS策略
4. 错误处理
5. 参数验证

## 部署要求

- Go 1.23+
- MongoDB 4.0+
- Redis 6.0+
- 至少1GB RAM
- 建议使用Linux系统 
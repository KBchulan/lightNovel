# 轻小说服务器

基于Go语言开发的高性能轻小说API服务器，支持小说内容管理、阅读进度同步和实时更新通知。

## 技术栈

- Go 1.23+
- Gin Web Framework
- MongoDB
- Redis
- WebSocket
- Swagger
- BigCache

## 核心功能

1. 小说管理

   - 小说列表、搜索、详情
   - 最新小说、热门小说
   - 卷章节内容管理
   - 图片资源管理
2. 用户功能

   - 基于设备ID的阅读进度同步
   - 阅读历史记录
   - 多设备支持
   - 书签管理（创建、更新、删除）
3. 实时通知

   - WebSocket实时推送
   - 小说更新通知
   - 系统公告
   - 心跳检测和自动重连
4. 系统功能

   - 多级缓存（本地+Redis）
   - 分布式限流
   - 设备识别与管理
   - 性能监控

## 性能指标

在标准测试环境下（4核8G）：

- QPS: 52k
- 平均响应时间: 25-42ms
- 并发连接数: 200+
- 数据吞吐量: 80MB/s
- WebSocket连接: 5k+

## 环境要求

- Go 1.23+
- MongoDB 4.0+
- Redis 6.0+
- 内存: 2GB+
- 系统: Linux (推荐)

## 配置说明

配置文件: `config/config.yaml`

```yaml
server:
  port: "8080"
  readTimeout: 10s
  writeTimeout: 10s

database:
  uri: "mongodb://localhost:27017"
  database: "lightnovel"
  poolSize: 300

redis:
  host: "localhost"
  port: "6379"
  password: "your_password"
  db: 0
  poolSize: 300

cache:
  novelList: 30m
  novelDetail: 1h
  volumeList: 40m
  chapterList: 40m
  chapterDetail: 2h
  searchResult: 20m
  latestNovels: 10m
  popularNovels: 1h

rate:
  limit: 1000
  burst: 2000
  window: 1s
```

## 项目结构

```
go-server/
├── api/v1/              # API处理器
│   ├── health.go        # 健康检查
│   ├── novel_handler.go # 小说相关API
│   └── websocket.go     # WebSocket处理
├── config/              # 配置文件
│   ├── config.go        # 配置加载器
│   └── config.yaml      # 配置文件
├── docs/                # API文档
│   └── swagger.json     # Swagger文档
├── internal/            # 内部包
│   ├── models/          # 数据模型
│   └── service/         # 业务逻辑
├── pkg/                 # 公共包
│   ├── cache/          # 缓存相关
│   ├── database/       # 数据库相关
│   ├── errors/         # 错误处理
│   ├── middleware/     # 中间件
│   ├── response/       # 响应处理
│   └── websocket/      # WebSocket相关
└── test/               # 测试文件
```

## 快速开始

1. 安装依赖

```bash
go mod download
```

2. 修改配置

```bash
cp config/config.example.yaml config/config.yaml
# 编辑 config.yaml 设置数据库等配置
```

3. 运行服务

```bash
go run main.go
```

4. 访问API文档

```
http://localhost:8080/swagger/index.html
```

## API文档

### 小说相关

```
GET /api/v1/novels              # 获取小说列表（支持分页）
GET /api/v1/novels/search       # 搜索小说（支持分页）
GET /api/v1/novels/latest       # 最新更新（支持限制数量）
GET /api/v1/novels/popular      # 热门小说（支持限制数量）
GET /api/v1/novels/:id          # 获取小说详情
GET /api/v1/novels/:id/volumes  # 获取卷列表
GET /api/v1/novels/:id/volumes/:volume/chapters      # 获取章节列表
GET /api/v1/novels/:id/volumes/:volume/chapters/:chapter # 获取章节内容
```

### 用户相关

#### 收藏管理

```
GET    /api/v1/user/favorites                # 获取收藏列表
POST   /api/v1/user/favorites/:novel_id      # 添加收藏
DELETE /api/v1/user/favorites/:novel_id      # 取消收藏
GET    /api/v1/user/favorites/:novel_id/check # 检查收藏状态
```

#### 书签管理

```
GET    /api/v1/user/bookmarks      # 获取书签列表
POST   /api/v1/user/bookmarks      # 创建书签
PUT    /api/v1/user/bookmarks/:id  # 更新书签
DELETE /api/v1/user/bookmarks/:id  # 删除书签
```

#### 阅读相关

```
GET    /api/v1/user/reading/history           # 获取阅读历史
PUT    /api/v1/user/reading/history/:novel_id # 添加或更新阅读历史
DELETE /api/v1/user/reading/history/:novel_id # 删除指定小说的阅读历史
DELETE /api/v1/user/reading/history          # 清空所有阅读历史
GET    /api/v1/user/reading/progress/:novel_id # 获取阅读进度
PUT    /api/v1/user/reading/progress/:novel_id # 更新阅读进度
```

### WebSocket

```
GET /api/v1/ws         # WebSocket连接
GET /api/v1/ws/status  # 获取连接状态
```

### 系统监控

```
GET /api/v1/health   # 健康检查
GET /api/v1/metrics  # 性能指标
```

## 设备识别机制

系统使用设备ID来识别不同的用户设备：

1. 主要识别方式：

   - 通过 `X-Device-ID` 请求头传递设备ID
   - 如果请求头不存在，则使用客户端IP作为备选标识
2. 设备信息记录：

   - 设备ID（唯一标识）
   - IP地址
   - User-Agent
   - 设备类型（PC/Mobile/Tablet）
   - 首次访问时间
   - 最后访问时间
3. 数据关联：

   - 阅读进度
   - 阅读历史
   - 书签管理
   - 收藏列表

## 缓存机制

1. 多级缓存：

   - 本地缓存（BigCache）用于热点数据
   - Redis缓存用于分布式数据共享
   - 自动过期清理机制
2. 缓存策略：

   - 小说列表: 15分钟
   - 小说详情: 30分钟
   - 卷列表: 20分钟
   - 章节列表: 20分钟
   - 章节内容: 1小时
   - 搜索结果: 10分钟
   - 最新小说: 5分钟
   - 热门小说: 30分钟
   - 收藏列表: 15分钟

## WebSocket服务

1. 消息类型：

   - 小说更新通知
   - 系统公告
2. 特性：

   - 心跳检测（60秒超时）
   - 自动重连机制
   - 消息队列缓冲
   - 并发控制

## 安全特性

1. 请求限制：

   - 基于Redis的分布式限流
   - 可配置的限流规则
   - IP级别的访问控制
2. 安全头：

   - CORS保护
   - XSS防护
   - 点击劫持防护
   - 内容类型嗅探防护

## 日志格式

服务器日志格式如下：

```
[GIN] 2024/03/17 - 15:04:05 | 200 | 8.254ms | 172.0.0.1 | GET /api/v1/health
```

字段说明：

- 时间戳
- 状态码
- 响应时间
- 客户端IP
- 请求方法
- 请求路径

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

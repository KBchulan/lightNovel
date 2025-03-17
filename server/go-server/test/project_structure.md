# API文档和项目结构

## API接口说明

### 1. 小说相关接口

#### 获取小说列表
- 路径: `GET /api/v1/novels`
- 参数: 
  - page: 页码（默认1）
  - size: 每页数量（默认10）
- 返回: 小说列表和分页信息

#### 搜索小说
- 路径: `GET /api/v1/novels/search`
- 参数:
  - keyword: 搜索关键词
  - page: 页码
  - size: 每页数量
- 返回: 匹配的小说列表

#### 获取最新小说
- 路径: `GET /api/v1/novels/latest`
- 参数: 
  - limit: 返回数量（默认10）
- 返回: 最新更新的小说列表

#### 获取热门小说
- 路径: `GET /api/v1/novels/popular`
- 参数:
  - limit: 返回数量（默认10）
- 返回: 热门小说列表

#### 获取小说详情
- 路径: `GET /api/v1/novels/:id`
- 参数: 无
- 返回: 小说详细信息

#### 获取卷列表
- 路径: `GET /api/v1/novels/:id/volumes`
- 参数: 无
- 返回: 小说的卷列表

#### 获取章节列表
- 路径: `GET /api/v1/novels/:id/volumes/:vid/chapters`
- 参数: 无
- 返回: 指定卷的章节列表

#### 获取章节内容
- 路径: `GET /api/v1/novels/:id/volumes/:vid/chapters/:cid`
- 参数: 无
- 返回: 章节详细内容

### 2. 用户相关接口

#### 获取书签
- 路径: `GET /api/v1/user/bookmarks`
- 头部: X-Device-ID
- 返回: 用户的书签列表

#### 更新阅读进度
- 路径: `PATCH /api/v1/user/progress`
- 头部: X-Device-ID
- 参数:
  ```json
  {
    "novelId": "string",
    "volumeId": number,
    "chapterId": number,
    "position": number
  }
  ```
- 返回: 更新状态

### 3. 系统监控接口

#### 健康检查
- 路径: `GET /api/v1/health`
- 返回: 服务器状态信息

#### 性能指标
- 路径: `GET /api/v1/metrics`
- 返回: 系统性能指标

## 项目文件结构

### 主要目录
```
go-server/
├── api/v1/              # API处理器
├── config/              # 配置文件
├── internal/            # 内部包
│   ├── models/         # 数据模型
│   └── service/        # 业务逻辑
├── pkg/                 # 公共包
│   ├── database/       # 数据库相关
│   └── middleware/     # 中间件
└── test/               # 测试文件
```

### 核心文件说明

#### 1. API层 (`api/v1/`)
- `novel_handler.go`: 小说相关API处理
- `user_handler.go`: 用户相关API处理
- `health_handler.go`: 系统监控API处理

#### 2. 服务层 (`internal/service/`)
- `novel_service.go`: 小说业务逻辑
- `user_service.go`: 用户业务逻辑
- `cache_service.go`: 缓存服务

#### 3. 数据层 (`internal/models/`)
- `novel.go`: 小说相关模型
- `user.go`: 用户相关模型
- `bookmark.go`: 书签模型
- `reading_progress.go`: 阅读进度模型

#### 4. 中间件 (`pkg/middleware/`)
- `rate_limiter.go`: 请求限流
- `cache.go`: Redis缓存
- `logger.go`: 日志记录
- `security.go`: 安全相关
- `error.go`: 错误处理

#### 5. 数据库 (`pkg/database/`)
- `mongodb.go`: MongoDB连接和操作
- `redis.go`: Redis连接和操作

#### 6. 配置 (`config/`)
- `config.yaml`: 配置文件
- `config.go`: 配置加载器

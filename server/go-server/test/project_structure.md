# API文档和项目结构

## API接口说明

### 1. 小说相关接口

#### 获取小说列表
- 路径: `GET /api/v1/novels`
- 参数: 
  - page: 页码（默认1）
  - size: 每页数量（默认10，最大50）
- 返回: 小说列表和分页信息

#### 搜索小说
- 路径: `GET /api/v1/novels/search`
- 参数:
  - keyword: 搜索关键词（必填）
  - page: 页码（默认1）
  - size: 每页数量（默认10）
- 返回: 匹配的小说列表

#### 获取最新小说
- 路径: `GET /api/v1/novels/latest`
- 参数: 
  - limit: 返回数量（默认10，最大100）
- 返回: 最新更新的小说列表

#### 获取热门小说
- 路径: `GET /api/v1/novels/popular`
- 参数:
  - limit: 返回数量（默认10，最大100）
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
- 返回: 章节详细内容，包含图片信息
- 响应示例:
  ```json
  {
    "code": 0,
    "message": "success",
    "data": {
      "id": "string",
      "novelId": "string",
      "volumeNumber": 1,
      "chapterNumber": 1,
      "title": "string",
      "content": "string",
      "hasImages": true,
      "imageCount": 17,
      "imagePath": "novels/volume_1/chapter_1"
    }
  }
  ```

#### 图片访问
- 基础路径: `/novels/{小说名称}/volume_{卷号}/chapter_{章节号}/{图片序号}.jpg`
- 访问方式: 直接通过 HTTP GET 请求
- 参数: 无
- 示例:
  ```
  http://localhost:8080/novels/小说名称/volume_2/chapter_32/001.jpg
  ```
- 说明:
  1. 图片序号通常从001开始
  2. 支持的图片格式：jpg、jpeg、png、webp
  3. 图片路径信息在章节内容API响应中的imagePath字段
  4. 只有hasImages为true的章节才包含图片
  5. imageCount字段表示该章节的图片总数

### 2. 用户相关接口

#### 获取收藏列表
- 路径: `GET /api/v1/user/favorites`
- 头部: X-Device-ID
- 返回: 用户的收藏列表

#### 添加收藏
- 路径: `POST /api/v1/user/favorites/:id`
- 头部: X-Device-ID
- 返回: 添加状态

#### 取消收藏
- 路径: `DELETE /api/v1/user/favorites/:id`
- 头部: X-Device-ID
- 返回: 删除状态

#### 检查收藏状态
- 路径: `GET /api/v1/user/favorites/:id/check`
- 头部: X-Device-ID
- 返回: 是否已收藏（布尔值）

#### 获取书签列表
- 路径: `GET /api/v1/user/bookmarks`
- 头部: X-Device-ID
- 返回: 用户的书签列表

#### 创建书签
- 路径: `POST /api/v1/user/bookmarks`
- 头部: X-Device-ID
- 参数: novelId, volumeNumber, chapterNumber, position, note
- 返回: 创建的书签信息

#### 更新书签
- 路径: `PUT /api/v1/user/bookmarks/:id`
- 头部: X-Device-ID
- 参数: note
- 返回: 更新后的书签信息

#### 删除书签
- 路径: `DELETE /api/v1/user/bookmarks/:id`
- 头部: X-Device-ID
- 返回: 删除状态

#### 获取阅读历史
- 路径: `GET /api/v1/user/history`
- 头部: X-Device-ID
- 参数: limit（可选，默认10）
- 返回: 用户的阅读历史记录

#### 更新阅读进度
- 路径: `PATCH /api/v1/user/progress`
- 头部: X-Device-ID
- 参数: novelId, volumeNumber, chapterNumber, position
- 返回: 更新状态

### 3. WebSocket接口

#### 建立连接
- 路径: `GET /api/v1/ws`
- 头部: X-Device-ID（可选）
- 说明: 建立WebSocket连接以接收实时更新通知

#### 消息类型
1. 小说更新消息
```json
{
  "type": "novel_update",
  "data": {
    "novelId": "string",
    "title": "string",
    "updateType": "new_chapter|new_volume|content_update",
    "description": "string"
  },
  "time": "2024-03-17T15:04:05Z"
}
```

2. 系统通知消息
```json
{
  "type": "system_notice",
  "data": {
    "level": "info|warning|error",
    "content": "string"
  },
  "time": "2024-03-17T15:04:05Z"
}
```

### 4. 系统监控接口

#### 健康检查
- 路径: `GET /api/v1/health`
- 返回: 服务器状态信息
```json
{
  "status": "ok",
  "timestamp": "2024-03-17T15:04:05Z",
  "uptime": "24h0m0s"
}
```

#### 性能指标
- 路径: `GET /api/v1/metrics`
- 返回: 系统性能指标
```json
{
  "memory": {
    "alloc": 1234567,
    "totalAlloc": 7654321,
    "sys": 9876543,
    "numGC": 42
  },
  "goroutines": 100,
  "uptime": "24h0m0s"
}
```

## 数据模型

### Novel 小说
```go
type Novel struct {
    ID          primitive.ObjectID `json:"id"`
    Title       string            `json:"title"`
    Author      string            `json:"author"`
    Description string            `json:"description"`
    Cover       string            `json:"cover"`
    VolumeCount int               `json:"volumeCount"`
    Tags        []string          `json:"tags"`
    Status      string            `json:"status"`      // 连载中、已完结
    ReadCount   int64             `json:"readCount"`   // 阅读量
    CreatedAt   time.Time         `json:"createdAt"`
    UpdatedAt   time.Time         `json:"updatedAt"`
}
```

### Volume 卷
```go
type Volume struct {
    ID           primitive.ObjectID `json:"id"`
    NovelID      primitive.ObjectID `json:"novelId"`
    VolumeNumber int                `json:"volumeNumber"`
    ChapterCount int                `json:"chapterCount"`
    CreatedAt    time.Time          `json:"createdAt"`
    UpdatedAt    time.Time          `json:"updatedAt"`
}
```

### Chapter 章节
```go
type Chapter struct {
    ID            primitive.ObjectID `json:"id"`
    NovelID       primitive.ObjectID `json:"novelId"`
    VolumeNumber  int                `json:"volumeNumber"`
    ChapterNumber int                `json:"chapterNumber"`
    Title         string             `json:"title"`
    Content       string             `json:"content"`
    HasImages     bool               `json:"hasImages"`
    ImagePath     string             `json:"imagePath,omitempty"`
    ImageCount    int                `json:"imageCount"`
    CreatedAt     time.Time          `json:"createdAt"`
    UpdatedAt     time.Time          `json:"updatedAt"`
}
```

### Bookmark 书签
```go
type Bookmark struct {
    ID            primitive.ObjectID `json:"id"`
    DeviceID      string            `json:"deviceId"`
    NovelID       string            `json:"novelId"`
    VolumeNumber  int               `json:"volumeNumber"`
    ChapterNumber int               `json:"chapterNumber"`
    Position      int               `json:"position"`
    Note          string            `json:"note"`
    CreatedAt     time.Time         `json:"createdAt"`
    UpdatedAt     time.Time         `json:"updatedAt"`
}
```

### ReadingProgress 阅读进度
```go
type ReadingProgress struct {
    ID              primitive.ObjectID `json:"id"`
    DeviceID        string            `json:"deviceId"`
    NovelID         string            `json:"novelId"`
    CurrentProgress CurrentProgress   `json:"currentProgress"`
    CreatedAt       time.Time         `json:"createdAt"`
    UpdatedAt       time.Time         `json:"updatedAt"`
}

type CurrentProgress struct {
    VolumeNumber  int       `json:"volumeNumber"`
    ChapterNumber int       `json:"chapterNumber"`
    Position      int       `json:"position"`
    LastReadAt    time.Time `json:"lastReadAt"`
}
```

## 项目结构

### 主要目录
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

### 核心组件

1. 多级缓存
   - 本地缓存 (BigCache)
   - Redis缓存
   - 自动过期清理

2. 限流机制
   - 基于Redis的分布式限流
   - 可配置的限流规则
   - 自动清理过期限流记录

3. WebSocket服务
   - 心跳检测
   - 自动重连
   - 消息广播

4. 安全特性
   - CORS保护
   - 请求频率限制
   - 安全响应头

# Go服务器项目结构说明

## 核心文件说明

### 1. `main.go`（主入口文件）

- 服务器的入口点
- 配置加载和初始化
- 中间件链的设置
- 路由注册
- 服务器启动配置

### 2. `pkg/middleware/logger.go`（日志中间件）

- 记录每个HTTP请求的详细信息
- 包含请求时间、路径、状态码、响应时间等
- 使用标准格式输出日志

### 3. `internal/models/novel.go`（数据模型定义）

- 定义了所有数据结构：
  - `Novel`：小说基本信息
  - `Volume`：卷信息
  - `Chapter`：章节信息
  - `Bookmark`：书签
  - `ReadingProgress`：阅读进度

### 4. `internal/service/novel_service.go`（业务逻辑层）

- 实现所有小说相关的业务逻辑
- 处理数据库操作
- 提供服务层接口给API层调用

### 5. `api/v1/novel_handler.go`（API处理层）

- 处理所有HTTP请求
- 参数验证和处理
- 调用service层的方法
- 返回HTTP响应

### 6. `pkg/database/mongodb.go`（数据库连接）

- MongoDB数据库连接管理
- 提供数据库操作接口

### 7. `pkg/middleware/cache.go`（缓存中间件）

- Redis缓存实现
- 缓存GET请求响应
- 管理缓存生命周期

### 8. `pkg/middleware/rate_limiter.go`（限流中间件）

- 实现请求频率限制
- 基于令牌桶算法
- 防止API滥用

### 9. `pkg/middleware/security.go`（安全中间件）

- 添加安全相关的HTTP头
- 实现CORS策略
- 防止XSS攻击

### 10. `pkg/middleware/error.go`（错误处理中间件）

- 统一错误处理
- 标准化错误响应
- 错误日志记录

### 11. `config/config.go`（配置管理）

- 加载配置文件
- 提供配置访问接口
- 管理环境变量

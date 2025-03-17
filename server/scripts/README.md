# 轻小说EPUB处理工具

这个工具用于处理EPUB格式的轻小说文件，将文本内容存储到MongoDB数据库中，并将图片保存到文件系统中。

## 功能特点

- 解析EPUB文件，提取文本内容和图片
- 自动将小说内容分卷和章节
- 只为包含图片的章节创建目录
- 支持图片格式检查和优化
- 自动上传数据到MongoDB数据库

## 环境要求

- Python 3.8+
- MongoDB 4.0+
- 所需Python包见`requirements.txt`

## 安装

1. 克隆代码库
2. 安装依赖：
```bash
pip install -r requirements.txt
```

3. 创建`.env`文件并配置：
```env
MONGO_URI=mongodb://localhost:27017
MONGO_DB=lightnovel
BASE_NOVEL_DIR=novels
```

## 使用方法

```bash
python main.py /path/to/your/novel.epub
```

## 数据结构

### 文件系统结构
```
novels/
├── 小说名称/
│   ├── volume_1/
│   │   ├── chapter_1/
│   │   │   ├── 001.jpg
│   │   │   ├── 002.jpg
│   │   │   └── ...
│   │   └── ...
│   └── ...
```

### MongoDB集合结构

1. novels
   - _id: ObjectId
   - title: String
   - volumeCount: Int
   - createdAt: DateTime
   - updatedAt: DateTime

2. volumes
   - _id: ObjectId
   - novelId: String
   - volumeNumber: Int
   - chapterCount: Int
   - createdAt: DateTime
   - updatedAt: DateTime

3. chapters
   - _id: ObjectId
   - novelId: String
   - volumeNumber: Int
   - chapterNumber: Int
   - title: String
   - content: String
   - hasImages: Boolean
   - imagePath: String (optional)
   - imageCount: Int
   - createdAt: DateTime
   - updatedAt: DateTime 
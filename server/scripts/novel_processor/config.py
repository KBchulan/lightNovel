import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

# 获取项目根目录（scripts的父目录）
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# MongoDB配置
MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017')
MONGO_DB = os.getenv('MONGO_DB', 'lightnovel')

# 文件路径配置
BASE_NOVEL_DIR = os.path.join(ROOT_DIR, 'novels')

# 图片配置
ALLOWED_IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp'}
MAX_IMAGE_SIZE = 16 * 1024 * 1024  # 16MB

# 创建必要的目录
os.makedirs(BASE_NOVEL_DIR, exist_ok=True) 
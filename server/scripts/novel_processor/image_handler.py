import os
import logging
from PIL import Image
from io import BytesIO
from typing import Dict, List
from .config import BASE_NOVEL_DIR, ALLOWED_IMAGE_EXTENSIONS, MAX_IMAGE_SIZE

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ImageHandler:
    def __init__(self):
        self.base_dir = BASE_NOVEL_DIR
        
    def process_images(self, novel_data: Dict):
        """处理小说中的图片"""
        novel_title = novel_data['title']
        
        for volume in novel_data['volumes']:
            volume_number = volume['volume_number']
            
            for chapter in volume['chapters']:
                if chapter['images']:  # 只处理有图片的章节
                    try:
                        chapter_path = self._create_chapter_dir(
                            novel_title,
                            volume_number,
                            chapter['chapter_number']
                        )
                        self._save_chapter_images(chapter['images'], chapter_path)
                    except Exception as e:
                        logger.error(f"处理章节 {chapter['chapter_number']} 的图片时出错: {str(e)}")
                        continue
                        
    def _create_chapter_dir(self, novel_title: str, volume_number: int, chapter_number: int) -> str:
        """创建章节目录"""
        chapter_path = os.path.join(
            self.base_dir,
            novel_title,
            f"volume_{volume_number}",
            f"chapter_{chapter_number}"
        )
        os.makedirs(chapter_path, exist_ok=True)
        return chapter_path
        
    def _save_chapter_images(self, images: List[Dict], chapter_path: str):
        """保存章节的图片"""
        for idx, image_data in enumerate(images, 1):
            try:
                # 检查图片类型
                image_type = image_data['image_type'].lower()
                if image_type not in ALLOWED_IMAGE_EXTENSIONS:
                    logger.warning(f"不支持的图片类型: {image_type}")
                    continue
                    
                # 检查图片大小
                if len(image_data['image_data']) > MAX_IMAGE_SIZE:
                    logger.warning(f"图片太大: {len(image_data['image_data'])} bytes")
                    continue
                    
                # 处理图片
                image = Image.open(BytesIO(image_data['image_data']))
                
                # 生成文件名
                filename = f"{idx:03d}{image_type}"
                filepath = os.path.join(chapter_path, filename)
                
                # 保存图片
                image.save(filepath, quality=85, optimize=True)
                logger.info(f"保存图片: {filepath}")
                
            except Exception as e:
                logger.error(f"保存图片时出错: {str(e)}")
                continue
                
    def get_chapter_image_info(self, novel_title: str, volume_number: int, chapter_number: int) -> Dict:
        """获取章节图片信息"""
        chapter_path = os.path.join(
            self.base_dir,
            novel_title,
            f"volume_{volume_number}",
            f"chapter_{chapter_number}"
        )
        
        if not os.path.exists(chapter_path):
            return {
                'has_images': False,
                'image_count': 0,
                'image_path': None
            }
            
        images = [f for f in os.listdir(chapter_path) 
                 if os.path.splitext(f)[1].lower() in ALLOWED_IMAGE_EXTENSIONS]
                 
        return {
            'has_images': bool(images),
            'image_count': len(images),
            'image_path': chapter_path if images else None
        } 
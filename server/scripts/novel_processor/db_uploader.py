import logging
from typing import Dict, Optional
from pymongo import MongoClient
from datetime import datetime
from .config import MONGO_URI, MONGO_DB

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DbUploader:
    def __init__(self):
        self.client = MongoClient(MONGO_URI)
        self.db = self.client[MONGO_DB]
        
    def upload_to_mongodb(self, novel_data: Dict):
        """上传小说数据到MongoDB"""
        try:
            # 上传小说信息
            novel_id = self._upload_novel_info(novel_data)
            
            # 上传卷和章节信息
            for volume in novel_data['volumes']:
                volume_id = self._upload_volume(novel_id, volume)
                for chapter in volume['chapters']:
                    self._upload_chapter(novel_id, volume['volume_number'], chapter)
                    
            logger.info(f"成功上传小说 '{novel_data['title']}' 的数据")
            
        except Exception as e:
            logger.error(f"上传数据时出错: {str(e)}")
            raise
            
    def _upload_novel_info(self, novel_data: Dict) -> str:
        """上传小说基本信息"""
        novels = self.db.novels
        
        novel_info = {
            'title': novel_data['title'],
            'author': novel_data['author'],
            'description': novel_data['description'],
            'volumeCount': len(novel_data['volumes']),
            'createdAt': datetime.utcnow(),
            'updatedAt': datetime.utcnow()
        }
        
        # 检查是否已存在
        existing_novel = novels.find_one({'title': novel_data['title']})
        if existing_novel:
            novels.update_one(
                {'_id': existing_novel['_id']},
                {'$set': {**novel_info, 'updatedAt': datetime.utcnow()}}
            )
            return str(existing_novel['_id'])
            
        result = novels.insert_one(novel_info)
        return str(result.inserted_id)
        
    def _upload_volume(self, novel_id: str, volume_data: Dict) -> str:
        """上传卷信息"""
        volumes = self.db.volumes
        
        volume_info = {
            'novelId': novel_id,
            'volumeNumber': volume_data['volume_number'],
            'volumeTitle': volume_data.get('volume_title', f"第{volume_data['volume_number']}卷"),
            'chapterCount': len(volume_data['chapters']),
            'createdAt': datetime.utcnow(),
            'updatedAt': datetime.utcnow()
        }
        
        # 检查是否已存在
        existing_volume = volumes.find_one({
            'novelId': novel_id,
            'volumeNumber': volume_data['volume_number']
        })
        
        if existing_volume:
            volumes.update_one(
                {'_id': existing_volume['_id']},
                {'$set': {**volume_info, 'updatedAt': datetime.utcnow()}}
            )
            return str(existing_volume['_id'])
            
        result = volumes.insert_one(volume_info)
        return str(result.inserted_id)
        
    def _upload_chapter(self, novel_id: str, volume_number: int, chapter_data: Dict):
        """上传章节信息"""
        chapters = self.db.chapters
        
        # 确定章节是否有图片
        has_images = bool(chapter_data.get('images'))
        image_path = None
        image_count = 0
        
        if has_images:
            image_path = f"novels//volume_{volume_number}/chapter_{chapter_data['chapter_number']}"
            image_count = len(chapter_data['images'])
            
        chapter_info = {
            'novelId': novel_id,
            'volumeNumber': volume_number,
            'chapterNumber': chapter_data['chapter_number'],
            'title': chapter_data['title'],
            'content': chapter_data['content'],
            'hasImages': has_images,
            'imagePath': image_path,
            'imageCount': image_count,
            'createdAt': datetime.utcnow(),
            'updatedAt': datetime.utcnow()
        }
        
        # 检查是否已存在
        existing_chapter = chapters.find_one({
            'novelId': novel_id,
            'volumeNumber': volume_number,
            'chapterNumber': chapter_data['chapter_number']
        })
        
        if existing_chapter:
            chapters.update_one(
                {'_id': existing_chapter['_id']},
                {'$set': {**chapter_info, 'updatedAt': datetime.utcnow()}}
            )
        else:
            chapters.insert_one(chapter_info)

    def delete_novel_by_title(self, title: str):
        """删除指定标题的小说及其所有相关数据"""
        try:
            # 1. 先找到novel
            novel = self.db.novels.find_one({'title': title})
            if not novel:
                logger.warning(f"未找到标题为 '{title}' 的小说")
                return
                
            novel_id = str(novel['_id'])
            
            # 2. 删除所有相关章节
            chapters_result = self.db.chapters.delete_many({'novelId': novel_id})
            logger.info(f"删除了 {chapters_result.deleted_count} 个章节")
            
            # 3. 删除所有相关卷
            volumes_result = self.db.volumes.delete_many({'novelId': novel_id})
            logger.info(f"删除了 {volumes_result.deleted_count} 个卷")
            
            # 4. 最后删除小说本身
            self.db.novels.delete_one({'_id': novel['_id']})
            logger.info(f"删除了小说 '{title}'")
            
        except Exception as e:
            logger.error(f"删除小说数据时出错: {str(e)}")
            raise 
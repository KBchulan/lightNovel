import os
import re
import ebooklib
from ebooklib import epub
from bs4 import BeautifulSoup
from typing import Dict, List, Optional, Tuple
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EpubParser:
    def __init__(self):
        self.book = None
        self.title = ""
        self.chapters = []
        
    def parse_epub(self, epub_path: str) -> Dict:
        """解析EPUB文件，提取文本和图片"""
        try:
            self.book = epub.read_epub(epub_path)
            self.title = self._get_title()
            self._process_chapters()
            
            return {
                'title': self.title,
                'volumes': self._organize_chapters()
            }
        except Exception as e:
            logger.error(f"解析EPUB文件时出错: {str(e)}")
            raise
            
    def _get_title(self) -> str:
        """获取小说标题"""
        if self.book.title:
            return self.book.title
        return os.path.splitext(os.path.basename(self.book.path))[0]
        
    def _process_chapters(self):
        """处理所有章节"""
        self.chapters = []
        chapter_items = []
        
        # 收集所有章节项
        for item in self.book.items:
            if isinstance(item, epub.EpubHtml):
                if not item.is_chapter():
                    continue
                chapter_items.append(item)
        
        # 按照spine顺序排序章节
        sorted_items = sorted(chapter_items, key=lambda x: self.book.spine.index(x.id) if x.id in self.book.spine else 999999)
        
        # 处理每个章节
        for idx, item in enumerate(sorted_items, 1):
            chapter_data = self._process_chapter(item, idx)
            if chapter_data:
                self.chapters.append(chapter_data)
                
    def _process_chapter(self, chapter: epub.EpubHtml, index: int) -> Optional[Dict]:
        """处理单个章节"""
        try:
            soup = BeautifulSoup(chapter.content, 'lxml')
            
            # 提取标题
            title = soup.find('title')
            title = title.text if title else chapter.title
            
            # 使用索引作为章节号
            chapter_number = index
                
            # 提取文本内容
            content = self._extract_content(soup)
            
            # 提取图片
            images = self._extract_images(chapter, soup)
            
            return {
                'chapter_number': chapter_number,
                'title': title,
                'content': content,
                'images': images
            }
        except Exception as e:
            logger.error(f"处理章节时出错: {str(e)}")
            return None
            
    def _extract_content(self, soup: BeautifulSoup) -> str:
        """提取章节文本内容"""
        # 移除script和style标签
        for tag in soup(['script', 'style']):
            tag.decompose()
            
        # 获取文本
        text = soup.get_text()
        
        # 清理文本
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        return '\n'.join(lines)
        
    def _extract_images(self, chapter: epub.EpubHtml, soup: BeautifulSoup) -> List[Dict]:
        """提取章节中的图片"""
        images = []
        for img in soup.find_all('img'):
            src = img.get('src')
            if src:
                try:
                    # 获取图片数据
                    image_item = self.book.get_item_with_href(src)
                    if image_item:
                        image_data = image_item.content
                        image_name = os.path.basename(src)
                        image_type = os.path.splitext(src)[1].lower()
                        
                        images.append({
                            'image_data': image_data,
                            'image_name': image_name,
                            'image_type': image_type
                        })
                except Exception as e:
                    logger.error(f"提取图片时出错: {str(e)}")
                    continue
        
        return images if images else None
        
    def _organize_chapters(self) -> List[Dict]:
        """将章节组织成卷的结构"""
        # 按照章节号排序
        sorted_chapters = sorted(self.chapters, key=lambda x: x['chapter_number'])
        
        # 每20章一卷
        CHAPTERS_PER_VOLUME = 20
        volumes = []
        
        for i in range(0, len(sorted_chapters), CHAPTERS_PER_VOLUME):
            volume_chapters = sorted_chapters[i:i + CHAPTERS_PER_VOLUME]
            volume = {
                'volume_number': (i // CHAPTERS_PER_VOLUME) + 1,
                'chapters': volume_chapters
            }
            volumes.append(volume)
            
        return volumes 
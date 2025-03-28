import os
import re
import ebooklib
from ebooklib import epub
from bs4 import BeautifulSoup
import xml.etree.ElementTree as ET
from typing import Dict, List, Optional, Tuple
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EpubParser:
    def __init__(self):
        self.book = None
        self.title = ""
        self.author = ""
        self.description = ""
        self.chapters = []
        self.toc_structure = {}
        
    def parse_epub(self, epub_path: str) -> Dict:
        """解析EPUB文件, 提取文本和图片"""
        try:
            self.book = epub.read_epub(epub_path)
            
            # 直接从ebooklib获取基本元数据
            self._get_metadata_from_ebooklib()
            
            # 尝试从content.opf提取元数据
            self._extract_metadata_from_opf()
            
            # 处理章节和结构
            self._process_chapters()
            self._parse_toc_structure()
            
            # 记录最终结果
            logger.info(f"最终提取的元数据: 标题='{self.title}', 作者='{self.author}', 描述长度={len(self.description)}")
            
            return {
                'title': self.title,
                'author': self.author,
                'description': self.description,
                'volumes': self._organize_chapters()
            }
        except Exception as e:
            logger.error(f"解析EPUB文件时出错: {str(e)}")
            raise
    
    def _get_metadata_from_ebooklib(self):
        """直接从ebooklib获取元数据"""
        try:
            # 获取标题
            if self.book.title:
                self.title = self.book.title
            
            # 获取作者
            creators = self.book.get_metadata('DC', 'creator')
            if creators and creators[0][0]:
                self.author = creators[0][0]
            
            # 获取描述
            descriptions = self.book.get_metadata('DC', 'description')
            if descriptions and descriptions[0][0]:
                self.description = descriptions[0][0]
                
            logger.info(f"从ebooklib直接获取的元数据: 标题='{self.title}', 作者='{self.author}', 描述长度={len(self.description)}")
        except Exception as e:
            logger.error(f"从ebooklib获取元数据时出错: {str(e)}")
    
    def _extract_metadata_from_opf(self):
        """从content.opf提取元数据"""
        try:
            # 查找content.opf文件
            opf_item = None
            for item in self.book.items:
                if isinstance(item, ebooklib.epub.EpubItem) and (item.file_name.endswith('.opf') or item.media_type == 'application/oebps-package+xml'):
                    opf_item = item
                    break
            
            if not opf_item:
                logger.info("通过文件名未找到content.opf文件，尝试通过类型查找")
                # 尝试通过媒体类型查找
                for item in self.book.get_items():
                    if item.media_type == 'application/oebps-package+xml':
                        opf_item = item
                        break
            
            if not opf_item:
                logger.info("未能找到content.opf文件，将使用ebooklib已提取的元数据")
                return
                
            opf_content = opf_item.content.decode('utf-8')
            
            # 记录原始OPF内容中的作者信息（用于调试）
            author_match = re.search(r'<dc:creator[^>]*>(.*?)</dc:creator>', opf_content)
            if author_match:
                logger.debug(f"OPF中找到作者信息: {author_match.group(1)}")
            
            # 1. 使用BeautifulSoup解析XML
            soup = BeautifulSoup(opf_content, 'xml')
            
            # 提取标题
            if not self.title:
                title_elem = soup.find('dc:title') or soup.find('title')
                if title_elem and title_elem.text.strip():
                    self.title = title_elem.text.strip()
            
            # 提取作者 - 尝试多种可能的标签
            if not self.author:
                # 直接使用字符串查找
                creator_match = re.search(r'<dc:creator[^>]*>(.*?)</dc:creator>', opf_content)
                if creator_match and creator_match.group(1).strip():
                    self.author = creator_match.group(1).strip()
                    logger.debug(f"通过正则表达式提取到作者: {self.author}")
                else:
                    # 尝试使用BeautifulSoup
                    creator_elem = soup.find('dc:creator') or soup.find('creator')
                    if creator_elem and creator_elem.text.strip():
                        self.author = creator_elem.text.strip()
                        logger.debug(f"通过BeautifulSoup提取到作者: {self.author}")
                    else:
                        # 尝试其他可能的标记
                        for elem in soup.find_all(['creator', 'meta']):
                            if (elem.get('property') == 'dcterms:creator' or 
                                elem.get('name') == 'author' or 
                                elem.get('id') == 'creator'):
                                self.author = elem.text.strip() or elem.get('content', '').strip()
                                logger.debug(f"通过其他标签提取到作者: {self.author}")
                                break
            
            # 提取描述
            if not self.description:
                desc_elem = soup.find('dc:description') or soup.find('description')
                if desc_elem and desc_elem.text.strip():
                    self.description = desc_elem.text.strip()
                else:
                    # 尝试其他可能的标记
                    for elem in soup.find_all('meta'):
                        if elem.get('property') == 'dcterms:description' or elem.get('name') == 'description':
                            self.description = elem.text.strip() or elem.get('content', '').strip()
                            break
            
            # 2. 使用ElementTree解析XML（作为备选方案）
            if not self.author:
                try:
                    namespaces = {
                        'opf': 'http://www.idpf.org/2007/opf',
                        'dc': 'http://purl.org/dc/elements/1.1/'
                    }
                    
                    root = ET.fromstring(opf_content)
                    metadata = root.find('.//{http://www.idpf.org/2007/opf}metadata')
                    
                    if metadata is not None:
                        # 查找creator元素
                        creator = metadata.find('.//{http://purl.org/dc/elements/1.1/}creator')
                        if creator is not None and creator.text:
                            self.author = creator.text.strip()
                            logger.debug(f"通过ElementTree提取到作者: {self.author}")
                except Exception as e:
                    logger.error(f"使用ElementTree解析XML时出错: {str(e)}")
            
            # 3. 最后的回退方案：如果还是没有找到作者，将其设置为默认值
            if not self.author:
                self.author = "未知作者"
                logger.warning("无法提取作者信息，使用默认值")
                
            logger.debug(f"从content.opf提取的元数据: 标题='{self.title}', 作者='{self.author}', 描述长度={len(self.description)}")
                
        except Exception as e:
            logger.error(f"提取元数据时出错: {str(e)}")
            # 使用默认值
            if not self.title:
                self.title = os.path.splitext(os.path.basename(self.book.path))[0]
            if not self.author:
                self.author = "未知作者"
            if not self.description:
                self.description = ""
            
    def _parse_toc_structure(self):
        """解析nav.xhtml或toc.ncx获取章节结构"""
        try:
            # 查找nav.xhtml
            nav_item = None
            for item in self.book.items:
                if isinstance(item, epub.EpubHtml) and item.properties and 'nav' in item.properties:
                    nav_item = item
                    break
                if item.file_name.endswith('nav.xhtml'):
                    nav_item = item
                    break
            
            if nav_item:
                self._parse_nav_structure(nav_item)
            else:
                # 如果没有nav.xhtml，尝试解析toc.ncx
                self._parse_ncx_structure()
        except Exception as e:
            logger.error(f"解析目录结构时出错: {str(e)}")
            
    def _parse_nav_structure(self, nav_item):
        """解析nav.xhtml中的目录结构"""
        try:
            soup = BeautifulSoup(nav_item.content, 'xml')
            nav = soup.find('nav', {'epub:type': 'toc'}) or soup.find('nav')
            
            if not nav:
                return
                
            current_volume = None
            structure = {}
            
            # 查找所有顶级<li>元素
            top_level_items = nav.find_all('li', recursive=False)
            if not top_level_items:  # 如果没有直接子<li>，找所有<li>
                top_level_items = nav.find_all('li')
            
            for li in top_level_items:
                # 检查是否是卷
                span = li.find('span')
                if span and '卷' in span.text:
                    current_volume = span.text
                    structure[current_volume] = []
                    # 找到当前卷的所有章节
                    chapter_items = li.find_all('li')
                    for chapter_li in chapter_items:
                        a_tag = chapter_li.find('a')
                        if a_tag and a_tag.get('href'):
                            chapter_href = a_tag.get('href')
                            chapter_title = a_tag.text
                            structure[current_volume].append({
                                'href': chapter_href,
                                'title': chapter_title
                            })
            
            self.toc_structure = structure
        except Exception as e:
            logger.error(f"解析nav.xhtml时出错: {str(e)}")
    
    def _parse_ncx_structure(self):
        """解析toc.ncx中的目录结构"""
        try:
            # 查找toc.ncx文件
            ncx_item = None
            for item in self.book.items:
                if item.file_name.endswith('.ncx'):
                    ncx_item = item
                    break
            
            if not ncx_item:
                return
                
            soup = BeautifulSoup(ncx_item.content, 'xml')
            nav_map = soup.find('navMap')
            
            if not nav_map:
                return
                
            structure = {}
            current_volume = "第一卷"  # 默认卷
            structure[current_volume] = []
            
            for nav_point in nav_map.find_all('navPoint'):
                label = nav_point.find('text').text if nav_point.find('text') else ""
                content = nav_point.find('content')
                href = content.get('src') if content else ""
                
                if '卷' in label and not href:
                    current_volume = label
                    structure[current_volume] = []
                else:
                    structure[current_volume].append({
                        'href': href,
                        'title': label
                    })
            
            self.toc_structure = structure
        except Exception as e:
            logger.error(f"解析toc.ncx时出错: {str(e)}")
        
    def _process_chapters(self):
        """处理所有章节"""
        self.chapters = []
        chapter_items = []
        
        # 收集所有章节项
        for item in self.book.items:
            if isinstance(item, epub.EpubHtml):
                chapter_items.append(item)
        
        # 获取spine顺序
        spine_ids = []
        try:
            # 处理不同版本的ebooklib的spine格式
            if hasattr(self.book.spine, '__iter__'):
                for spine_item in self.book.spine:
                    if isinstance(spine_item, tuple) and len(spine_item) > 0:
                        spine_ids.append(spine_item[0])  # 元组第一个元素是ID
                    elif hasattr(spine_item, 'idref'):
                        spine_ids.append(spine_item.idref)
                    elif isinstance(spine_item, str):
                        spine_ids.append(spine_item)
            elif isinstance(self.book.spine, list):
                spine_ids = self.book.spine  # 可能是ID列表
        except Exception as e:
            logger.error(f"提取spine顺序时出错: {str(e)}")
            # 如果无法提取spine顺序，使用默认顺序
            
        # 尝试按照spine顺序排序章节，如果失败则按照默认顺序
        if spine_ids:
            try:
                # 先按照spine_ids中的顺序排序
                def get_position(item):
                    try:
                        return spine_ids.index(item.id)
                    except (ValueError, AttributeError):
                        return 999999
                
                sorted_items = sorted(chapter_items, key=get_position)
            except Exception as e:
                logger.error(f"按spine顺序排序章节时出错: {str(e)}")
                sorted_items = chapter_items
        else:
            sorted_items = chapter_items
        
        # 处理每个章节
        for idx, item in enumerate(sorted_items, 1):
            chapter_data = self._process_chapter(item, idx)
            if chapter_data:
                self.chapters.append(chapter_data)
                
    def _process_chapter(self, chapter: epub.EpubHtml, index: int) -> Optional[Dict]:
        """处理单个章节"""
        try:
            # 使用正确的解析器处理XML内容
            soup = BeautifulSoup(chapter.content, 'xml')
            
            # 提取标题
            title_tag = soup.find('title')
            h1_tag = soup.find('h1')
            h2_tag = soup.find('h2')
            
            if title_tag and title_tag.text.strip():
                title = title_tag.text.strip()
            elif h1_tag and h1_tag.text.strip():
                title = h1_tag.text.strip()
            elif h2_tag and h2_tag.text.strip():
                title = h2_tag.text.strip()
            else:
                title = chapter.title if chapter.title else f"第{index}章"
            
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
                'images': images,
                'file_name': chapter.file_name
            }
        except Exception as e:
            logger.error(f"处理章节时出错: {str(e)}")
            # 如果XML解析失败，尝试使用HTML解析器
            try:
                soup = BeautifulSoup(chapter.content, 'lxml')
                
                title_tag = soup.find('title')
                h1_tag = soup.find('h1')
                h2_tag = soup.find('h2')
                
                if title_tag and title_tag.text.strip():
                    title = title_tag.text.strip()
                elif h1_tag and h1_tag.text.strip():
                    title = h1_tag.text.strip()
                elif h2_tag and h2_tag.text.strip():
                    title = h2_tag.text.strip()
                else:
                    title = chapter.title if chapter.title else f"第{index}章"
                
                content = self._extract_content(soup)
                images = self._extract_images(chapter, soup)
                
                return {
                    'chapter_number': chapter_number,
                    'title': title,
                    'content': content,
                    'images': images,
                    'file_name': chapter.file_name
                }
            except Exception as inner_e:
                logger.error(f"使用备用解析器处理章节时出错: {str(inner_e)}")
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
                    image_item = self.book.get_item_with_href(chapter.get_name() + '/' + src)
                    if not image_item:
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
        """将章节按照目录结构组织成卷"""
        volumes = []
        
        # 如果有目录结构，按照目录组织
        if self.toc_structure:
            volume_number = 1
            for volume_title, chapter_links in self.toc_structure.items():
                chapters_in_volume = []
                
                for idx, chapter_link in enumerate(chapter_links, 1):
                    # 找到匹配的章节
                    href = chapter_link['href'].split('#')[0]  # 移除锚点
                    matching_chapter = None
                    
                    for chapter in self.chapters:
                        if chapter['file_name'] == href or href in chapter['file_name']:
                            matching_chapter = chapter.copy()
                            matching_chapter['chapter_number'] = idx
                            matching_chapter['title'] = chapter_link['title']
                            chapters_in_volume.append(matching_chapter)
                            break
                    
                    if not matching_chapter and idx <= len(self.chapters):
                        # 如果没找到匹配的章节，使用索引位置的章节
                        chapter_idx = idx - 1
                        if chapter_idx < len(self.chapters):
                            matching_chapter = self.chapters[chapter_idx].copy()
                            matching_chapter['chapter_number'] = idx
                            matching_chapter['title'] = chapter_link['title']
                            chapters_in_volume.append(matching_chapter)
                
                if chapters_in_volume:
                    volume = {
                        'volume_number': volume_number,
                        'volume_title': volume_title,
                        'chapters': chapters_in_volume
                    }
                    volumes.append(volume)
                    volume_number += 1
        
        # 如果没有目录结构或目录结构处理失败，回退到默认的分组方式
        if not volumes:
            # 按照章节号排序
            sorted_chapters = sorted(self.chapters, key=lambda x: x['chapter_number'])
            
            # 每20章一卷
            CHAPTERS_PER_VOLUME = 20
            
            for i in range(0, len(sorted_chapters), CHAPTERS_PER_VOLUME):
                volume_chapters = sorted_chapters[i:i + CHAPTERS_PER_VOLUME]
                volume = {
                    'volume_number': (i // CHAPTERS_PER_VOLUME) + 1,
                    'volume_title': f"第{(i // CHAPTERS_PER_VOLUME) + 1}卷",
                    'chapters': volume_chapters
                }
                volumes.append(volume)
            
        return volumes 
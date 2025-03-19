import argparse
import logging
from novel_processor.epub_parser import EpubParser
from novel_processor.image_handler import ImageHandler
from novel_processor.db_uploader import DbUploader

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def process_novel(epub_path: str):
    """处理轻小说文件"""
    try:
        # 1. 解析EPUB文件
        logger.info(f"开始解析EPUB文件: {epub_path}")
        parser = EpubParser()
        novel_data = parser.parse_epub(epub_path)
        logger.info(f"成功解析EPUB文件: {novel_data['title']}")
        
        # 2. 处理图片
        logger.info("开始处理图片")
        image_handler = ImageHandler()
        image_handler.process_images(novel_data)
        logger.info("图片处理完成")
        
        # 3. 上传到MongoDB
        logger.info("开始上传数据到MongoDB")
        db_uploader = DbUploader()
        db_uploader.upload_to_mongodb(novel_data)
        logger.info("数据上传完成")
        
        logger.info(f"小说 '{novel_data['title']}' 处理完成")
        
    except Exception as e:
        logger.error(f"处理过程中出错: {str(e)}")
        raise

def main():
    parser = argparse.ArgumentParser(description='轻小说EPUB处理工具')
    parser.add_argument('--delete', help='要删除的小说标题')
    parser.add_argument('--epub', help='EPUB文件路径')
    args = parser.parse_args()
    
    try:
        if args.delete:
            # 删除小说
            db_uploader = DbUploader()
            db_uploader.delete_novel_by_title(args.delete)
        elif args.epub:
            # 处理EPUB文件
            process_novel(args.epub)
        else:
            parser.print_help()
    except Exception as e:
        logger.error(f"程序执行失败: {str(e)}")
        exit(1)

if __name__ == '__main__':
    main() 
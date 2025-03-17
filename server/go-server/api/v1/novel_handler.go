package v1

import (
	"context"
	"lightnovel/internal/service"
	"lightnovel/pkg/errors"
	"lightnovel/pkg/response"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// @title Light Novel API
// @version 1.0
// @description 轻小说阅读API服务
// @BasePath /api/v1

type NovelHandler struct {
	novelService *service.NovelService
}

func NewNovelHandler(novelService *service.NovelService) *NovelHandler {
	return &NovelHandler{novelService: novelService}
}

// @Summary 获取所有小说
// @Description 获取小说列表，支持分页
// @Tags novels
// @Accept json
// @Produce json
// @Param page query int false "页码" default(1)
// @Param size query int false "每页数量" default(10)
// @Success 200 {object} response.PageResponse
// @Router /novels [get]
func (h *NovelHandler) GetAllNovels(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "10"))

	novels, total, err := h.novelService.GetAllNovels(c.Request.Context(), page, size)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	response.SuccessWithPage(c, total, page, size, novels)
}

// @Summary 获取小说详情
// @Description 根据ID获取小说详情
// @Tags novels
// @Accept json
// @Produce json
// @Param id path string true "小说ID"
// @Success 200 {object} models.Novel
// @Router /novels/{id} [get]
func (h *NovelHandler) GetNovelByID(c *gin.Context) {
	id := c.Param("id")
	novel, err := h.novelService.GetNovelByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if novel == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "novel not found"})
		return
	}

	c.JSON(http.StatusOK, novel)
}

// GetVolumesByNovelID 获取小说的所有卷
func (h *NovelHandler) GetVolumesByNovelID(c *gin.Context) {
	novelID := c.Param("id")
	volumes, err := h.novelService.GetVolumesByNovelID(c.Request.Context(), novelID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, volumes)
}

// GetChaptersByVolumeID 获取卷的所有章节
func (h *NovelHandler) GetChaptersByVolumeID(c *gin.Context) {
	novelID := c.Param("id")
	volumeNumber, err := strconv.Atoi(c.Param("volume"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid volume number"})
		return
	}

	chapters, err := h.novelService.GetChaptersByVolumeID(c.Request.Context(), novelID, volumeNumber)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, chapters)
}

// GetChapterByNumber 获取指定章节
func (h *NovelHandler) GetChapterByNumber(c *gin.Context) {
	novelID := c.Param("id")
	volumeNumber, err := strconv.Atoi(c.Param("volume"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid volume number"})
		return
	}

	chapterNumber, err := strconv.Atoi(c.Param("chapter"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid chapter number"})
		return
	}

	chapter, err := h.novelService.GetChapterByNumber(c.Request.Context(), novelID, volumeNumber, chapterNumber)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if chapter == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "chapter not found"})
		return
	}

	// 异步增加阅读量
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := h.novelService.IncrementNovelReadCount(ctx, novelID); err != nil {
			log.Printf("Failed to increment read count for novel %s: %v", novelID, err)
		}
	}()

	c.JSON(http.StatusOK, chapter)
}

// @Summary 搜索小说
// @Description 根据关键词搜索小说
// @Tags novels
// @Accept json
// @Produce json
// @Param keyword query string true "搜索关键词"
// @Param page query int false "页码" default(1)
// @Param size query int false "每页数量" default(10)
// @Success 200 {object} response.Response
// @Router /novels/search [get]
func (h *NovelHandler) SearchNovels(c *gin.Context) {
	keyword := c.Query("keyword")
	if keyword == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	// 获取分页参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "10"))
	if page < 1 {
		page = 1
	}
	if size < 1 || size > 50 {
		size = 10
	}

	novels, total, err := h.novelService.SearchNovels(c.Request.Context(), keyword, page, size)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{
		"total": total,
		"items": novels,
		"page":  page,
		"size":  size,
	})
}

// @Summary 获取最新小说
// @Description 获取最新更新的小说列表
// @Tags novels
// @Accept json
// @Produce json
// @Param limit query int false "限制数量" default(10)
// @Success 200 {object} response.Response
// @Router /novels/latest [get]
func (h *NovelHandler) GetLatestNovels(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	novels, err := h.novelService.GetLatestNovels(c.Request.Context(), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"novels": novels})
}

// @Summary 获取热门小说
// @Description 获取阅读量最高的小说列表
// @Tags novels
// @Accept json
// @Produce json
// @Param limit query int false "限制数量" default(10)
// @Success 200 {object} response.Response
// @Router /novels/popular [get]
func (h *NovelHandler) GetPopularNovels(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	novels, err := h.novelService.GetPopularNovels(c.Request.Context(), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"novels": novels})
}

// @Summary 获取用户书签
// @Description 获取用户的所有书签
// @Tags user
// @Accept json
// @Produce json
// @Param X-Device-ID header string false "设备ID"
// @Success 200 {object} response.Response
// @Router /user/bookmarks [get]
func (h *NovelHandler) GetUserBookmarks(c *gin.Context) {
	deviceID := c.GetHeader("X-Device-ID")
	if deviceID == "" {
		deviceID = c.ClientIP() // 如果没有设备ID，使用IP地址作为标识
	}

	bookmarks, err := h.novelService.GetUserBookmarks(c.Request.Context(), deviceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"bookmarks": bookmarks})
}

// @Summary 更新阅读进度
// @Description 更新用户的阅读进度
// @Tags user
// @Accept json
// @Produce json
// @Param X-Device-ID header string false "设备ID"
// @Param progress body object true "阅读进度"
// @Success 200 {object} response.Response
// @Router /user/progress [patch]
func (h *NovelHandler) UpdateReadingProgress(c *gin.Context) {
	deviceID := c.GetHeader("X-Device-ID")
	if deviceID == "" {
		deviceID = c.ClientIP() // 如果没有设备ID，使用IP地址作为标识
	}

	var progress struct {
		NovelID   string `json:"novelId" binding:"required"`
		VolumeID  int    `json:"volumeId" binding:"required"`
		ChapterID int    `json:"chapterId" binding:"required"`
		Position  int    `json:"position"`
	}

	if err := c.ShouldBindJSON(&progress); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求参数"})
		return
	}

	err := h.novelService.UpdateReadingProgress(c.Request.Context(), deviceID, progress.NovelID, progress.VolumeID, progress.ChapterID, progress.Position)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "更新成功"})
}

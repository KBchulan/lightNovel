package v1

import (
	"encoding/json"
	"lightnovel/config"
	ws "lightnovel/pkg/websocket"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

// WSMessage WebSocket消息结构
type WSMessage struct {
	Type string      `json:"type"`
	Data interface{} `json:"data"`
	Time time.Time   `json:"time"`
}

// NovelUpdate 小说更新消息
type NovelUpdate struct {
	NovelID     string `json:"novelId"`
	Title       string `json:"title"`
	UpdateType  string `json:"updateType"` // "new_chapter", "new_volume", "content_update"
	Description string `json:"description"`
}

var (
	upgrader = websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		CheckOrigin: func(r *http.Request) bool {
			origin := r.Header.Get("Origin")
			// 开发环境允许所有来源
			if gin.Mode() == gin.DebugMode {
				return true
			}
			// 生产环境检查允许的域名
			allowedOrigins := []string{
				"https://your-domain.com",
				"https://api.your-domain.com",
			}
			return isAllowedOrigin(origin, allowedOrigins)
		},
	}
)

// WebSocketHandler 处理WebSocket连接
type WebSocketHandler struct {
	hub *ws.Hub
	cfg *config.Config
}

// NewWebSocketHandler 创建WebSocket处理器
func NewWebSocketHandler(cfg *config.Config) *WebSocketHandler {
	hub := ws.NewHub()
	go hub.Run()
	return &WebSocketHandler{
		hub: hub,
		cfg: cfg,
	}
}

// isAllowedOrigin 检查origin是否在允许列表中
func isAllowedOrigin(origin string, allowedOrigins []string) bool {
	if origin == "" {
		return false
	}
	for _, allowed := range allowedOrigins {
		if strings.EqualFold(origin, allowed) {
			return true
		}
	}
	return false
}

// HandleConnection 处理WebSocket连接请求
func (h *WebSocketHandler) HandleConnection(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	client := ws.NewClient(h.hub, conn)

	// 使用hub的Register通道注册客户端
	h.hub.Register <- client

	// 启动goroutine处理读写
	go client.WritePump()
	go client.ReadPump()
}

// BroadcastNovelUpdate 广播小说更新消息
func (h *WebSocketHandler) BroadcastNovelUpdate(novelID string, title string) {
	update := NovelUpdate{
		NovelID:     novelID,
		Title:       title,
		UpdateType:  "new_chapter",
		Description: "新章节已更新",
	}

	msg := WSMessage{
		Type: "novel_update",
		Data: update,
		Time: time.Now(),
	}

	msgBytes, err := json.Marshal(msg)
	if err != nil {
		return
	}

	h.hub.Broadcast <- msgBytes
}

// BroadcastSystemMessage 广播系统消息
func (h *WebSocketHandler) BroadcastSystemMessage(messageType string, content string) {
	msg := WSMessage{
		Type: "system",
		Data: map[string]string{
			"type":    messageType,
			"content": content,
		},
		Time: time.Now(),
	}

	msgBytes, err := json.Marshal(msg)
	if err != nil {
		return
	}

	h.hub.Broadcast <- msgBytes
}

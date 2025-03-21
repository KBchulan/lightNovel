// ****************************************************************************
// @file       hub.go
// @brief      WebSocket Hub
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package websocket

import (
	"sync"
	"time"
)

// Hub 维护活动的WebSocket连接集合
type Hub struct {
	// 注册的客户端
	clients map[*Client]bool

	// 广播消息通道
	Broadcast chan []byte

	// 注册请求
	Register chan *Client

	// 注销请求
	Unregister chan *Client

	// 互斥锁保护clients map
	mu sync.RWMutex

	// 统计信息
	messagesSent int64
	startTime    time.Time
}

// NewHub 创建一个新的Hub
func NewHub() *Hub {
	return &Hub{
		Broadcast:  make(chan []byte),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
		clients:    make(map[*Client]bool),
		startTime:  time.Now(),
	}
}

// Run 启动Hub的消息处理
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()

		case client := <-h.Unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}
			h.mu.Unlock()

		case message := <-h.Broadcast:
			h.mu.RLock()
			for client := range h.clients {
				if client.IsAlive() {
					select {
					case client.send <- message:
						h.messagesSent++
					default:
						h.mu.RUnlock()
						h.mu.Lock()
						delete(h.clients, client)
						close(client.send)
						h.mu.Unlock()
						h.mu.RLock()
					}
				} else {
					h.mu.RUnlock()
					h.mu.Lock()
					delete(h.clients, client)
					close(client.send)
					h.mu.Unlock()
					h.mu.RLock()
				}
			}
			h.mu.RUnlock()
		}
	}
}

// GetActiveConnections 获取当前活动连接数
func (h *Hub) GetActiveConnections() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// GetMessagesSent 获取已发送消息数量
func (h *Hub) GetMessagesSent() int64 {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return h.messagesSent
}

// GetStartTime 获取服务启动时间
func (h *Hub) GetStartTime() time.Time {
	return h.startTime
}

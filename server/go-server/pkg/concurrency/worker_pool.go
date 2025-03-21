// ****************************************************************************
//
// @file       worker_pool.go
// @brief      工作池
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package concurrency

import (
	"context"
	"sync"
)

// Task 表示一个任务
type Task interface {
	Execute(ctx context.Context) error
}

// Result 表示任务执行结果
type Result struct {
	Data interface{}
	Err  error
}

// WorkerPool 工作池
type WorkerPool struct {
	maxWorkers int
	taskQueue  chan Task
	results    chan Result
	wg         sync.WaitGroup
	ctx        context.Context
	cancel     context.CancelFunc
}

// NewWorkerPool 创建新的工作池
func NewWorkerPool(maxWorkers int) *WorkerPool {
	ctx, cancel := context.WithCancel(context.Background())
	return &WorkerPool{
		maxWorkers: maxWorkers,
		taskQueue:  make(chan Task, maxWorkers*2),
		results:    make(chan Result, maxWorkers*2),
		ctx:        ctx,
		cancel:     cancel,
	}
}

// Start 启动工作池
func (p *WorkerPool) Start(ctx context.Context) {
	for i := 0; i < p.maxWorkers; i++ {
		p.wg.Add(1)
		go p.worker(ctx)
	}
}

// Submit 提交任务
func (p *WorkerPool) Submit(task Task) {
	select {
	case p.taskQueue <- task:
	case <-p.ctx.Done():
	}
}

// Results 获取结果通道
func (p *WorkerPool) Results() <-chan Result {
	return p.results
}

// Stop 停止工作池
func (p *WorkerPool) Stop() {
	p.cancel()
	close(p.taskQueue)
	p.wg.Wait()
	close(p.results)
}

// worker 工作协程
func (p *WorkerPool) worker(ctx context.Context) {
	defer p.wg.Done()

	for {
		select {
		case task, ok := <-p.taskQueue:
			if !ok {
				return
			}
			err := task.Execute(ctx)
			select {
			case p.results <- Result{Err: err}:
			case <-ctx.Done():
				return
			}
		case <-ctx.Done():
			return
		}
	}
}

// BatchProcessor 批处理器
type BatchProcessor struct {
	batchSize  int
	maxWorkers int
	tasks      []Task
	results    []Result
	mu         sync.Mutex
}

// NewBatchProcessor 创建新的批处理器
func NewBatchProcessor(batchSize, maxWorkers int) *BatchProcessor {
	return &BatchProcessor{
		batchSize:  batchSize,
		maxWorkers: maxWorkers,
		tasks:      make([]Task, 0),
		results:    make([]Result, 0),
	}
}

// AddTask 添加任务
func (p *BatchProcessor) AddTask(task Task) {
	p.mu.Lock()
	p.tasks = append(p.tasks, task)
	p.mu.Unlock()
}

// Process 处理所有任务
func (p *BatchProcessor) Process(ctx context.Context) []Result {
	if len(p.tasks) == 0 {
		return nil
	}

	// 创建工作池
	pool := NewWorkerPool(p.maxWorkers)
	pool.Start(ctx)

	// 提交任务
	go func() {
		for _, task := range p.tasks {
			pool.Submit(task)
		}
	}()

	// 收集结果
	go func() {
		for result := range pool.Results() {
			p.mu.Lock()
			p.results = append(p.results, result)
			p.mu.Unlock()
		}
	}()

	// 等待所有任务完成
	pool.Stop()

	return p.results
}

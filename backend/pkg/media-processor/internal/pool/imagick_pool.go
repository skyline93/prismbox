package pool

import (
	"context"
	"time"

	"gopkg.in/gographics/imagick.v3/imagick"
)

// ImagickPool 提供针对 MagickWand 的资源池封装。
type ImagickPool struct {
	base *Pool[*imagick.MagickWand]
}

// NewImagickPool 构造资源池。
func NewImagickPool(maxSize int) *ImagickPool {
	cfg := Config{
		MaxSize:     maxSize,
		IdleTimeout: 2 * time.Minute,
	}
	return &ImagickPool{
		base: New(cfg, func() (*imagick.MagickWand, error) {
			return imagick.NewMagickWand(), nil
		}, func(wand *imagick.MagickWand) {
			if wand != nil {
				wand.Clear()
				wand.Destroy()
			}
		}),
	}
}

// Get 获取 MagickWand。
func (p *ImagickPool) Get(ctx context.Context) (*imagick.MagickWand, error) {
	return p.base.Get(ctx)
}

// Put 归还 MagickWand。
func (p *ImagickPool) Put(wand *imagick.MagickWand) {
	if wand == nil {
		return
	}
	wand.Clear()
	p.base.Put(wand)
}

// Close 关闭资源池。
func (p *ImagickPool) Close() {
	p.base.Close()
}

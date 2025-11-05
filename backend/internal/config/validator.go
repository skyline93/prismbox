package config

import (
	"fmt"
)

// Validator 配置验证器
type Validator struct{}

// NewValidator 创建配置验证器
func NewValidator() *Validator {
	return &Validator{}
}

// Validate 验证配置
func (v *Validator) Validate(cfg *Config) error {
	if cfg == nil {
		return fmt.Errorf("config is nil")
	}

	// 验证各个模块配置
	if err := cfg.Validate(); err != nil {
		return err
	}

	return nil
}

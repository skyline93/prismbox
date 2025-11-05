package modules

// AuthConfig 认证配置
type AuthConfig struct {
	JWTSecret string `yaml:"jwt_secret"`
	// 其他认证配置字段
}

// Validate 验证认证配置
func (c *AuthConfig) Validate() error {
	return nil
}

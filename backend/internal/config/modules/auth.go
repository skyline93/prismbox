package modules

import "fmt"

// AuthConfig 认证配置
type AuthConfig struct {
	JWTSecret             string   `yaml:"jwt_secret"`
	AccessTokenExpiresIn  Duration `yaml:"access_token_expires_in"`
	RefreshTokenExpiresIn Duration `yaml:"refresh_token_expires_in"`
	AppleAppBundleID      string   `yaml:"apple_app_bundle_id"`
	AvatarSavePath        string   `yaml:"avatar_save_path"`
	MaxAvatarSize         Size     `yaml:"max_avatar_size"`
	URLSignerSecret       string   `yaml:"url_signer_secret"`
	SignedURLLoadTTL      Duration `yaml:"signed_url_load_ttl"`
}

// Validate 验证认证配置
func (c *AuthConfig) Validate() error {
	if c.JWTSecret == "" {
		return fmt.Errorf("auth.jwt_secret is required")
	}
	if c.AccessTokenExpiresIn.Duration() <= 0 {
		return fmt.Errorf("auth.access_token_expires_in must be greater than 0")
	}
	if c.RefreshTokenExpiresIn.Duration() <= 0 {
		return fmt.Errorf("auth.refresh_token_expires_in must be greater than 0")
	}
	if c.AvatarSavePath == "" {
		return fmt.Errorf("auth.avatar_save_path is required")
	}
	if c.MaxAvatarSize.Int64() <= 0 {
		return fmt.Errorf("auth.max_avatar_size must be greater than 0")
	}
	if c.URLSignerSecret == "" {
		return fmt.Errorf("auth.url_signer_secret is required")
	}
	if c.SignedURLLoadTTL.Duration() <= 0 {
		return fmt.Errorf("auth.signed_url_load_ttl must be greater than 0")
	}
	return nil
}

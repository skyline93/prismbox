package auth

import (
	"github.com/album/backend/internal/config/types"
)

// Config 认证配置
type Config struct {
	JWTSecret             string           `yaml:"jwt_secret"`
	AccessTokenExpiresIn  types.Duration `yaml:"access_token_expires_in"`
	RefreshTokenExpiresIn types.Duration `yaml:"refresh_token_expires_in"`
	AppleAppBundleID      string           `yaml:"apple_app_bundle_id"`
	AvatarSavePath        string           `yaml:"avatar_save_path"`
	MaxAvatarSize         types.Size     `yaml:"max_avatar_size"`
	URLSignerSecret       string           `yaml:"url_signer_secret"`
	SignedURLLoadTTL      types.Duration `yaml:"signed_url_load_ttl"`
}

package version

import (
	"encoding/json"
	"fmt"
	"runtime"
)

// 编译时注入的版本信息，提供默认值便于开发环境运行。
var (
	Version   = "dev"
	BuildTime = "unknown"
	GitCommit = "unknown"
	GitBranch = "unknown"
)

// Info 表示应用版本信息。
type Info struct {
	Version   string `json:"version"`
	BuildTime string `json:"build_time"`
	GitCommit string `json:"git_commit"`
	GitBranch string `json:"git_branch"`
	GoVersion string `json:"go_version"`
	Platform  string `json:"platform"`
}

// Get 返回当前版本信息。
func Get() Info {
	return Info{
		Version:   Version,
		BuildTime: BuildTime,
		GitCommit: GitCommit,
		GitBranch: GitBranch,
		GoVersion: runtime.Version(),
		Platform:  fmt.Sprintf("%s/%s", runtime.GOOS, runtime.GOARCH),
	}
}

// MarshalJSON 返回 JSON 格式的版本信息。
func MarshalJSON() ([]byte, error) {
	info := Get()
	return json.MarshalIndent(info, "", "  ")
}

package utils

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/gabriel-vasile/mimetype"
)

// DetectFileFormat 使用 mimetype 识别文件类型。
func DetectFileFormat(path string) (mime string, extension string, err error) {
	f, err := os.Open(path)
	if err != nil {
		return "", "", err
	}
	defer f.Close()

	mtype, err := mimetype.DetectReader(f)
	if err != nil {
		return "", "", err
	}

	return mtype.String(), strings.TrimPrefix(mtype.Extension(), "."), nil
}

// NormalizeExt 返回标准化的扩展名（不含点）。
func NormalizeExt(path string) string {
	return strings.TrimPrefix(strings.ToLower(filepath.Ext(path)), ".")
}

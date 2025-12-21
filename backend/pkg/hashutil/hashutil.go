package hashutil

import (
	"crypto/md5"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"hash"
	"io"
	"os"
)

// HashAlgorithm 哈希算法类型
type HashAlgorithm int

const (
	// HashMD5 MD5 算法（默认，快速，适用于非安全场景）
	HashMD5 HashAlgorithm = iota
	// HashSHA256 SHA256 算法（推荐用于安全场景）
	HashSHA256
)

// String 返回算法名称
func (a HashAlgorithm) String() string {
	switch a {
	case HashMD5:
		return "MD5"
	case HashSHA256:
		return "SHA256"
	default:
		return "MD5"
	}
}

// FileHashUtil 文件哈希计算工具类
//
// 提供统一的文件哈希计算功能，包括：
// - 支持多种哈希算法（MD5、SHA256）
// - 流式读取（避免内存溢出）
// - 文件大小检查
type FileHashUtil struct {
	algorithm HashAlgorithm
}

// NewFileHashUtil 创建文件哈希工具实例
//
// **参数**：
// - [algorithm] - 哈希算法类型（默认：MD5）
//
// **返回**：FileHashUtil 实例
func NewFileHashUtil(algorithm HashAlgorithm) *FileHashUtil {
	return &FileHashUtil{
		algorithm: algorithm,
	}
}

// CalculateFileHash 计算文件哈希值（从文件路径）
//
// **性能优化**：
// - 使用流式读取替代一次性读取整个文件
// - 对于大文件（如视频），流式读取可以显著降低内存占用
// - 避免 Out of Memory 错误
//
// **参数**：
// - [filePath] - 文件路径
//
// **返回**：哈希值（十六进制字符串）和错误
//
// **异常**：
// - 如果文件不存在或无法读取，会返回错误
// - 如果文件为空，会返回错误
//
// **示例**：
// ```go
// // 使用默认 MD5 算法
// util := hashutil.NewFileHashUtil(hashutil.HashMD5)
// hash, err := util.CalculateFileHash("/path/to/file")
//
// // 使用 SHA256 算法
// util := hashutil.NewFileHashUtil(hashutil.HashSHA256)
// hash, err := util.CalculateFileHash("/path/to/file")
// ```
func (u *FileHashUtil) CalculateFileHash(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", fmt.Errorf("open file: %w", err)
	}
	defer file.Close()

	// 检查文件大小
	fileInfo, err := file.Stat()
	if err != nil {
		return "", fmt.Errorf("get file info: %w", err)
	}
	if fileInfo.Size() == 0 {
		return "", fmt.Errorf("file is empty: %s", filePath)
	}

	return u.CalculateHash(file)
}

// CalculateHash 计算数据流的哈希值（从 io.Reader）
//
// **参数**：
// - [reader] - 数据流
//
// **返回**：哈希值（十六进制字符串）和错误
//
// **示例**：
// ```go
// util := hashutil.NewFileHashUtil(hashutil.HashMD5)
// hash, err := util.CalculateHash(file)
// ```
func (u *FileHashUtil) CalculateHash(reader io.Reader) (string, error) {
	hasher := u.getHasher()
	if _, err := io.Copy(hasher, reader); err != nil {
		return "", fmt.Errorf("calculate hash: %w", err)
	}
	return hex.EncodeToString(hasher.Sum(nil)), nil
}

// getHasher 根据算法类型获取对应的 Hash 实例
func (u *FileHashUtil) getHasher() hash.Hash {
	return GetHasher(u.algorithm)
}

// GetHasher 根据算法类型获取对应的 Hash 实例（用于 HMAC 等场景）
//
// **参数**：
// - [algorithm] - 哈希算法类型
//
// **返回**：对应的 Hash 实例
func GetHasher(algorithm HashAlgorithm) hash.Hash {
	switch algorithm {
	case HashMD5:
		return md5.New()
	case HashSHA256:
		return sha256.New()
	default:
		return md5.New()
	}
}

// GetHasherFunc 根据算法类型获取对应的 Hash 构造函数（用于 HMAC 等场景）
//
// **参数**：
// - [algorithm] - 哈希算法类型
//
// **返回**：返回 Hash 实例的函数
//
// **示例**：
// ```go
// // 用于 HMAC 签名
// hasherFunc := hashutil.GetHasherFunc(hashutil.HashSHA256)
// hmac := hmac.New(hasherFunc, secretKey)
// ```
func GetHasherFunc(algorithm HashAlgorithm) func() hash.Hash {
	switch algorithm {
	case HashMD5:
		return md5.New
	case HashSHA256:
		return sha256.New
	default:
		return md5.New
	}
}

// CalculateFileHashMD5 计算文件的 MD5 哈希值（便捷方法）
//
// **参数**：
// - [filePath] - 文件路径
//
// **返回**：MD5 哈希值（十六进制字符串）和错误
func CalculateFileHashMD5(filePath string) (string, error) {
	util := NewFileHashUtil(HashMD5)
	return util.CalculateFileHash(filePath)
}

// CalculateFileHashSHA256 计算文件的 SHA256 哈希值（便捷方法）
//
// **参数**：
// - [filePath] - 文件路径
//
// **返回**：SHA256 哈希值（十六进制字符串）和错误
func CalculateFileHashSHA256(filePath string) (string, error) {
	util := NewFileHashUtil(HashSHA256)
	return util.CalculateFileHash(filePath)
}

// CalculateHashMD5 计算数据流的 MD5 哈希值（便捷方法）
//
// **参数**：
// - [reader] - 数据流
//
// **返回**：MD5 哈希值（十六进制字符串）和错误
func CalculateHashMD5(reader io.Reader) (string, error) {
	util := NewFileHashUtil(HashMD5)
	return util.CalculateHash(reader)
}

// CalculateHashSHA256 计算数据流的 SHA256 哈希值（便捷方法）
//
// **参数**：
// - [reader] - 数据流
//
// **返回**：SHA256 哈希值（十六进制字符串）和错误
func CalculateHashSHA256(reader io.Reader) (string, error) {
	util := NewFileHashUtil(HashSHA256)
	return util.CalculateHash(reader)
}

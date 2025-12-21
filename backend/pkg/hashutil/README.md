# HashUtil - 统一哈希计算工具包

提供统一的文件哈希计算功能，支持多种哈希算法（MD5、SHA256）。

## 特性

- ✅ 支持多种哈希算法（MD5、SHA256）
- ✅ 流式读取（避免内存溢出）
- ✅ 文件大小检查
- ✅ 统一的 API 接口
- ✅ 便捷的静态方法

## 使用示例

### 方式一：使用实例方法（推荐用于需要切换算法的场景）

```go
import "github.com/album/backend/pkg/hashutil"

// 使用 MD5 算法（默认）
util := hashutil.NewFileHashUtil(hashutil.HashMD5)
hash, err := util.CalculateFileHash("/path/to/file")
if err != nil {
    // 处理错误
}

// 使用 SHA256 算法
utilSHA256 := hashutil.NewFileHashUtil(hashutil.HashSHA256)
hash, err := utilSHA256.CalculateFileHash("/path/to/file")

// 从数据流计算哈希
file, _ := os.Open("/path/to/file")
defer file.Close()
hash, err := util.CalculateHash(file)
```

### 方式二：使用便捷的静态方法（推荐用于简单场景）

```go
import "github.com/album/backend/pkg/hashutil"

// 计算文件的 MD5 哈希值
hash, err := hashutil.CalculateFileHashMD5("/path/to/file")

// 计算文件的 SHA256 哈希值
hash, err := hashutil.CalculateFileHashSHA256("/path/to/file")

// 从数据流计算 MD5 哈希值
file, _ := os.Open("/path/to/file")
defer file.Close()
hash, err := hashutil.CalculateHashMD5(file)
```

## API 参考

### 类型

- `HashAlgorithm`: 哈希算法类型枚举
  - `HashMD5`: MD5 算法（默认，快速，适用于非安全场景）
  - `HashSHA256`: SHA256 算法（推荐用于安全场景）

### 主要方法

#### `NewFileHashUtil(algorithm HashAlgorithm) *FileHashUtil`

创建文件哈希工具实例。

#### `CalculateFileHash(filePath string) (string, error)`

计算文件的哈希值（从文件路径）。

#### `CalculateHash(reader io.Reader) (string, error)`

计算数据流的哈希值（从 io.Reader）。

#### `CalculateFileHashMD5(filePath string) (string, error)`

便捷方法：计算文件的 MD5 哈希值。

#### `CalculateFileHashSHA256(filePath string) (string, error)`

便捷方法：计算文件的 SHA256 哈希值。

#### `CalculateHashMD5(reader io.Reader) (string, error)`

便捷方法：计算数据流的 MD5 哈希值。

#### `CalculateHashSHA256(reader io.Reader) (string, error)`

便捷方法：计算数据流的 SHA256 哈希值。

#### `GetHasher(algorithm HashAlgorithm) hash.Hash`

根据算法类型获取对应的 Hash 实例（用于直接使用 Hash 接口的场景）。

#### `GetHasherFunc(algorithm HashAlgorithm) func() hash.Hash`

根据算法类型获取对应的 Hash 构造函数（用于 HMAC 等需要函数参数的场景）。

**示例（HMAC 签名）**：
```go
import (
    "crypto/hmac"
    "github.com/album/backend/pkg/hashutil"
)

// 用于 HMAC-SHA256 签名
hasherFunc := hashutil.GetHasherFunc(hashutil.HashSHA256)
hmac := hmac.New(hasherFunc, secretKey)
hmac.Write([]byte(data))
signature := hex.EncodeToString(hmac.Sum(nil))
```

## 性能优化

- **流式读取**：使用 `io.Copy` 进行流式读取，避免一次性加载整个文件到内存
- **文件大小检查**：自动检查文件是否为空，避免无效计算
- **内存友好**：对于大文件（如视频），流式读取可以显著降低内存占用

## 默认算法

默认使用 **MD5** 算法，因为：
- 计算速度快
- 哈希值长度短（32 字符）
- 适合用于文件去重和比对场景

如果需要更高的安全性，可以使用 SHA256 算法。

## 注意事项

1. 文件必须存在且可读
2. 空文件会返回错误
3. 大文件使用流式读取，不会导致内存溢出
4. 哈希值以十六进制字符串形式返回


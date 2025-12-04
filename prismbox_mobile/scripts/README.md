# 脚本说明

## generate_openapi_client.sh

生成OpenAPI客户端代码的脚本。

### 使用方法

```bash
cd prismbox_mobile
chmod +x scripts/generate_openapi_client.sh
./scripts/generate_openapi_client.sh
```

### 前置要求

1. 安装openapi-generator:
   ```bash
   npm install -g @openapitools/openapi-generator-cli
   ```

2. 确保后端swagger文件存在:
   - `../../backend/docs/swagger/swagger.yaml`

### 输出

生成的客户端代码将输出到:
- `lib/infrastructure/api/generated/`

### 后续步骤

生成完成后：
1. 运行 `flutter pub get` 安装依赖
2. 更新 `lib/infrastructure/api/generated/openapi_client_wrapper.dart`
3. 在 `ApiService` 中集成生成的客户端


# 脚本说明

本目录包含项目相关的脚本文件。

## 当前状态

项目已改为使用 Dio 方式实现 API 对接，不再需要生成 OpenAPI 客户端。

所有 API 调用直接使用 Dio，通过拦截器实现认证、响应处理、重试、错误处理等功能。

详细说明请参考：
- [API对接模块使用指南](../lib/infrastructure/api/DIO_USAGE.md)
- [API对接模块整改总结](../lib/infrastructure/api/DIO_REFACTOR_SUMMARY.md)


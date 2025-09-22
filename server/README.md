```bash
swag init -g main.go 
```

```bash
docker run -d \
    --name postgres \
    --restart always \
    -e POSTGRES_USER=mobile \
    -e POSTGRES_PASSWORD=mobile \
    -e POSTGRES_DB=mobile \
    -p 15422:5432 \
    -v /etc/localtime:/etc/localtime:ro \
    -v /etc/timezone:/etc/timezone:ro \
    postgres:14
```

### 数据同步状态矩阵

| 本地状态 (Local State) | `created` | `updated` | `updated_deleted` (软删除) | `deleted` (硬删除) |
| :--- | :--- | :--- | :--- | :--- |
| **localOnly_active** | synced_active | synced_active | localOnly_active | localOnly_active |
| **synced_active** | synced_active | synced_active | localOnly_active | localOnly_active |
| **cloudOnly_active** | cloudOnly_active | cloudOnly_active | x | x |
| **localOnly_trashed** | localOnly_trashed | localOnly_trashed | localOnly_trashed | localOnly_trashed |
| **synced_trashed** | synced_trashed | synced_trashed | synced_trashed | localOnly_trashed |
| **cloudOnly_trashed** | cloudOnly_trashed | cloudOnly_trashed | cloudOnly_trashed | x |

*   **x**: 表示该操作应被忽略或导致本地记录被删除（通常仅限于 `cloudOnly` 状态）。

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

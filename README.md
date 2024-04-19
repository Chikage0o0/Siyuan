## 思源笔记 Docker 部署

提供了额外的PUID、PGID以及UMASK环境变量，以便与使用宿主机用户的UID和GID进行文件操作。

```shell
docker run -d \
  --name=noted \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=022 \
  -e TZ=Asia/Shanghai \
  -e WORK_SPACE=/siyuan \
  -e ACCESS_TOKEN=your_access_token \
  -p 6806:6806 \
  -v /path/to/config:/siyuan/conf \
  -v /path/to/data:/siyuan/data \
  --restart unless-stopped \
  ghcr.io/chikage0o0/siyuan:latest
```
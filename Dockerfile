FROM node:21 as NODE_BUILD
WORKDIR /go/src/github.com/siyuan-note/
ENV VERSION=v3.0.10
RUN git clone --depth=1 https://github.com/appdev/siyuan-unlock.git -b ${VERSION} siyuan
WORKDIR /go/src/github.com/siyuan-note/siyuan/
RUN cd app && npm install -g pnpm@8.14.1 && pnpm install && pnpm run build


FROM golang:alpine as GO_BUILD
WORKDIR /go/src/github.com/siyuan-note/siyuan/
COPY --from=NODE_BUILD /go/src/github.com/siyuan-note/siyuan/ /go/src/github.com/siyuan-note/siyuan/
ENV GO111MODULE=on
ENV CGO_ENABLED=1
RUN apk add --no-cache gcc musl-dev && \
    cd kernel && go build --tags fts5 -v -ldflags "-s -w -X github.com/siyuan-note/siyuan/kernel/util.Mode=prod" && \
    mkdir /opt/siyuan/ && \
    mv /go/src/github.com/siyuan-note/siyuan/app/appearance/ /opt/siyuan/ && \
    mv /go/src/github.com/siyuan-note/siyuan/app/stage/ /opt/siyuan/ && \
    mv /go/src/github.com/siyuan-note/siyuan/app/guide/ /opt/siyuan/ && \
    mv /go/src/github.com/siyuan-note/siyuan/app/changelogs/ /opt/siyuan/ && \
    mv /go/src/github.com/siyuan-note/siyuan/kernel/kernel /opt/siyuan/ && \
    find /opt/siyuan/ -name .git | xargs rm -rf


FROM alpine:3

# 赋予脚本执行权限
COPY entrypoint.sh /usr/bin
RUN chmod 755 /usr/bin/entrypoint.sh
WORKDIR /opt/siyuan/
COPY --from=GO_BUILD /opt/siyuan/ /opt/siyuan/

# 定义环境变量
ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8
ENV LANGUAGE=zh_CN.UTF-8
ENV WORK_SPACE=/home/siyuan
ENV RUN_IN_CONTAINER=true

EXPOSE 6806

# 设置时区为上海
RUN sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories && \ 
    apk add -U --no-cache \
    ca-certificates \
    bash \
    curl \
    su-exec \
    tzdata && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone && \
    apk del tzdata

# 添加用户
RUN addgroup -S -g 1000 siyuan && \
    adduser -S -H -D -h /home/siyuan -s /bin/bash -u 1000 -G siyuan siyuan && \
    echo "siyuan:*" | chpasswd -e
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
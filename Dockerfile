FROM node:21 as NODE_BUILD
WORKDIR /go/src/github.com/siyuan-note/
ENV VERSION=v3.1.20
RUN git clone --depth=1 https://github.com/siyuan-note/siyuan.git -b ${VERSION} siyuan
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

# 拷贝可执行文件
WORKDIR /opt/siyuan/
COPY entrypoint.sh /usr/bin
COPY --from=GO_BUILD /opt/siyuan/ /opt/siyuan/

# 定义环境变量
ENV TZ=Asia/Shanghai
ENV RUN_IN_CONTAINER=true
EXPOSE 6806


# 添加用户&& 设置时区
RUN addgroup --gid 1000 siyuan && \
    adduser --uid 1000 --ingroup siyuan --disabled-password siyuan && \
    apk add --no-cache ca-certificates su-exec tzdata && \
    chown -R siyuan:siyuan /opt/siyuan/ && \
    chmod 755 /usr/bin/entrypoint.sh

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
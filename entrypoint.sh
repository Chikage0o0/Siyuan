#!/bin/sh

if [ -z "${PGID}" ]; then
  PGID="`id -g siyuan`"
fi

if [ -z "${PUID}" ]; then
  PUID="`id -u siyuan`"
fi

if [ -z "${WORK_SPACE}" ]; then
    exit /opt/siyuan/workspace
fi

if [ -z "${SIYUAN_OPTIONS}" ]; then
    SIYUAN_OPTIONS=""
fi

if [ -z "${ACCESS_TOKEN}" ]; then
    ACCESS_TOKEN="123456"
fi

echo "=================== 启动参数 ==================="
echo "USER_GID = ${PGID}"
echo "USER_UID = ${PUID}"
echo "SIYUAN_OPTIONS = ${SIYUAN_OPTIONS}"
echo "WORK_SPACE = ${WORK_SPACE}"
echo "ACCESS_TOKEN = ${ACCESS_TOKEN}"
echo "==============================================="


# 更新用户GID?
if [ -n "${PGID}" ] && [ "${PGID}" != "`id -g siyuan`" ]; then
    echo "更新用户GID..."
    sed -i -e "s/^siyuan:\([^:]*\):[0-9]*/siyuan:\1:${PGID}/" /etc/group
    sed -i -e "s/^siyuan:\([^:]*\):\([0-9]*\):[0-9]*/siyuan:\1:\2:${PGID}/" /etc/passwd
fi

# 更新用户UID?
if [ -n "${PUID}" ] && [ "${PUID}" != "`id -u siyuan`" ]; then
    echo "更新用户UID..."
    sed -i -e "s/^siyuan:\([^:]*\):[0-9]*:\([0-9]*\)/siyuan:\1:${PUID}:\2/" /etc/passwd
fi

# 创建工作空间
if [ ! -d "${WORK_SPACE}" ];then
    echo "生成工作空间目录 ${WORK_SPACE} ..."
    mkdir -p ${WORK_SPACE}
fi
chown -R siyuan:siyuan ${WORK_SPACE};

# 文件夹不存在则创建，不知道为啥，反正就得创建，不创建启动会报错
if [ ! -d "/home/siyuan" ];then
    # echo "生成 /home/siyuan 目录..."
    mkdir -p /home/siyuan
fi
chown -R siyuan:siyuan /home/siyuan

# 启动思源笔记内核
if [ -n "${SIYUAN_OPTIONS}" ]; then
    echo "即将启动带参数的笔记内核..."
    exec su-exec siyuan /opt/siyuan/kernel ${SIYUAN_OPTIONS} --workspace=${WORK_SPACE} --access-token=${ACCESS_TOKEN}
else
    echo "即将启动笔记内核..."
    exec su-exec siyuan /opt/siyuan/kernel --workspace=${WORK_SPACE} --accessAuthCode=${ACCESS_TOKEN}
fi
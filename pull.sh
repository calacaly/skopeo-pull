#!/bin/bash

# 检查是否提供了参数
if [ -z "$1" ]; then
  echo "用法: $0 <镜像地址:tag>"
  echo "示例: $0 ghcr.io/cross-rs/riscv64gc-unknown-linux-gnu:0.2.5"
  exit 1
fi

# 提取镜像地址和 tag
IMAGE_AND_TAG="$1"

# 提取镜像仓库地址（去掉 :tag 部分）
IMAGE_REPO="${IMAGE_AND_TAG%%:*}"

# 提取 tag（如果无 tag，默认 latest）
IMAGE_TAG="${IMAGE_AND_TAG##*:}"
if [[ "$IMAGE_TAG" == "$IMAGE_REPO" ]]; then
  IMAGE_TAG="latest"
fi

# 生成 tar 文件名（替换 / 为 _，避免文件路径问题）
TAR_FILE_NAME="${IMAGE_REPO//\//-}_$IMAGE_TAG.tar"

# 使用 skopeo 拉取镜像并保存为 tar 文件
echo "🔍 正在使用 skopeo 拉取镜像: $IMAGE_AND_TAG"
skopeo copy \
  docker://$IMAGE_AND_TAG \
  docker-archive:$TAR_FILE_NAME:$IMAGE_AND_TAG

if [ $? -eq 0 ]; then
  echo "📦 镜像已成功保存为 $TAR_FILE_NAME"
else
  echo "❌ skopeo 拉取镜像失败，请检查网络或权限设置"
  exit 1
fi

# 使用 docker load 加载镜像
echo "📥 正在加载镜像到 Docker..."
docker load -i "$TAR_FILE_NAME"

if [ $? -eq 0 ]; then
  echo "✅ 镜像已成功加载到 Docker"
else
  echo "❌ 加载镜像到 Docker 失败"
  exit 1
fi

# 清理临时文件（可选）
rm -f "$TAR_FILE_NAME"
echo "🗑️ 临时文件已清理"

# 显示加载成功的镜像
echo ""
echo "📋 当前本地镜像列表："
docker images | grep "${IMAGE_REPO##*/}"

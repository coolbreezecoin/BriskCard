#!/bin/bash
set -e

# 确保数据目录存在并有正确的权限
DATA_DIR="/app/data"
DB_FILE="${DATA_DIR}/cards.db"
APPUSER_UID=${APPUSER_UID:-1000}
APPUSER_GID=${APPUSER_GID:-1000}

echo "🔧 初始化数据目录: $DATA_DIR"

# 创建数据目录（如果不存在）
if [ ! -d "$DATA_DIR" ]; then
    echo "创建数据目录: $DATA_DIR"
    mkdir -p "$DATA_DIR"
fi

# 尝试设置数据目录的所有者和权限
# 对于 volume 挂载，可能无法修改权限，但我们会尝试
echo "设置数据目录权限..."
if chown -R ${APPUSER_UID}:${APPUSER_GID} "$DATA_DIR" 2>/dev/null; then
    echo "✅ 已设置数据目录所有者"
else
    echo "⚠️  无法更改数据目录所有者（可能是 volume 挂载）"
fi

if chmod 700 "$DATA_DIR" 2>/dev/null; then
    echo "✅ 已设置数据目录权限"
else
    echo "⚠️  无法设置数据目录权限（可能是 volume 挂载）"
fi

# 如果数据库文件已存在，设置文件权限
if [ -f "$DB_FILE" ]; then
    echo "设置数据库文件权限..."
    chown ${APPUSER_UID}:${APPUSER_GID} "$DB_FILE" 2>/dev/null || true
    chmod 600 "$DB_FILE" 2>/dev/null || true
fi

# 验证权限（以 appuser 身份测试）
echo "验证权限..."
if gosu appuser test -w "$DATA_DIR" 2>/dev/null; then
    echo "✅ 数据目录权限检查通过"
else
    echo "❌ 错误: 数据目录没有写权限"
    echo ""
    echo "请执行以下命令修复权限："
    echo "  docker-compose down"
    echo "  chmod 700 data"
    echo "  chown -R ${APPUSER_UID}:${APPUSER_GID} data"
    if [ -f "$DB_FILE" ]; then
        echo "  chmod 600 data/cards.db"
    fi
    echo "  docker-compose up -d"
    echo ""
    exit 1
fi

# 切换到 appuser 并执行传入的命令
echo "🚀 启动应用..."
exec gosu appuser "$@"


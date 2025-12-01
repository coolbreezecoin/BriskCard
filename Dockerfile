# 使用 Python 3.12 官方镜像
FROM python:3.12-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY app/ ./app/
COPY init_db.py .

# 复制启动脚本
COPY docker-entrypoint.sh /docker-entrypoint.sh

# 设置非 root 用户（安全最佳实践）
RUN useradd -m -u 1000 appuser

# 创建数据目录（用于持久化数据库）并设置权限
RUN mkdir -p /app/data && \
    chmod 700 /app/data && \
    chown -R appuser:appuser /app && \
    chmod +x /docker-entrypoint.sh


# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# 设置入口点
ENTRYPOINT ["/docker-entrypoint.sh"]

# 启动命令
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]


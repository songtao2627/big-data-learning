# 基于现有的Jupyter PySpark Notebook镜像
FROM jupyter/pyspark-notebook:python-3.11

# 切换到root用户以安装包
USER root

# 配置pip使用国内镜像源
RUN echo "[global]" > /etc/pip.conf \
    && echo "index-url = https://pypi.tuna.tsinghua.edu.cn/simple" >> /etc/pip.conf \
    && echo "trusted-host = pypi.tuna.tsinghua.edu.cn" >> /etc/pip.conf \
    && echo "timeout = 120" >> /etc/pip.conf

# 添加pip镜像源切换脚本，方便用户根据需要切换
RUN echo '#!/bin/bash' > /usr/local/bin/switch_pip_mirror.sh \
    && echo 'if [ "$1" = "tsinghua" ]; then' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    echo "[global]" > /etc/pip.conf' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    echo "index-url = https://pypi.tuna.tsinghua.edu.cn/simple" >> /etc/pip.conf' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    echo "trusted-host = pypi.tuna.tsinghua.edu.cn" >> /etc/pip.conf' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo 'elif [ "$1" = "aliyun" ]; then' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    echo "[global]" > /etc/pip.conf' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    echo "index-url = https://mirrors.aliyun.com/pypi/simple/" >> /etc/pip.conf' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    echo "trusted-host = mirrors.aliyun.com" >> /etc/pip.conf' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo 'elif [ "$1" = "douban" ]; then' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    echo "[global]" > /etc/pip.conf' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    echo "index-url = https://pypi.douban.com/simple/" >> /etc/pip.conf' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    echo "trusted-host = pypi.douban.com" >> /etc/pip.conf' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo 'else' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    echo "Usage: switch_pip_mirror.sh [tsinghua|aliyun|douban]"' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo '    exit 1' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo 'fi' >> /usr/local/bin/switch_pip_mirror.sh \
    && echo 'echo "Switched to $1 pip mirror"' >> /usr/local/bin/switch_pip_mirror.sh \
    && chmod +x /usr/local/bin/switch_pip_mirror.sh

# 卸载现有PySpark并安装与Spark集群兼容的版本
RUN pip uninstall pyspark -y || echo "无法卸载pyspark" \
    && pip install pyspark==3.5.0 py4j==0.10.9.7 \
    && rm -rf /usr/local/spark/python/pyspark \
    && cp -r /opt/conda/lib/python3.11/site-packages/pyspark /usr/local/spark/python/ \
    && echo "__version__: str = '3.5.0'" > /usr/local/spark/python/pyspark/version.py \
    && chmod -R 755 /usr/local/spark/python/pyspark

# 设置PYTHONPATH，确保使用正确版本的PySpark
ENV PYTHONPATH=/opt/conda/lib/python3.11/site-packages:/usr/local/spark/python:/home/jovyan/work

# 确保工作目录权限正确
RUN chown -R jovyan:users /home/jovyan

# 切换回jovyan用户
USER jovyan

# 设置工作目录
WORKDIR /home/jovyan

# 暴露端口
EXPOSE 8888 4040-4050
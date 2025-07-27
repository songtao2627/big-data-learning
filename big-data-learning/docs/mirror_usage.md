# 国内镜像源使用说明

为了提高在国内下载Python包的速度，本项目支持使用国内镜像源。

## 支持的镜像源

1. **清华大学** (默认) - https://pypi.tuna.tsinghua.edu.cn/simple
2. **阿里云** - https://mirrors.aliyun.com/pypi/simple/
3. **豆瓣** - https://pypi.douban.com/simple/

## Docker环境

Docker环境已经预配置使用清华大学镜像源。如果需要切换镜像源，可以在容器中执行以下命令：

```bash
# 切换到清华大学镜像源
switch_pip_mirror.sh tsinghua

# 切换到阿里云镜像源
switch_pip_mirror.sh aliyun

# 切换到豆瓣镜像源
switch_pip_mirror.sh douban
```

## 本地环境

在本地环境中，可以通过PowerShell脚本的参数选择镜像源：

```powershell
# 使用清华大学镜像源（默认）
.\setup_local_environment.ps1

# 使用阿里云镜像源
.\setup_local_environment.ps1 -Mirror aliyun

# 使用豆瓣镜像源
.\setup_local_environment.ps1 -Mirror douban

# 使用默认PyPI源
.\setup_local_environment.ps1 -Mirror default
```

## 手动配置

如果需要手动配置pip镜像源，可以创建配置文件：

### Windows

创建文件 `%APPDATA%\pip\pip.ini` 并添加以下内容：

```ini
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
```

### Linux/macOS

创建文件 `~/.pip/pip.conf` 并添加以下内容：

```ini
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
```

## 相关文档

- [VS Code 插件配置指南](./vscode_plugins.md) - 介绍推荐的VS Code插件，方便运行项目中的各种脚本

## 常见问题

### 1. 镜像源配置不生效

确保配置文件路径和格式正确，并重启终端。

### 2. 特定包无法从镜像源下载

某些包可能没有在镜像源同步，可以临时使用默认源：

```bash
pip install package_name -i https://pypi.org/simple
```

### 3. 需要验证包的完整性

如果对包的安全性有顾虑，可以使用官方源并耐心等待下载：

```bash
.\setup_local_environment.ps1 -Mirror default
```
# 国内镜像源使用说明

为了提高在国内下载Python包的速度，本项目支持使用国内镜像源。

## 支持的镜像源

1. **清华大学** (默认) - https://pypi.tuna.tsinghua.edu.cn/simple
2. **阿里云** - https://mirrors.aliyun.com/pypi/simple/
3. **豆瓣** - https://pypi.douban.com/simple/

## Docker环境

Docker环境已经预配置使用清华大学镜像源。如果需要切换镜像源，可以在容器中执行以下命令：

```bash
# 切换到清华大学镜像源
switch_pip_mirror.sh tsinghua

# 切换到阿里云镜像源
switch_pip_mirror.sh aliyun

# 切换到豆瓣镜像源
switch_pip_mirror.sh douban
```

## 本地环境

在本地环境中，可以通过PowerShell脚本的参数选择镜像源：

```powershell
# 使用清华大学镜像源（默认）
.\setup_local_environment.ps1

# 使用阿里云镜像源
.\setup_local_environment.ps1 -Mirror aliyun

# 使用豆瓣镜像源
.\setup_local_environment.ps1 -Mirror douban

# 使用默认PyPI源
.\setup_local_environment.ps1 -Mirror default
```

## 手动配置

如果需要手动配置pip镜像源，可以创建配置文件：

### Windows

创建文件 `%APPDATA%\pip\pip.ini` 并添加以下内容：

```ini
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
```

### Linux/macOS

创建文件 `~/.pip/pip.conf` 并添加以下内容：

```ini
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
```

## 相关文档

- [VS Code 插件配置指南](./vscode_plugins.md) - 介绍推荐的VS Code插件，方便运行项目中的各种脚本

## 常见问题

### 1. 镜像源配置不生效

确保配置文件路径和格式正确，并重启终端。

### 2. 特定包无法从镜像源下载

某些包可能没有在镜像源同步，可以临时使用默认源：

```bash
pip install package_name -i https://pypi.org/simple
```

### 3. 需要验证包的完整性

如果对包的安全性有顾虑，可以使用官方源并耐心等待下载：

```bash
.\setup_local_environment.ps1 -Mirror default
```
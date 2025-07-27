# VS Code 插件配置指南

为了方便在 VS Code 中运行项目中的各种脚本，推荐安装以下插件。

## 必需插件

### 1. Python
提供对 Python 文件的全面支持，包括语法高亮、代码补全、调试等功能。这是运行 .py 文件的基础插件。

安装命令:
```
ext install ms-python.python
```

### 2. Jupyter
支持在 VS Code 中直接打开和运行 Jupyter Notebook (.ipynb) 文件，可以方便地执行和调试 notebook 中的代码。

安装命令:
```
ext install ms-toolsai.jupyter
```

### 3. PowerShell
为 PowerShell 脚本 (.ps1 文件) 提供语法高亮和执行支持，该项目中有多个 PowerShell 脚本。

安装命令:
```
ext install ms-vscode.PowerShell
```

## 推荐插件

### 4. Docker
提供 Docker 相关功能，方便管理和运行项目中的 Docker 容器。

安装命令:
```
ext install ms-azuretools.vscode-docker
```

### 5. Code Runner
支持一键运行多种编程语言的脚本，包括 Python 和 PowerShell，非常方便测试各种脚本。

安装命令:
```
ext install formulahendry.code-runner
```

### 6. GitLens
增强 Git 功能，帮助你更好地管理项目版本控制。

安装命令:
```
ext install eamodio.gitlens
```

## 配置建议

安装这些插件后，你可以:

1. 直接在 VS Code 中右键点击 Python 文件并选择"Run Python File in Terminal"来运行 Python 脚本
2. 使用 Code Runner 插件通过快捷键 `Ctrl+Alt+N` 快速运行当前脚本
3. 在 PowerShell 文件中使用集成终端执行脚本
4. 直接在 VS Code 中编辑和运行 Jupyter Notebook

这些插件将大大提高你在 VS Code 中处理这个大数据学习项目各种脚本文件的效率。
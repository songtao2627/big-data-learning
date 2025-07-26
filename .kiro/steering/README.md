# Steering 配置说明

## 配置文件概览

### 始终包含的文件 (inclusion: always)
- **project-standards.md**: 项目标准和编码规范
- **project-overview.md**: 项目总览和快速开始指南

### 文件匹配触发的文件 (inclusion: fileMatch)
- **spark-development.md**: Spark 开发指导 (匹配: *.py, *.ipynb, *spark*)
- **docker-environment.md**: Docker 环境管理 (匹配: *docker*, *.yml, *.yaml)
- **data-processing.md**: 数据处理规范 (匹配: *data*, *.csv, *.json, *.parquet)

### 手动包含的文件 (inclusion: manual)
- **learning-guidance.md**: 学习路径指导
- **troubleshooting.md**: 故障排除指南

## Steering 系统的作用

### 1. 上下文增强
为 AI 助手提供项目特定的背景知识和规范，确保生成的建议符合项目标准。

### 2. 一致性保证
通过统一的规范和最佳实践，确保代码质量和项目结构的一致性。

### 3. 学习支持
提供结构化的学习路径和指导，帮助用户系统地掌握大数据技术。

### 4. 问题解决
包含常见问题的诊断和解决方案，提高问题解决效率。

## 文件引用机制

### 语法
```markdown
#[[file:relative/path/to/file.ext]]
```

### 示例
```markdown
# 引用项目 README
#[[file:README.md]]

# 引用脚本文件
#[[file:scripts/troubleshoot.ps1]]

# 引用数据描述
#[[file:data/datasets_description.md]]
```

### 作用
- 动态包含其他文件的内容
- 保持文档的实时性和准确性
- 避免信息重复和不一致

## 最佳实践

### 1. 内容组织
- 按功能领域分组相关内容
- 使用清晰的标题和结构
- 提供具体的示例和代码片段

### 2. 更新维护
- 定期检查文档的准确性
- 随项目发展更新规范
- 收集用户反馈优化内容

### 3. 文件引用
- 合理使用文件引用避免冗余
- 确保引用的文件存在且相关
- 注意引用文件的更新影响

## 自定义 Steering

### 添加新的 Steering 文件
1. 在 `.kiro/steering/` 目录创建 markdown 文件
2. 添加适当的 front-matter 配置
3. 编写相关的指导内容
4. 测试文件匹配规则

### Front-matter 配置选项
```yaml
---
inclusion: always|fileMatch|manual
fileMatchPattern: "*.py|*.js|README*"  # 仅当 inclusion: fileMatch 时需要
---
```

### 内容编写指南
- 使用清晰的标题层次
- 提供具体的代码示例
- 包含实用的检查清单
- 添加相关的外部链接

## 与 Hooks 的协同

Steering 文件为 Hooks 提供上下文信息，两者协同工作：
- Hooks 触发特定的自动化任务
- Steering 提供执行任务所需的背景知识
- 共同提升开发体验和代码质量
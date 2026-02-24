## 安全指南（关键）

### 强制性安全检查

在提交任何代码之前：
- [ ] 没有硬编码的密钥、密码或敏感信息
- [ ] 外部数据经过适当验证和处理
- [ ] 防止各种注入攻击（代码、命令、数据等）
- [ ] 适当的访问控制和权限管理
- [ ] 资源使用在合理范围内（内存、CPU、存储等）
- [ ] 错误和异常处理不暴露敏感信息
- [ ] 依赖项和第三方库已检查安全性
- [ ] 配置和部署设置符合安全要求

### 密钥管理

```typescript
// 绝对不要：硬编码密钥
const apiKey = "sk-proj-xxxxx"

// 始终：使用环境变量
const apiKey = process.env.OPENAI_API_KEY

if (!apiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}
```

### 安全响应协议

如果发现安全问题：
1. 立即停止
2. 使用 **security-reviewer** 代理
3. 在继续之前修复关键问题
4. 轮换任何暴露的密钥
5. 审查整个代码库中的类似问题

---

## 编码风格

### 文件组织

多个小文件 > 少量大文件：
- 高内聚，低耦合
- 典型 200-400 行，最多 800 行
- 从大型组件中提取实用工具
- 按功能/领域组织，而不是按类型

### 错误处理

始终全面处理错误：

```typescript
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  console.error('Operation failed:', error)
  throw new Error('Detailed user-friendly message')
}
```

### 代码质量检查清单

在标记工作完成之前：
- [ ] 代码可读且命名良好
- [ ] 函数小巧（<50 行）
- [ ] 文件专注（<800 行）
- [ ] 没有深层嵌套（>4 层）
- [ ] 适当的错误处理
- [ ] 没有调试输出语句（如 console.log、print 等）
- [ ] 没有硬编码的值

---
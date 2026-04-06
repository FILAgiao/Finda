# Claude Code源码泄露分析与OpenClaw增强方案

> **研究时间**：2026年4月6日
> **研究目的**：借鉴Claude Code优秀设计，增强OpenClaw能力

---

## 一、泄露事件概述

### 1.1 事件背景

| 项目 | 详情 |
|------|------|
| 发生时间 | 2026年3月31日 |
| 泄露原因 | Anthropic在npm包更新中意外发布源码映射文件 |
| 代码规模 | 512,000行TypeScript，约1,900个文件 |
| 社区响应 | 22小时内获得22,000+ GitHub Stars |

### 1.2 相关仓库

| 仓库 | 类型 | 说明 |
|------|------|------|
| `chauncygu/collection-claude-code-source-code` | 源码合集 | 原始泄露+Python重写 |
| `claw-decode` | 分析文档 | 43工具+7隐藏功能详解 |
| `nano-claude-code` | Python重写 | ~5000行可运行版本 |

---

## 二、Claude Code核心架构分析

### 2.1 系统架构概览

```
用户输入
    ↓
processUserInput()      # 解析 /slash 命令
    ↓
query()                 # 主Agent循环 (query.ts)
    ├── fetchSystemPromptParts()  # 组装系统提示
    ├── StreamingToolExecutor     # 并行工具执行
    ├── autoCompact()             # 自动上下文压缩
    └── runTools()                # 工具编排调度
    ↓
yield SDKMessage        # 流式返回结果
```

### 2.2 技术栈

| 组件 | 技术 |
|------|------|
| 语言 | TypeScript 6.0+ |
| 运行时 | Bun（编译为Node.js >= 18 bundle） |
| Claude API | Anthropic SDK |
| 终端UI | React + Ink |
| 代码打包 | esbuild |
| 数据验证 | Zod |
| 工具协议 | MCP（Model Context Protocol） |

---

## 三、五大可借鉴模式

### 3.1 内存即Markdown文件

**核心理念**：
- 不使用向量数据库
- 不使用RAG管道
- LLM原生读写文本
- Dream Mode负责维护

**目录结构**：
```
Memory Directory/
├── ENTRYPOINT.md      ← 索引（< 25KB）
├── user-prefs.md      ← 用户偏好
├── project-ctx.md     ← 项目上下文
├── feedback-testing.md ← 用户纠正
└── logs/
    └── 2026/03/
        └── 2026-03-31.md ← 每日日志
```

**启示**：OpenClaw的MEMORY.md机制与之类似，可增强Dream Mode（记忆整合循环）。

---

### 3.2 工具 = 名称 + 提示 + 权限 + 执行

**Claude Code的43个工具**：

| 类别 | 工具 |
|------|------|
| 文件操作 | FileRead, FileWrite, FileEdit, Glob, Grep, NotebookEdit |
| 系统执行 | Bash, PowerShell, REPL（内部） |
| Agent编排 | Agent, TeamCreate, TeamDelete, SendMessage |
| 任务管理 | TaskCreate, TaskGet, TaskList, TaskUpdate, TaskStop, TaskOutput, TodoWrite |
| Web访问 | WebSearch, WebFetch |
| MCP集成 | MCPTool, McpAuth, ListMcpResources, ReadMcpResource |
| IDE集成 | LSP |
| 会话管理 | Sleep, ScheduleCron, RemoteTrigger, SendUserMessage |
| 导航 | EnterPlanMode, ExitPlanMode, EnterWorktree, ExitWorktree |
| 配置 | ConfigTool, SkillTool, ToolSearchTool |
| UX | AskUserQuestion, SyntheticOutput, BriefTool |

**启示**：
- 每个工具独立可测试
- 权限粒度化（auto/ask/deny）
- 提示词教会模型何时用、何时不用

---

### 3.3 多Agent通过共享任务列表协调

**核心机制**：
- Agent不直接调用彼此
- 通过共享任务CRUD协调
- 任何Agent可以领取任何任务
- 进度对所有可见

**角色类型**：
- Coder（编码）
- Reviewer（审查）
- Researcher（研究）
- Planner（规划）

**启示**：OpenClaw的三省六部制可借鉴角色分工和任务队列机制。

---

### 3.4 行动谨慎框架

**权限分级**：

| 可逆性 | 影响范围 | 操作 |
|--------|---------|------|
| 可逆 | 低影响 | 自由执行 |
| 可逆 | 高影响 | 确认后执行 |
| 不可逆 | 低影响 | 确认后执行 |
| 不可逆 | 高影响 | 始终确认 |

**关键原则**：
- 一次授权不等于永久授权
- "Measure twice, cut once"

---

### 3.5 静态/动态提示分离

**提示词结构（914行）**：

| 部分 | 类型 | 说明 |
|------|------|------|
| Section 1-6 | 静态 | 规则、工具、风格（可缓存） |
| Section 7-10 | 动态 | 内存、环境、MCP（每次变化） |

**启示**：利用Anthropic的提示缓存，914行提示大部分首次调用后免费。

---

## 四、隐藏功能发现

### 4.1 Dream Mode（梦境模式）

**四阶段记忆整合**：

| 阶段 | 名称 | 动作 |
|------|------|------|
| Phase 1 | Orient | ls内存目录，读取索引，避免重复创建 |
| Phase 2 | Gather | 检查日志，发现漂移记忆，grep关键内容 |
| Phase 3 | Consolidate | 合并新内容，转换相对日期，删除矛盾事实 |
| Phase 4 | Prune | 保持索引<25KB，移除过期指针，解决矛盾 |

---

### 4.2 Verification Agent（验证Agent）

**内部版本特性**：
- ≤25字工具间输出
- ≤100字最终响应
- 多文件编辑强制验证
- 默认无代码注释
- "不声称测试通过当输出显示失败"

---

### 4.3 Undercover Mode（潜行模式）

**应用场景**：Anthropic员工在公开仓库使用Claude Code时自动进入

**禁止内容**：
- 内部模型代号（Capybara, Tengu等）
- 未发布版本号（opus-4-7, sonnet-4-8）
- 内部仓库名
- "Claude Code"或AI提及
- Co-Authored-By行

---

### 4.4 Buddy System（伙伴系统）

**ASCII宠物系统**：
- 18种物种
- 5种稀有度
- 动画ASCII精灵
- 帽子、眼睛变体
- 个性属性（DEBUGGING, PATIENCE, CHAOS, WISDOM, SNARK）

---

## 五、OpenClaw能力差距分析

### 5.1 皇上之前提出的需求回顾

| 需求 | 当前状态 | Claude Code方案 |
|------|---------|-----------------|
| 自动化单元测试 | 部分实现 | Verification Agent强制验证 |
| 目检测试（无头浏览器） | gstack技能 | 截图对比工具 |
| 人工模拟操作测试 | 未实现 | 用户交互记录 |
| 记录改善问题循环迭代 | 看板系统 | Dream Mode + feedback类型 |
| 压力测试（9999次迭代） | 部分实现 | 任务调度系统 |

### 5.2 OpenClaw现有优势

| 优势 | 说明 |
|------|------|
| 三省六部制 | 独特的流程编排 |
| 看板系统 | 任务状态可视化 |
| Memory系统 | MEMORY.md + memory/*.md |
| 技能系统 | skills目录 |
| 多Agent | spawn机制 |

### 5.3 需要增强的领域

| 领域 | 差距 | 优先级 |
|------|------|--------|
| 工具权限系统 | 缺少细粒度权限控制 | 高 |
| 上下文压缩 | 缺少autoCompact | 高 |
| 验证Agent | 缺少强制验证机制 | 高 |
| Dream Mode | 缺少记忆整合循环 | 中 |
| 工具标准化 | 缺少工具提示词规范 | 中 |
| 静态/动态提示分离 | 未实现缓存优化 | 低 |

---

## 六、具体增强方案

### 6.1 验证Agent机制

**目标**：代码修改后自动验证

**实施方案**：

```python
# scripts/verification_agent.py

class VerificationAgent:
    """验证Agent - 代码修改后自动验证"""
    
    def __init__(self):
        self.rules = [
            "运行单元测试",
            "检查语法错误",
            "验证导入正确性",
            "检查类型注解",
        ]
    
    def verify_changes(self, changed_files: list) -> dict:
        """验证代码变更"""
        results = {
            "passed": [],
            "failed": [],
            "warnings": []
        }
        
        for file in changed_files:
            # 1. 语法检查
            # 2. 单元测试
            # 3. 类型检查
            pass
        
        return results
```

**集成点**：三省六部制中的门下省审议环节

---

### 6.2 目检测试增强

**目标**：无头浏览器截图对比设计稿

**依赖安装**：
```bash
npm install playwright
npx playwright install
```

**实施方案**：

```python
# scripts/visual_regression.py

from playwright.sync_api import sync_playwright

class VisualRegression:
    """视觉回归测试"""
    
    def __init__(self, baseline_dir: str):
        self.baseline_dir = baseline_dir
    
    def capture(self, url: str, name: str) -> str:
        """截取当前页面"""
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page()
            page.goto(url)
            screenshot = page.screenshot()
            browser.close()
            return screenshot
    
    def compare(self, current: bytes, baseline: bytes) -> float:
        """对比相似度"""
        # 使用像素对比或感知哈希
        pass
    
    def generate_report(self, diffs: list) -> str:
        """生成对比报告"""
        pass
```

---

### 6.3 Dream Mode实现

**目标**：自动记忆整合循环

**实施方案**：

```python
# scripts/dream_mode.py

class DreamMode:
    """梦境模式 - 记忆整合"""
    
    def __init__(self, memory_dir: str):
        self.memory_dir = memory_dir
        self.max_index_size = 25 * 1024  # 25KB
    
    def phase_orient(self):
        """Phase 1: 定向"""
        # 读取ENTRYPOINT.md索引
        # 扫描现有主题文件
        pass
    
    def phase_gather(self):
        """Phase 2: 收集"""
        # 检查每日日志
        # 发现漂移记忆
        # grep关键内容
        pass
    
    def phase_consolidate(self):
        """Phase 3: 整合"""
        # 合并新内容
        # 转换相对日期为绝对日期
        # 删除矛盾事实
        pass
    
    def phase_prune(self):
        """Phase 4: 修剪"""
        # 保持索引<25KB
        # 移除过期指针
        # 解决文件间矛盾
        pass
    
    def run(self):
        """运行完整梦境循环"""
        self.phase_orient()
        self.phase_gather()
        self.phase_consolidate()
        self.phase_prune()
```

**触发条件**：
- 空闲超过30分钟
- 用户手动触发 `/dream`
- 每日凌晨3点自动运行

---

### 6.4 工具权限系统

**目标**：细粒度权限控制

**实施方案**：

```python
# scripts/tool_permissions.py

from enum import Enum
from typing import Dict, List

class PermissionLevel(Enum):
    AUTO = "auto"       # 自动允许
    ASK = "ask"         # 每次询问
    DENY = "deny"       # 自动拒绝

class ToolPermission:
    """工具权限管理"""
    
    # 默认权限配置
    DEFAULT_PERMISSIONS = {
        "FileRead": PermissionLevel.AUTO,
        "FileWrite": PermissionLevel.ASK,
        "FileEdit": PermissionLevel.ASK,
        "Bash": PermissionLevel.ASK,
        "WebSearch": PermissionLevel.AUTO,
        "WebFetch": PermissionLevel.AUTO,
    }
    
    # 高危操作
    DANGEROUS_OPERATIONS = [
        "rm -rf",
        "DROP TABLE",
        "DELETE FROM",
        "format",
    ]
    
    def __init__(self, config_path: str):
        self.config_path = config_path
        self.permissions = self.load_permissions()
    
    def check_permission(self, tool: str, operation: str = None) -> PermissionLevel:
        """检查权限级别"""
        # 检查是否是高危操作
        if operation and any(d in operation for d in self.DANGEROUS_OPERATIONS):
            return PermissionLevel.DENY
        
        return self.permissions.get(tool, PermissionLevel.ASK)
    
    def update_permission(self, tool: str, level: PermissionLevel):
        """更新权限"""
        self.permissions[tool] = level
        self.save_permissions()
```

---

### 6.5 上下文压缩

**目标**：自动压缩长对话

**实施方案**：

```python
# scripts/context_compact.py

class ContextCompactor:
    """上下文压缩器"""
    
    # 压缩策略
    STRATEGIES = [
        "reactive",      # 反应式：达到阈值时压缩
        "micro",         # 微压缩：每轮小压缩
        "trimmed",       # 修剪式：删除旧消息
    ]
    
    def __init__(self, max_tokens: int = 100000):
        self.max_tokens = max_tokens
    
    def estimate_tokens(self, messages: list) -> int:
        """估算token数量"""
        total = 0
        for msg in messages:
            total += len(msg.get("content", "")) // 4
        return total
    
    def compact(self, messages: list, strategy: str = "reactive") -> list:
        """压缩消息"""
        if strategy == "reactive":
            return self._reactive_compact(messages)
        elif strategy == "micro":
            return self._micro_compact(messages)
        elif strategy == "trimmed":
            return self._trimmed_compact(messages)
    
    def _reactive_compact(self, messages: list) -> list:
        """反应式压缩"""
        # 保留系统消息和最近N条
        # 对中间消息生成摘要
        pass
    
    def _micro_compact(self, messages: list) -> list:
        """微压缩"""
        # 每轮压缩最近消息的冗余
        pass
    
    def _trimmed_compact(self, messages: list) -> list:
        """修剪式压缩"""
        # 删除旧的非关键消息
        pass
```

---

## 七、实施计划

### 7.1 阶段一：基础增强（1-2周）

| 任务 | 优先级 | 预计时间 |
|------|--------|---------|
| 工具权限系统 | 高 | 2天 |
| 上下文压缩 | 高 | 3天 |
| 验证Agent | 高 | 4天 |

### 7.2 阶段二：测试增强（2-3周）

| 任务 | 优先级 | 预计时间 |
|------|--------|---------|
| 目检测试集成 | 高 | 5天 |
| 自动化测试流程 | 高 | 4天 |
| 问题记录循环 | 中 | 3天 |

### 7.3 阶段三：记忆增强（3-4周）

| 任务 | 优先级 | 预计时间 |
|------|--------|---------|
| Dream Mode | 中 | 5天 |
| 记忆类型扩展 | 中 | 3天 |
| 静态/动态提示分离 | 低 | 4天 |

---

## 八、依赖安装清单

```bash
# 目检测试
npm install playwright
npx playwright install chromium

# 代码验证
pip install pytest pytest-cov mypy ruff

# 上下文压缩
pip install tiktoken

# 压力测试
pip install locust

# 记忆管理
pip install python-dateutil
```

---

## 九、风险与应对

| 风险 | 应对措施 |
|------|---------|
| Claude Code闭源 | 仅借鉴架构思想，不复制代码 |
| 许可问题 | 参考clean-room重写（nano-claude-code） |
| 功能冲突 | 逐步集成，保持三省六部制核心 |
| 性能影响 | 异步执行，不阻塞主流程 |

---

## 十、总结

### 10.1 核心收获

1. **内存即Markdown**：简单有效，LLM原生支持
2. **工具标准化**：名称+提示+权限+执行
3. **多Agent协调**：共享任务队列
4. **验证机制**：强制验证保证质量
5. **梦境模式**：自动记忆整合

### 10.2 OpenClaw优势保持

- 三省六部制流程编排
- 看板系统任务可视化
- 中文原生支持
- 企业微信/钉钉/飞书集成

### 10.3 下一步行动

1. **立即安装**：playwright, pytest, mypy
2. **优先实现**：验证Agent + 工具权限
3. **持续迭代**：根据皇上需求调整

---

*报告日期：2026年4月6日*
*研究人员：太子·三省六部*
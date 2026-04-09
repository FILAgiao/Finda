# Finda 记忆宫殿 (Memory Palace)

> 用空间记忆法管理项目信息——这是你的"脑内地图"

```
                    🏰 FINDA 记忆宫殿
                         ╱    ╲
                        ╱      ╲
                   🚪 入口     🏛️ 大厅 (PLAN.md)
                      ╱
         ┌───────────┼───────────┐
         │           │           │
      📋 会议室    🔧 车间     🧪 实验室
      (backlog)  (tasks/)   (sprints/)
         │           │           │
      epics/      开发任务    迭代回顾
      stories/    Bug 修复    测试报告
         │           │           │
         └───────────┼───────────┘
                     │
              ┌─────┴─────┐
              │           │
           📚 图书馆    🏆 荣誉室
          (docs/)    (decisions/)
           架构文档    ADR 决策
           技术规范    里程碑
              │           │
              └─────┬─────┘
                    │
                🧠 档案室
               (memory/)
               项目记忆
               经验教训
```

---

## 房间导航

### 🏛️ 大厅 — PLAN.md
**用途**: 项目总览、快速定位  
**查看频率**: 每次对话开始  
**包含**: 项目定位、架构图、关键指标、AI 规则

---

### 📋 会议室 — backlog/
**用途**: 需求管理  
**查看场景**: 规划新功能、查看优先级  
**包含**:
- `epics/` — 大模块 (EPIC-001: 用户认证)
- `stories/` — 用户故事 (US-001: 手机号登录)

**使用方法**:
```bash
# 查看当前进行中的 Epic
cat backlog/epics/EPIC-001-auth.md

# 创建新需求
cp backlog/stories/_template.md backlog/stories/US-010-xxx.md
```

---

### 🔧 车间 — `.claude/tasks/`
**用途**: 具体执行任务  
**查看场景**: 开发编码时  
**与 backlog 关系**: Story 拆解为 Task

**任务状态流转**:
```
📋 待开始 → 🚧 进行中 → ✅ 已完成
```

---

### 🧪 实验室 — sprints/
**用途**: 迭代管理、测试追踪  
**包含**:
- `current.md` — 当前 Sprint
- `reviews/` — 迭代回顾
- `tests/` — 测试报告

---

### 📚 图书馆 — docs/
**用途**: 技术文档、知识沉淀  
**现有文档**:
- 架构设计、算法分析、竞品分析

---

### 🏆 荣誉室 — decisions/
**用途**: 记录重要决策 (ADR)  
**格式**: `ADR-XXX-标题.md`  
**包含**: 决策背景、方案对比、最终选择

---

### 🧠 档案室 — `.claude/memory/`
**用途**: AI 的持久记忆  
**由 Claude 自动管理**  
**包含**: 用户偏好、项目上下文、经验教训

---

## 使用工作流 (AI 协作流程)

```
1. 新对话开始
   → 读取 PLAN.md (进入大厅)
   → 读取 memory/ (调取记忆)

2. 规划新功能
   → 进入 backlog/ 会议室
   → 创建 Epic/Story
   → 拆解为 Tasks

3. 开始开发
   → 进入 .claude/tasks/ 车间
   → 领取/创建任务
   → 编码实现

4. 任务完成
   → 更新 Task 状态
   → 更新 Story 验收标准
   → 记录到 sprints/ 实验室

5. 技术决策
   → 进入 decisions/ 荣誉室
   → 创建 ADR 文档
   → 更新 PLAN.md 决策表
```

---

## 快速命令

```bash
# 查看项目全貌
find . -name "*.md" -path "./backlog/*" -o -path "./sprints/*" | sort

# 查找进行中任务
grep -r "🚧 进行中" backlog/ sprints/ 2>/dev/null

# 查看今日任务
ls -lt .claude/tasks/ | head -10
```

---

## 可视化记忆技巧

想象你在这个宫殿中行走：
1. **每天进入大厅** (PLAN.md) — 了解全局
2. **在会议室讨论** (backlog) — 明确做什么
3. **去车间干活** (tasks) — 专注执行
4. **到实验室验证** (sprints) — 检查结果
5. **在荣誉室记录** (decisions) — 总结经验

**记住**: 空间即信息，位置即记忆

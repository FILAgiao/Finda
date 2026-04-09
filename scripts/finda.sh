#!/bin/bash
#
# Finda 项目管理快捷脚本
# 使用: ./finda.sh [命令] [参数]
#

COMMAND=$1
shift

 case $COMMAND in
  "status")
    echo "🏰 Finda 项目状态"
    echo "=================="
    echo ""
    echo "📋 进行中的 Epics:"
    grep -r "🚧 进行中" backlog/epics/ 2>/dev/null | wc -l | xargs echo "  - 数量:"
    echo ""
    echo "🔴 P0 优先级任务:"
    grep -r "🔴 P0" backlog/stories/ 2>/dev/null | wc -l | xargs echo "  - 数量:"
    echo ""
    echo "🔬 活跃实验:"
    ls insights/experiments/*.md 2>/dev/null | wc -l | xargs echo "  - 数量:"
    echo ""
    echo "📊 Sprint 进度:"
    if [ -f "sprints/current.md" ]; then
      grep "\[x\]" sprints/current.md | wc -l | xargs -I{} echo -n "  - 完成: {}"
      grep "\[ \]" sprints/current.md | wc -l | xargs -I{} echo " / 剩余: {}"
    fi
    ;;

  "task")
    ACTION=$1
    TASK_ID=$2
    case $ACTION in
      "list")
        echo "📝 当前任务列表"
        ls -1 .claude/tasks/ 2>/dev/null || echo "暂无任务"
        ;;
      "create")
        if [ -z "$TASK_ID" ]; then
          echo "Usage: ./finda.sh task create <task-id>"
          exit 1
        fi
        cat > ".claude/tasks/${TASK_ID}.md" << EOF
# ${TASK_ID}

## 描述
[任务描述]

## 关联
- Epic:
- Story:

## 检查清单
- [ ] 分析
- [ ] 实现
- [ ] 测试
- [ ] 文档

## 状态
📋 待开始

## 创建于
$(date +%Y-%m-%d)
EOF
        echo "✅ 任务 ${TASK_ID} 已创建"
        ;;
      "done")
        if [ -z "$TASK_ID" ]; then
          echo "Usage: ./finda.sh task done <task-id>"
          exit 1
        fi
        sed -i '' 's/📋 待开始/✅ 已完成/' ".claude/tasks/${TASK_ID}.md" 2>/dev/null || \
        sed -i 's/📋 待开始/✅ 已完成/' ".claude/tasks/${TASK_ID}.md" 2>/dev/null
        echo "✅ 任务 ${TASK_ID} 已标记为完成"
        ;;
      *)
        echo "Usage: ./finda.sh task [list|create|done]"
        ;;
    esac
    ;;

  "story")
    STORY_ID=$1
    if [ -z "$STORY_ID" ]; then
      echo "Usage: ./finda.sh story <story-id>"
      echo "Example: ./finda.sh story US-004"
      exit 1
    fi
    FILE="backlog/stories/${STORY_ID}.md"
    if [ -f "$FILE" ]; then
      echo "📖 ${STORY_ID}"
      grep "^# " "$FILE"
      echo ""
      grep "🚧 进行中\|✅ 已完成\|📋 待开始" "$FILE" | head -1
    else
      echo "Story ${STORY_ID} 不存在"
      echo "创建新 Story:"
      cat > "$FILE" << EOF
# ${STORY_ID}: [标题]

## 背景
作为 [角色]，我希望 [功能]，以便 [价值]

## 验收标准
- [ ] AC1:
- [ ] AC2:
- [ ] AC3:

## 估计工作量
- 开发: X 天
- 测试: X 天

## 状态
📋 待开始

## 创建于
$(date +%Y-%m-%d)
EOF
      echo "✅ 已创建模板: ${FILE}"
    fi
    ;;

  "exp")
    EXP_ID=$1
    if [ -z "$EXP_ID" ]; then
      echo "🔬 实验列表"
      ls -1 insights/experiments/*.md 2>/dev/null
      exit 0
    fi
    FILE="insights/experiments/${EXP_ID}.md"
    if [ -f "$FILE" ]; then
      cat "$FILE"
    else
      echo "实验 ${EXP_ID} 不存在"
    fi
    ;;

  "insights")
    echo "🧠 用户洞察"
    echo "============"
    echo ""
    echo "📊 心理学画像:"
    echo "  - [需求方心理](insights/psychology-map/persona.md#用户-A需求方-seeker)"
    echo "  - [服务方心理](insights/psychology-map/persona.md#用户-B服务方-provider)"
    echo ""
    echo "🗺️ 用户旅程:"
    echo "  - [需求方旅程](insights/journey-emotion/map.md#需求方旅程)"
    echo "  - [服务方旅程](insights/journey-emotion/map.md#服务方旅程)"
    echo ""
    echo "🔬 增长实验:"
    echo "  - [实验列表](insights/experiments/README.md)"
    ;;

  "help"|*)
    echo "Finda 项目管理脚本"
    echo ""
    echo "Commands:"
    echo "  ./finda.sh status              查看项目状态"
    echo "  ./finda.sh task list           列出所有任务"
    echo "  ./finda.sh task create <id>    创建新任务"
    echo "  ./finda.sh task done <id>      标记任务完成"
    echo "  ./finda.sh story <id>          查看/创建 Story"
    echo "  ./finda.sh exp [id]            查看实验列表/详情"
    echo "  ./finda.sh insights            查看用户洞察"
    echo ""
    echo "Examples:"
    echo "  ./finda.sh task create TASK-001"
    echo "  ./finda.sh story US-004"
    ;;
esac

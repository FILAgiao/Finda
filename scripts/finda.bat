@echo off
REM Finda 项目管理快捷脚本 (Windows版本)
REM 使用: finda.bat [命令] [参数]

set COMMAND=%1

if "%COMMAND%"=="status" goto :status
if "%COMMAND%"=="task" goto :task
if "%COMMAND%"=="story" goto :story
if "%COMMAND%"=="insights" goto :insights
if "%COMMAND%"=="help" goto :help
goto :help

:status
echo 🏰 Finda 项目状态
echo ==================
echo.
echo 📋 进行中的 Epics:
findstr /C:"🚧 进行中" backlog\epics\*.md 2>nul | find /C ":" | set /p count=
if "%count%"=="" set count=0
echo   - 数量: %count%
echo.
echo 🔴 P0 优先级任务:
findstr /C:"🔴 P0" backlog\stories\*.md 2>nul | find /C ":" | set /p p0count=
if "%p0count%"=="" set p0count=0
echo   - 数量: %p0count%
echo.
echo 🔬 活跃实验:
dir /b insights\experiments\*.md 2>nul | find /C ".md" | set /p expcount=
if "%expcount%"=="" set expcount=0
echo   - 数量: %expcount%
echo.
echo 📊 Sprint 进度:
if exist sprints\current.md (
    findstr /C:"[x]" sprints\current.md 2>nul | find /C ":" | set /p done=
    findstr /C:"[ ]" sprints\current.md 2>nul | find /C ":" | set /p todo=
    if "%done%"=="" set done=0
    if "%todo%"=="" set todo=0
    echo   - 完成: %done% / 剩余: %todo%
) else (
    echo   - 暂无 Sprint 数据
)
goto :eof

:task
set ACTION=%2
set TASK_ID=%3
if "%ACTION%"=="list" (
    echo 📝 当前任务列表
    dir /b .claude\tasks\*.md 2>nul || echo 暂无任务
) else if "%ACTION%"=="create" (
    if "%TASK_ID%"=="" (
        echo Usage: finda.bat task create ^<task-id^>
        goto :eof
    )
    (
        echo # %TASK_ID%
        echo.
        echo ## 描述
        echo [任务描述]
        echo.
        echo ## 关联
        echo - Epic:
        echo - Story:
        echo.
        echo ## 检查清单
        echo - [ ] 分析
        echo - [ ] 实现
        echo - [ ] 测试
        echo - [ ] 文档
        echo.
        echo ## 状态
        echo 📋 待开始
        echo.
        echo ## 创建于
        echo %date%
    ) > ".claude\tasks\%TASK_ID%.md"
    echo ✅ 任务 %TASK_ID% 已创建
) else (
    echo Usage: finda.bat task [list^|create^|done]
)
goto :eof

:story
set STORY_ID=%2
if "%STORY_ID%"=="" (
    echo Usage: finda.bat story ^<story-id^>
    echo Example: finda.bat story US-004
    goto :eof
)
if exist "backlog\stories\%STORY_ID%.md" (
    echo 📖 %STORY_ID%
    findstr /B "# " "backlog\stories\%STORY_ID%.md"
) else (
    echo Story %STORY_ID% 不存在
    echo 创建新 Story...
    (
        echo # %STORY_ID%: [标题]
        echo.
        echo ## 背景
        echo 作为 [角色]，我希望 [功能]，以便 [价值]
        echo.
        echo ## 验收标准
        echo - [ ] AC1:
        echo - [ ] AC2:
        echo - [ ] AC3:
        echo.
        echo ## 估计工作量
        echo - 开发: X 天
        echo - 测试: X 天
        echo.
        echo ## 状态
        echo 📋 待开始
        echo.
        echo ## 创建于
        echo %date%
    ) > "backlog\stories\%STORY_ID%.md"
    echo ✅ 已创建模板: backlog\stories\%STORY_ID%.md
)
goto :eof

:insights
echo 🧠 用户洞察
echo ============
echo.
echo 📊 心理学画像:
echo   - 需求方心理: insights\psychology-map\persona.md
echo   - 服务方心理: insights\psychology-map\persona.md
echo.
echo 🗺️ 用户旅程:
echo   - 需求方旅程: insights\journey-emotion\map.md
echo   - 服务方旅程: insights\journey-emotion\map.md
echo.
echo 🔬 增长实验:
echo   - 实验列表: insights\experiments\README.md
goto :eof

:help
echo Finda 项目管理脚本
echo.
echo Commands:
echo   finda.bat status              查看项目状态
echo   finda.bat task list           列出所有任务
echo   finda.bat task create ^<id^>  创建新任务
echo   finda.bat story ^<id^>        查看/创建 Story
echo   finda.bat insights            查看用户洞察
echo.
echo Examples:
echo   finda.bat task create TASK-001
echo   finda.bat story US-004

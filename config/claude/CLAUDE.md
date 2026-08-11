## 基本规则

- 全程使用简体中文回复我，所有提示、报错、帮助文档、操作提示全部显示中文，包括你的思考过程，保持永久生效
- 生成Word文档只用python-docx，不用npm的docx库
- Word文档排版：除封面和目录外，各章节之间连续不分页，保持阅读连贯性
- 本项目为非 git 仓库，所有版本追踪依赖文件本身
- **⚠️ 进度同步规则（每次会话必须遵守）**：
1. 复杂任务开始前运行 `/planning-with-files:plan-zh`，自动创建并维护 `task_plan.md`、`findings.md`、`progress.md`
2. 会话结束前运行 `/revise-claude-md`，把本次会话的经验教训沉淀到 `CLAUDE.md`
3. 项目结构或规则有变化时，用 `claude-md-improver` 审计并更新 `CLAUDE.md`

---

## 联网

WebFetch 不可靠（常被服务端域名校验挡），默认不用。改用：

1. **WebSearch** — 先搜索，永远可靠
2. **wmux 浏览器** — 在 wmux 里时，读页面正文用
3. **curl** — 兜底，任何环境可用（`curl -sL URL`）；web-access 需 Chrome 已开，没开就走 curl

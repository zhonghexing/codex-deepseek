# Codex + DeepSeek 完整配置指南

> 使用 cc-switch + 本地协议翻译代理，让 Codex 桌面版/CLI 无缝接入 DeepSeek

## 为什么需要这个方案？

Codex 使用 OpenAI 专有的 **Responses API**，DeepSeek 只提供标准的 **Chat Completions API**，两者协议不兼容。

本方案通过本地代理层做协议翻译，配合 cc-switch 做供应商管理，实现一键切换。

## 架构

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│              │     │              │     │              │     │              │
│  Codex 桌面版 ├────→│  cc-switch   ├────→│  本地代理     ├────→│  DeepSeek    │
│              │     │  (路由管理)   │     │  :11435      │     │  API         │
│              │     │              │     │              │     │              │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
                     Responses API       Responses ↔ Chat      Chat API
```

## 快速开始

### 1. 环境要求

- Python 3.9+
- [cc-switch](https://github.com/farion1231/cc-switch) 已安装
- Codex 桌面版/CLI
- DeepSeek API Key（[获取地址](https://platform.deepseek.com)）

### 2. 克隆仓库

```bash
git clone https://github.com/YOUR_USERNAME/codex-deepseek-guide.git
cd codex-deepseek-guide
```

### 3. 配置 API Key

编辑 `.env` 文件：

```env
api_key=sk-你的DeepSeek-API-Key
base_url=https://api.deepseek.com
model=deepseek-v4-pro
port=11435
```

### 4. 启动代理

**Windows：** 双击 `start_silent.vbs`（静默后台运行）

**macOS / Linux：**
```bash
python -m src.main &
```

### 5. 配置 cc-switch

打开 cc-switch → **Codex** 标签页 → 点击 **+** → 选择「**自定义**」：

| 字段 | 值 |
|------|-----|
| 名称 | `DeepSeek` |
| API 地址 | `http://127.0.0.1:11435` |
| wire_api | `responses` |
| requires_openai_auth | `true` |

点击启用，然后启动 Codex。

## 验证

```bash
# 代理健康检查
curl http://127.0.0.1:11435/health
# 输出: {"service": "codex-deepseek", "status": "ok"}

# 模型列表
curl http://127.0.0.1:11435/models
# 输出: {"data": [{"id": "deepseek-v4-pro"}]}
```

## 进阶配置

### 切换模型

修改 `.env` 中 `model` 字段：

| 模型 | 适用场景 |
|------|---------|
| `deepseek-v4-pro` | 复杂推理、重构、大项目 |
| `deepseek-v4-flash` | 日常编码、快速响应 |

### 自定义端口

修改 `.env`：
```env
port=8080
```

同时更新 cc-switch 中的 API 地址为 `http://127.0.0.1:8080`。

### 开机自启（Windows）

将 `start_silent.vbs` 放入启动文件夹：
```
Win+R → shell:startup → 粘贴快捷方式
```

## 协议翻译详情

<details>
<summary>请求方向（Responses → Chat Completions）</summary>

| Responses API | Chat Completions API |
|---------------|---------------------|
| `input_text` / `output_text` | 消息 `content` |
| `function_call` | assistant `tool_calls` |
| `function_call_output` | `tool` 角色消息 |
| `developer` 角色 | `system` 角色 |
| `instructions` | 前置 system 消息 |
| `tools` / `tool_choice` | 翻译为 Chat 格式 |
| `thinking` / `reasoning` | DeepSeek thinking 参数 |

</details>

<details>
<summary>响应方向（Chat SSE → Responses SSE）</summary>

| Chat Completions SSE | Responses API Event |
|----------------------|---------------------|
| 首个 delta | `response.created` + `response.in_progress` |
| `delta.content` | `response.output_text.delta` / `done` |
| `delta.reasoning_content` | `response.reasoning_text.delta` / `done` |
| `delta.tool_calls` | `response.function_call_arguments.delta` / `done` |
| 流结束 | `response.output_item.done` + `response.completed` |

</details>

## 故障排除

| 问题 | 解决方案 |
|------|---------|
| 代理无法启动 | 检查端口是否被占用：`netstat -ano \| findstr 11435` |
| Codex 连接失败 | 确认代理在运行：`curl http://127.0.0.1:11435/health` |
| API 返回错误 | 检查 `.env` 中 API Key 和账户余额 |
| 响应不完整 | 增大 `.env` 中 `timeout` 值 |
| 切回 OpenAI | 在 cc-switch 中启用 OpenAI Official 供应商 |

## 文件说明

```
codex-deepseek-guide/
├── src/                  # 协议翻译代理源码
│   ├── main.py           # HTTP 服务器
│   ├── translate.py      # 请求翻译
│   ├── sse.py            # SSE 事件翻译
│   └── recover.py        # reasoning_content 恢复
├── .env.example          # 环境变量模板
├── start.bat             # Windows 启动脚本（带控制台）
├── start_silent.vbs      # Windows 静默启动脚本
└── README.md             # 本文件
```

## 致谢

- [codex-deepseek](https://github.com/yangfei4913438/codex-deepseek) — 协议翻译代理（Python 移植版）
- [ccswitch-deepseek](https://github.com/liuzhengming/ccswitch-deepseek) — 原始 Node.js 版代理
- [cc-switch](https://github.com/farion1231/cc-switch) — 供应商管理工具

## License

MIT

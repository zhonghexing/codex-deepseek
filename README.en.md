# Codex + DeepSeek Complete Configuration Guide

> Use cc-switch + local protocol translation proxy to seamlessly connect Codex desktop/CLI with DeepSeek

## Why This Solution?

Codex uses OpenAI's proprietary **Responses API**, while DeepSeek only provides the standard **Chat Completions API** — the two protocols are incompatible.

This solution uses a local proxy layer for protocol translation, combined with cc-switch for provider management, enabling one-click switching.

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│              │     │              │     │              │     │              │
│  Codex       ├────→│  cc-switch   ├────→│  Local Proxy ├────→│  DeepSeek    │
│  Desktop/CLI │     │  (Routing)   │     │  :11435      │     │  API         │
│              │     │              │     │              │     │              │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
                     Responses API       Responses ↔ Chat      Chat API
```

## Quick Start

### 1. Requirements

- Python 3.9+
- [cc-switch](https://github.com/farion1231/cc-switch) installed
- Codex desktop/CLI
- DeepSeek API Key ([Get here](https://platform.deepseek.com))

### 2. Clone Repository

```bash
git clone https://github.com/zhonghexing/codex-deepseek.git
cd codex-deepseek
```

### 3. Configure API Key

Edit `.env` file:

```env
api_key=sk-your-DeepSeek-API-Key
base_url=https://api.deepseek.com
model=deepseek-v4-pro
port=11435
```

### 4. Start Proxy

**Windows:** Double-click `start_silent.vbs` (silent background mode)

**macOS / Linux:**
```bash
python -m src.main &
```

### 5. Configure cc-switch

Open cc-switch → **Codex** tab → Click **+** → Select "**Custom**":

| Field | Value |
|-------|-------|
| Name | `DeepSeek` |
| API URL | `http://127.0.0.1:11435` |
| wire_api | `responses` |
| requires_openai_auth | `true` |

Click enable, then start Codex.

## Verification

```bash
# Proxy health check
curl http://127.0.0.1:11435/health
# Output: {"service": "codex-deepseek", "status": "ok"}

# Model list
curl http://127.0.0.1:11435/models
# Output: {"data": [{"id": "deepseek-v4-pro"}]}
```

## Advanced Configuration

### Switch Models

Modify `model` field in `.env`:

| Model | Use Case |
|-------|----------|
| `deepseek-v4-pro` | Complex reasoning, refactoring, large projects |
| `deepseek-v4-flash` | Daily coding, fast responses |

### Custom Port

Modify `.env`:
```env
port=8080
```

Also update the API URL in cc-switch to `http://127.0.0.1:8080`.

### Auto-start on Windows

Put `start_silent.vbs` in the startup folder:
```
Win+R → shell:startup → paste shortcut
```

## Protocol Translation Details

<details>
<summary>Request Direction (Responses → Chat Completions)</summary>

| Responses API | Chat Completions API |
|---------------|---------------------|
| `input_text` / `output_text` | Message `content` |
| `function_call` | Assistant `tool_calls` |
| `function_call_output` | `tool` role message |
| `developer` role | `system` role |
| `instructions` | Prepend system message |
| `tools` / `tool_choice` | Translate to Chat format |
| `thinking` / `reasoning` | DeepSeek thinking parameter |

</details>

<details>
<summary>Response Direction (Chat SSE → Responses SSE)</summary>

| Chat Completions SSE | Responses API Event |
|----------------------|---------------------|
| First delta | `response.created` + `response.in_progress` |
| `delta.content` | `response.output_text.delta` / `done` |
| `delta.reasoning_content` | `response.reasoning_text.delta` / `done` |
| `delta.tool_calls` | `response.function_call_arguments.delta` / `done` |
| Stream end | `response.output_item.done` + `response.completed` |

</details>

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Proxy won't start | Check if port is occupied: `netstat -ano \| findstr 11435` |
| Codex connection failed | Confirm proxy is running: `curl http://127.0.0.1:11435/health` |
| API returns error | Check API Key and account balance in `.env` |
| Incomplete response | Increase `timeout` value in `.env` |
| Switch back to OpenAI | Enable OpenAI Official provider in cc-switch |

## File Structure

```
codex-deepseek/
├── src/                  # Protocol translation proxy source
│   ├── main.py           # HTTP server
│   ├── translate.py      # Request translation
│   ├── sse.py            # SSE event translation
│   └── recover.py        # reasoning_content recovery
├── .env.example          # Environment variable template
├── start.bat             # Windows start script (with console)
├── start_silent.vbs      # Windows silent start script
└── README.md             # This file
```

## Acknowledgments

- [codex-deepseek](https://github.com/yangfei4913438/codex-deepseek) — Protocol translation proxy (Python port)
- [ccswitch-deepseek](https://github.com/liuzhengming/ccswitch-deepseek) — Original Node.js proxy
- [cc-switch](https://github.com/farion1231/cc-switch) — Provider management tool

## License

MIT

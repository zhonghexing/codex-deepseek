@echo off
cd /d "%~dp0"
echo Starting codex-deepseek on http://127.0.0.1:11435 ...
echo.
echo [Powered by DeepSeek]
echo.
python -m src.main
pause

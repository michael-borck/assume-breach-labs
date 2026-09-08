@echo off
rem ISYS6014 Module 7: set up the Pi agent to use the Ollama models already on
rem this machine (qwen3:8b / qwen3:4b from last week's install). Optionally also
rem point Pi at the unit's shared server, using the key from the LMS announcement.
rem Run once; safe to run again at any time. (Windows)
setlocal
set "DIR=%USERPROFILE%\.pi\agent"
if not exist "%DIR%" mkdir "%DIR%"
set "F=%DIR%\models.json"
where pi >nul 2>nul
if errorlevel 1 (
  echo NOTE: Pi is not installed yet. The settings file will still be written.
  echo   1. Install Node.js LTS from https://nodejs.org ^(next, next, finish^)
  echo   2. npm install -g @earendil-works/pi-coding-agent
  echo   3. Check with: pi --version
  echo.
)
where ollama >nul 2>nul
if errorlevel 1 (
  echo NOTE: Ollama is not installed or not running. The local provider will not
  echo   respond until you install it from https://ollama.com and start the app.
  echo   The shared server ^(if you paste the key below^) works regardless.
  echo.
)
set "KEY="
set /p KEY=Paste the shared-server key from the LMS announcement (or press Enter to skip):
if "%KEY%"=="" goto localonly

> "%F%" echo {
>> "%F%" echo   "providers": {
>> "%F%" echo     "ollama": { "baseUrl": "http://localhost:11434/v1", "api": "openai-completions", "apiKey": "ollama", "models": [ { "id": "qwen3:8b" }, { "id": "qwen3:4b" } ] },
>> "%F%" echo     "ollama-curtin": { "baseUrl": "https://ollama.locollm.org/v1", "api": "openai-completions", "apiKey": "%KEY%", "compat": { "supportsDeveloperRole": false, "supportsReasoningEffort": false }, "models": [ { "id": "granite4.2:8b" }, { "id": "granite4.2:3b" }, { "id": "gemma4:e4b" }, { "id": "gemma4:12b" }, { "id": "llama3.1:latest" } ] }
>> "%F%" echo   }
>> "%F%" echo }
goto done

:localonly
> "%F%" echo {
>> "%F%" echo   "providers": {
>> "%F%" echo     "ollama": { "baseUrl": "http://localhost:11434/v1", "api": "openai-completions", "apiKey": "ollama", "models": [ { "id": "qwen3:8b" }, { "id": "qwen3:4b" } ] }
>> "%F%" echo   }
>> "%F%" echo }

:done
echo Done: %F%
echo Make sure Ollama is running, then start Pi with:
echo   pi --provider ollama --model qwen3:8b
echo (If "ollama list" shows qwen3:4b instead, use that as the model name.)
pause

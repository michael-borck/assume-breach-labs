@echo off
REM Assume Breach Labs — Windows entry point. Requires Docker Desktop + Git Bash
REM (installed with Git for Windows). Delegates to the bash console.
where bash >nul 2>nul
if errorlevel 1 (
  echo Git Bash is required. Install "Git for Windows" from https://git-scm.com/download/win
  echo Then double-click start.sh, or run:  bash start.sh
  pause
  exit /b 1
)
bash "%~dp0start.sh" %*

@echo off
setlocal

:: Change to the directory where this script is located
cd /d "%~dp0"

:: Prompt for commit message
set /p msg="Enter commit message: "

:: Add all changes
git add .

:: Commit with the message
git commit -m "%msg%"

:: Pull remote changes first (rebase to keep history clean)
echo.
echo Pulling latest changes from remote...
git pull --rebase

:: Check if pull succeeded
if errorlevel 1 (
    echo.
    echo CONFLICT DETECTED! Fix the conflicts manually, then run:
    echo   git rebase --continue
    echo   git push
    pause
    exit /b 1
)

:: Push to origin
git push

echo.
echo Done! Your code has been pushed.
pause
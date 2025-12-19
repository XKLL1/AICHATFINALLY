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

:: Push to origin
git push

echo.
echo Done! Your code has been pushed.
pause
@echo off
echo 正在启动大数据学习平台环境...
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\start_environment.ps1"
pause
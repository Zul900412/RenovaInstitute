@echo off
cd /d "%~dp0"
start "Renova Server" /min python admin\server.py
timeout /t 1 /nobreak >nul
start "Renova Admin" http://127.0.0.1:8000/admin/

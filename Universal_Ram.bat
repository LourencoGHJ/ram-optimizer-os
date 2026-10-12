@echo off
title [CONNECT LABS] - RAM & Memory Pipeline Core v5.0
mode con: cols=104 lines=48

:: ====================================================================
:: Launcher: admin check, then evidence-based PowerShell engine
:: ====================================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 0C
    echo =======================================================================
    echo [ERRO / ERROR] ACESSO NEGADO / ACCESS DENIED!
    echo =======================================================================
    echo  Este script precisa de permissoes de Administrador.
    echo  Clica com o botao direito e escolhe "EXECUTAR COMO ADMINISTRADOR".
    echo  Right-click this file and choose "RUN AS ADMINISTRATOR".
    echo =======================================================================
    pause
    exit /b 1
)

cd /d "%~dp0"
if not exist "%~dp0ConnectRamCore.ps1" (
    color 0C
    echo [ERRO] ConnectRamCore.ps1 nao encontrado na mesma pasta.
    echo [ERROR] ConnectRamCore.ps1 must sit next to this .bat file.
    pause
    exit /b 1
)

chcp 65001 >nul
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0ConnectRamCore.ps1" %*
exit /b %ERRORLEVEL%

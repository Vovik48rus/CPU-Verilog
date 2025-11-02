@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ===============================
REM 1. Проверка установлен ли Python
REM ===============================
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python не найден. Установите Python 3.13 или новее.
    exit /b 1
)

REM ===============================
REM 2. Проверка версии Python
REM ===============================
for /f "tokens=2 delims= " %%v in ('python -V 2^>^&1') do set PY_VER=%%v
for /f "tokens=1,2 delims=." %%a in ("%PY_VER%") do (
    set PY_MAJOR=%%a
    set PY_MINOR=%%b
)

if %PY_MAJOR% lss 3 (
    echo [ERROR] Требуется Python >= 3.13, найден %PY_VER%
    exit /b 1
)

if %PY_MAJOR%==3 if %PY_MINOR% lss 10 (
    echo [ERROR] Требуется Python >= 3.13, найден %PY_VER%
    exit /b 1
)

if %PY_MAJOR%==3 if %PY_MINOR% lss 13 (
    echo [WARNING] Проект был протестирован на Python 3.13, на установленной версии Python проект может работать некорректно, найден %PY_VER%
    exit /b 1
)

echo [OK] Найден Python версии %PY_VER%

REM ===============================
REM 3. Проверка наличия виртуальной среды
REM ===============================
if exist ".venv\" (
    echo [INFO] Виртуальная среда уже существует.
) else (
    echo [INFO] Создаём виртуальную среду...
    python -m pip install --upgrade pip >nul
    python -m pip install virtualenv >nul
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo [ERROR] Не удалось создать виртуальную среду.
        exit /b 1
    )
)

REM ===============================
REM 4. Активация виртуальной среды
REM ===============================
call .venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo [ERROR] Не удалось активировать виртуальную среду.
    exit /b 1
)
echo [OK] Виртуальная среда активирована.

REM ===============================
REM 5. Обновление pip и установка зависимостей
REM ===============================
echo [INFO] Обновляем pip...
python -m pip install --upgrade pip >nul

if exist "requirements.txt" (
    echo [INFO] Устанавливаем зависимости из requirements.txt...
    pip install -r requirements.txt
    if %errorlevel% neq 0 (
        echo [ERROR] Ошибка установки зависимостей.
        exit /b 1
    )
) else (
    echo [WARN] Файл requirements.txt не найден, пропускаем установку зависимостей.
)

echo.
echo [SUCCESS] Среда готова к работе!
echo Для выхода из виртуальной среды используйте команду: deactivate
endlocal
pause

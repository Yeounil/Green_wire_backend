@echo off
REM Playwright 브라우저 설치 스크립트 (Windows용)
echo ========================================
echo Playwright Chromium 브라우저 설치 중...
echo ========================================

REM 가상환경 활성화 확인
if exist "venv\Scripts\activate.bat" (
    echo [INFO] 가상환경 활성화 중...
    call venv\Scripts\activate.bat
) else (
    echo [WARN] 가상환경을 찾을 수 없습니다. 전역으로 설치합니다.
)

REM Playwright 설치 (이미 설치되어 있을 수 있음)
echo.
echo [1/2] Playwright 패키지 확인 중...
python -m pip install playwright>=1.40.0

REM Chromium 브라우저 설치
echo.
echo [2/2] Chromium 브라우저 설치 중...
python -m playwright install chromium

REM 시스템 의존성 설치 (Windows에서는 보통 필요 없음)
echo.
echo [INFO] 시스템 의존성 확인 중...
python -m playwright install-deps chromium

echo.
echo ========================================
echo ✅ Playwright Chromium 설치 완료!
echo ========================================
echo.
echo 설치된 브라우저 확인:
python -m playwright install --help

pause

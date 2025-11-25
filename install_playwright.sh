#!/bin/bash
# Playwright 브라우저 설치 스크립트 (Linux/Mac용)

echo "========================================"
echo "Playwright Chromium 브라우저 설치 중..."
echo "========================================"

# 가상환경 활성화 확인
if [ -f "venv/bin/activate" ]; then
    echo "[INFO] 가상환경 활성화 중..."
    source venv/bin/activate
else
    echo "[WARN] 가상환경을 찾을 수 없습니다. 전역으로 설치합니다."
fi

# Playwright 설치 (이미 설치되어 있을 수 있음)
echo ""
echo "[1/3] Playwright 패키지 확인 중..."
python -m pip install playwright>=1.40.0

# Chromium 브라우저 설치
echo ""
echo "[2/3] Chromium 브라우저 설치 중..."
python -m playwright install chromium

# 시스템 의존성 설치
echo ""
echo "[3/3] 시스템 의존성 설치 중..."
python -m playwright install-deps chromium

echo ""
echo "========================================"
echo "✅ Playwright Chromium 설치 완료!"
echo "========================================"
echo ""
echo "설치 확인:"
python -c "from playwright.sync_api import sync_playwright; print('Playwright 정상 작동')"

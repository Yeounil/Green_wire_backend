FROM python:3.11-slim

# 시스템 패키지 업데이트 및 Playwright 의존성 설치
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Python 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Playwright Chromium 브라우저 설치
RUN python -m playwright install chromium
RUN python -m playwright install-deps chromium

# 애플리케이션 파일 복사
COPY . .

# 실행 권한 부여
RUN chmod +x start.sh

# 포트 노출
EXPOSE 8080

# 환경 변수 기본값 설정
ENV PORT=8080
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# 헬스체크 추가
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/health', timeout=5)"

# 실행
CMD ["./start.sh"]

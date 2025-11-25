@echo off
REM Google Cloud Run 배포 스크립트 (Windows용)

echo ==========================================
echo Google Cloud Run 배포 스크립트
echo ==========================================

REM 프로젝트 ID 확인
if "%GCP_PROJECT_ID%"=="" (
    echo ❌ GCP_PROJECT_ID 환경 변수가 설정되지 않았습니다.
    echo 실행: set GCP_PROJECT_ID=your-project-id
    pause
    exit /b 1
)

set PROJECT_ID=%GCP_PROJECT_ID%
set REGION=asia-northeast3
set SERVICE_NAME=ms-ai-foundry-backend

echo 프로젝트 ID: %PROJECT_ID%
echo 리전: %REGION%
echo 서비스 이름: %SERVICE_NAME%
echo.

REM 1. gcloud 프로젝트 설정
echo 📌 [1/6] gcloud 프로젝트 설정 중...
gcloud config set project %PROJECT_ID%

REM 2. API 활성화
echo 📌 [2/6] 필요한 API 활성화 중...
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable containerregistry.googleapis.com

REM 3. Cloud Build로 빌드 및 배포
echo 📌 [3/6] Cloud Build로 빌드 및 배포 시작...
gcloud builds submit --config cloudbuild.yaml --timeout=30m

echo.
echo ✅ 배포가 완료되었습니다!
echo.

REM 4. 배포된 서비스 정보 조회
echo 📌 [4/6] 배포된 서비스 정보 조회...
gcloud run services describe %SERVICE_NAME% --region=%REGION% --format="value(status.url)"

for /f %%i in ('gcloud run services describe %SERVICE_NAME% --region=%REGION% --format="value(status.url)"') do set SERVICE_URL=%%i
echo.
echo 🌐 서비스 URL: %SERVICE_URL%
echo.

REM 5. 환경 변수 설정 안내
echo 📌 [5/6] 환경 변수 설정 필요!
echo.
echo Secret Manager에서 환경 변수를 설정하세요:
echo https://console.cloud.google.com/security/secret-manager?project=%PROJECT_ID%
echo.
echo 필요한 환경 변수:
echo - SECRET_KEY
echo - SUPABASE_URL
echo - SUPABASE_KEY
echo - OPENAI_API_KEY
echo - ANTHROPIC_API_KEY
echo - NEWS_API_KEY
echo - FMP_API_KEY
echo - PINECONE_API_KEY
echo.

REM 6. 헬스 체크
echo 📌 [6/6] 헬스 체크 실행 중...
timeout /t 10 /nobreak > nul
curl -s %SERVICE_URL%/health

echo.
echo ==========================================
echo 배포 완료!
echo ==========================================
echo 📝 다음 단계:
echo 1. Secret Manager에서 환경 변수 설정
echo 2. 서비스 URL 확인: %SERVICE_URL%
echo 3. Swagger 문서: %SERVICE_URL%/docs
echo 4. 헬스 체크: %SERVICE_URL%/health
echo.

pause

#!/bin/bash
# Google Cloud Run 배포 스크립트

set -e

echo "=========================================="
echo "Google Cloud Run 배포 스크립트"
echo "=========================================="

# 프로젝트 ID 확인
if [ -z "$GCP_PROJECT_ID" ]; then
    echo "❌ GCP_PROJECT_ID 환경 변수가 설정되지 않았습니다."
    echo "실행: export GCP_PROJECT_ID=your-project-id"
    exit 1
fi

PROJECT_ID=$GCP_PROJECT_ID
REGION="asia-northeast3"
SERVICE_NAME="ms-ai-foundry-backend"

echo "프로젝트 ID: $PROJECT_ID"
echo "리전: $REGION"
echo "서비스 이름: $SERVICE_NAME"
echo ""

# 1. gcloud 프로젝트 설정
echo "📌 [1/6] gcloud 프로젝트 설정 중..."
gcloud config set project $PROJECT_ID

# 2. API 활성화
echo "📌 [2/6] 필요한 API 활성화 중..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable containerregistry.googleapis.com

# 3. Cloud Build로 빌드 및 배포
echo "📌 [3/6] Cloud Build로 빌드 및 배포 시작..."
gcloud builds submit --config cloudbuild.yaml --timeout=30m

echo ""
echo "✅ 배포가 완료되었습니다!"
echo ""

# 4. 배포된 서비스 정보 조회
echo "📌 [4/6] 배포된 서비스 정보 조회..."
gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)"

SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
echo ""
echo "🌐 서비스 URL: $SERVICE_URL"
echo ""

# 5. 환경 변수 설정 안내
echo "📌 [5/6] 환경 변수 설정 필요!"
echo ""
echo "다음 명령어로 환경 변수를 설정하세요:"
echo ""
echo "gcloud run services update $SERVICE_NAME \\"
echo "  --region=$REGION \\"
echo "  --update-secrets=SECRET_KEY=SECRET_KEY:latest,\\"
echo "SUPABASE_URL=SUPABASE_URL:latest,\\"
echo "SUPABASE_KEY=SUPABASE_KEY:latest,\\"
echo "OPENAI_API_KEY=OPENAI_API_KEY:latest,\\"
echo "ANTHROPIC_API_KEY=ANTHROPIC_API_KEY:latest,\\"
echo "NEWS_API_KEY=NEWS_API_KEY:latest,\\"
echo "FMP_API_KEY=FMP_API_KEY:latest,\\"
echo "PINECONE_API_KEY=PINECONE_API_KEY:latest"
echo ""
echo "또는 Secret Manager에서 수동으로 설정:"
echo "https://console.cloud.google.com/security/secret-manager?project=$PROJECT_ID"
echo ""

# 6. 헬스 체크
echo "📌 [6/6] 헬스 체크 실행 중..."
sleep 10
curl -s $SERVICE_URL/health | python -m json.tool || echo "⚠️ 헬스 체크 실패 (환경 변수 미설정 가능)"

echo ""
echo "=========================================="
echo "배포 완료!"
echo "=========================================="
echo "📝 다음 단계:"
echo "1. Secret Manager에서 환경 변수 설정"
echo "2. 서비스 URL 확인: $SERVICE_URL"
echo "3. Swagger 문서: $SERVICE_URL/docs"
echo "4. 헬스 체크: $SERVICE_URL/health"
echo ""

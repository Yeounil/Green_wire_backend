# GitHub → Google Cloud Run 자동 배포 가이드

GitHub에서 Google Cloud Run으로 자동 배포를 설정하는 방법입니다.

## 📋 목차

1. [방법 1: Cloud Console에서 설정 (가장 쉬움)](#방법-1-cloud-console에서-설정)
2. [방법 2: GitHub Actions 사용 (더 유연함)](#방법-2-github-actions-사용)
3. [배포 확인 및 테스트](#배포-확인-및-테스트)
4. [트러블슈팅](#트러블슈팅)

---

## 방법 1: Cloud Console에서 설정

### 1단계: 사전 준비

- [x] GitHub 저장소에 코드 push 완료
- [x] GCP 프로젝트 생성 및 결제 활성화
- [x] Secret Manager에 환경 변수 등록 완료

### 2단계: Cloud Run 콘솔 접속

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 상단에서 **프로젝트 선택**
3. 왼쪽 메뉴 → **Cloud Run**
4. **서비스 만들기** 클릭

### 3단계: GitHub 저장소 연결

#### 소스 설정:

1. **"Continuously deploy from a repository"** 선택
2. **SET UP WITH CLOUD BUILD** 클릭

#### Cloud Build 설정:

1. **Repository Provider**: GitHub 선택
2. **Authenticate** 클릭 → GitHub 계정 연결
3. **저장소 선택**:
   ```
   Repository: your-username/Microsoft_AI_Foundary
   Branch: ^main$
   ```
4. **Build Configuration**:
   ```
   Build Type: Dockerfile
   Source location: /backend/Dockerfile
   ```

   또는

   ```
   Build Type: Cloud Build configuration file
   Source location: /backend/cloudbuild.yaml
   ```

5. **SAVE** 클릭

### 4단계: 서비스 설정

#### 기본 설정:

```yaml
서비스 이름: ms-ai-foundry-backend
리전: asia-northeast3 (서울)
```

#### 컨테이너 설정:

**Container(s), Volumes, Networking, Security** 탭:

```yaml
Container port: 8080

Resources:
  Memory: 2 GiB
  CPU: 2
  Request timeout: 300 (5분)
  Maximum requests per container: 80

Execution environment: First generation (권장)
```

#### Auto-scaling:

```yaml
Minimum number of instances: 0
  (콜드 스타트 방지 시: 1)

Maximum number of instances: 10
```

#### Authentication:

```
☑️ Allow unauthenticated invocations
```

(공개 API인 경우 체크, 인증 필요 시 체크 해제)

### 5단계: 환경 변수 및 Secret 설정

**Variables & Secrets** 탭으로 이동:

#### Secret 참조:

**REFERENCE A SECRET** 버튼 클릭하여 하나씩 추가:

| Secret 이름 | 마운트 방식 | 버전 |
|------------|------------|------|
| SECRET_KEY | Environment variable | latest |
| SUPABASE_URL | Environment variable | latest |
| SUPABASE_KEY | Environment variable | latest |
| OPENAI_API_KEY | Environment variable | latest |
| ANTHROPIC_API_KEY | Environment variable | latest |
| NEWS_API_KEY | Environment variable | latest |
| FMP_API_KEY | Environment variable | latest |
| PINECONE_API_KEY | Environment variable | latest |
| PINECONE_INDEX_NAME | Environment variable | latest |
| PINECONE_ENVIRONMENT | Environment variable | latest |
| RESEND_API_KEY | Environment variable | latest |

#### 일반 환경 변수:

**ADD VARIABLE** 버튼 클릭:

| Name | Value |
|------|-------|
| PORT | 8080 |
| PYTHONUNBUFFERED | 1 |
| ENVIRONMENT | production |
| ALGORITHM | HS256 |
| ACCESS_TOKEN_EXPIRE_MINUTES | 30 |

### 6단계: 고급 설정 (선택)

**Advanced Settings** 확장:

#### Cloud SQL connections (DB 사용 시):
- 없음 (Supabase 사용)

#### VPC connector:
- 없음 (기본값)

#### Service account:
- Default Compute Engine service account (기본값)

### 7단계: 배포 시작

**CREATE** 버튼 클릭! 🎉

#### 배포 진행 확인:

1. Cloud Build 페이지로 자동 이동
2. 빌드 로그 실시간 확인 (20-30분 소요)
3. 완료되면 서비스 URL 표시

---

## 방법 2: GitHub Actions 사용

### 1단계: 서비스 계정 생성

#### GCP Console에서:

1. **IAM & Admin** → **Service Accounts**
2. **CREATE SERVICE ACCOUNT** 클릭
3. 정보 입력:
   ```
   Name: github-actions-deployer
   Description: Service account for GitHub Actions deployments
   ```
4. 권한 부여:
   ```
   - Cloud Build Editor
   - Cloud Run Admin
   - Service Account User
   - Storage Admin
   ```
5. **CREATE KEY** → JSON 다운로드

### 2단계: GitHub Secrets 설정

#### GitHub 저장소에서:

1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** 클릭

**필수 Secrets**:

| Name | Value |
|------|-------|
| `GCP_PROJECT_ID` | your-project-id |
| `GCP_SA_KEY` | JSON 키 전체 내용 붙여넣기 |

**선택 Secrets** (Slack 알림 등):

| Name | Value |
|------|-------|
| `SLACK_WEBHOOK_URL` | https://hooks.slack.com/... |

### 3단계: GitHub Actions 워크플로우 파일 확인

이미 생성된 파일 확인:
```
.github/workflows/deploy-to-cloud-run.yml
```

### 4단계: Git Push로 자동 배포

```bash
# 변경사항 커밋
git add .
git commit -m "Add GitHub Actions deployment"

# GitHub에 push
git push origin main
```

#### 배포 확인:

1. GitHub 저장소 → **Actions** 탭
2. 워크플로우 실행 상태 확인
3. 로그 실시간 확인 가능

---

## 배포 확인 및 테스트

### 1. 서비스 URL 확인

#### Cloud Console에서:

1. **Cloud Run** → 서비스 클릭
2. 상단에 서비스 URL 표시
   ```
   https://ms-ai-foundry-backend-xxxxx-an.a.run.app
   ```

#### gcloud CLI에서:

```bash
gcloud run services describe ms-ai-foundry-backend \
  --region=asia-northeast3 \
  --format="value(status.url)"
```

### 2. 헬스 체크

```bash
# 기본 헬스 체크
curl https://your-service-url.run.app/health

# 상세 헬스 체크
curl https://your-service-url.run.app/health/detailed
```

### 3. Swagger 문서 확인

브라우저에서 접속:
```
https://your-service-url.run.app/docs
```

### 4. 로그 확인

#### Cloud Console에서:

**Cloud Run** → 서비스 → **LOGS** 탭

#### gcloud CLI에서:

```bash
# 실시간 로그
gcloud run services logs tail ms-ai-foundry-backend \
  --region=asia-northeast3

# 최근 로그
gcloud run services logs read ms-ai-foundry-backend \
  --region=asia-northeast3 \
  --limit=50
```

---

## 자동 배포 동작 방식

### Console 방식:

```
GitHub Push
    ↓
Cloud Build 자동 트리거
    ↓
Docker 이미지 빌드
    ↓
Container Registry 저장
    ↓
Cloud Run 자동 배포
    ↓
새 리비전 생성
    ↓
트래픽 100% 전환
```

### GitHub Actions 방식:

```
GitHub Push
    ↓
GitHub Actions 실행
    ↓
GCP 인증
    ↓
Cloud Build Submit
    ↓
Docker 이미지 빌드
    ↓
Cloud Run 배포
    ↓
Secret 업데이트
    ↓
헬스 체크
    ↓
Slack 알림 (선택)
```

---

## 트러블슈팅

### 문제 1: "Permission denied" 오류

**원인**: 서비스 계정 권한 부족

**해결**:
```bash
# Cloud Build 서비스 계정에 Cloud Run Admin 권한 부여
PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT_ID --format="value(projectNumber)")

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

### 문제 2: Dockerfile을 찾을 수 없음

**원인**: Dockerfile 경로 오류

**해결**:
- Repository root에서의 상대 경로 확인
- `/backend/Dockerfile` 경로 정확히 입력
- 또는 `cloudbuild.yaml` 사용

### 문제 3: 빌드 타임아웃

**원인**: Playwright 설치 시간 초과

**해결**:

`cloudbuild.yaml`에서 타임아웃 증가:
```yaml
timeout: 1800s  # 30분
```

또는 Cloud Console에서:
```
Build timeout: 30분
```

### 문제 4: Secret을 찾을 수 없음

**원인**: Secret Manager에 Secret 미등록

**해결**:
```bash
# Secret 목록 확인
gcloud secrets list

# 누락된 Secret 생성
echo -n "your-secret-value" | gcloud secrets create SECRET_NAME --data-file=-
```

### 문제 5: 메모리 부족

**원인**: PDF 생성 시 메모리 초과

**해결**:

메모리 증가:
```bash
gcloud run services update ms-ai-foundry-backend \
  --region=asia-northeast3 \
  --memory=4Gi
```

또는 Console에서:
```
Memory: 4 GiB
```

### 문제 6: CORS 오류

**원인**: 프론트엔드 도메인 미설정

**해결**:

환경 변수 추가:
```bash
gcloud run services update ms-ai-foundry-backend \
  --region=asia-northeast3 \
  --set-env-vars=CORS_ORIGINS=https://your-frontend.com,http://localhost:3000
```

---

## 배포 워크플로우 커스터마이징

### 특정 브랜치만 배포

`.github/workflows/deploy-to-cloud-run.yml`:

```yaml
on:
  push:
    branches:
      - main
      - production  # production 브랜치 추가
```

### 수동 배포만 허용

```yaml
on:
  workflow_dispatch:  # 수동 실행만
```

### 태그 기반 배포

```yaml
on:
  push:
    tags:
      - 'v*'  # v1.0.0 형식의 태그에만 배포
```

### 배포 환경 분리

```yaml
jobs:
  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    # ... staging 배포

  deploy-production:
    if: github.ref == 'refs/heads/main'
    # ... production 배포
```

---

## 롤백 방법

### Console에서:

1. **Cloud Run** → 서비스 클릭
2. **REVISIONS** 탭
3. 이전 리비전 선택
4. **MANAGE TRAFFIC** → 100% 할당

### gcloud CLI:

```bash
# 리비전 목록 확인
gcloud run revisions list --service=ms-ai-foundry-backend --region=asia-northeast3

# 특정 리비전으로 롤백
gcloud run services update-traffic ms-ai-foundry-backend \
  --region=asia-northeast3 \
  --to-revisions=REVISION_NAME=100
```

---

## 비용 최적화

### 권장 설정:

```yaml
Memory: 2 GiB (기본) → 필요시 4 GiB
CPU: 2 (기본)
Min instances: 0 (비용 절감) → 성능 중요시 1
Max instances: 10
Request timeout: 300s
```

### 예상 비용:

- **Min instances = 0**: $10-30/월
- **Min instances = 1**: $50-100/월

---

## 체크리스트

### Console 배포:

- [ ] GitHub 저장소 연결
- [ ] Dockerfile 경로 설정
- [ ] 리전 선택: asia-northeast3
- [ ] Secret 모두 연결
- [ ] 환경 변수 설정
- [ ] 메모리/CPU 설정
- [ ] 배포 완료
- [ ] 헬스 체크 성공

### GitHub Actions 배포:

- [ ] 서비스 계정 생성
- [ ] JSON 키 다운로드
- [ ] GitHub Secrets 설정
- [ ] 워크플로우 파일 커밋
- [ ] Push 후 Actions 탭 확인
- [ ] 배포 성공 확인
- [ ] 헬스 체크 성공

---

## 다음 단계

1. **모니터링 설정**: Cloud Monitoring 알림
2. **로그 분석**: 정기적인 로그 리뷰
3. **성능 튜닝**: 메모리/CPU 최적화
4. **보안 강화**: VPC, IAM 정책 검토

---

**작성일**: 2025-11-26
**버전**: 1.0.0

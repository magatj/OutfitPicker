# OutfitPicker — Claude Project Memory

## What This App Is
AI-powered styling platform. Users upload closet photos, AI detects clothing items,
builds a digital wardrobe, generates outfit recommendations, and visualizes outfits.

## Tech Stack
- Frontend: React (web first, React Native later)
- Backend: FastAPI + Docker
- Cloud: AWS
- IaC: Terraform (required)
- Auth: AWS Cognito
- Storage: Amazon S3
- Database: DynamoDB (PAY_PER_REQUEST, single-table design)
- Async jobs: SQS + Lambda
- Container registry: ECR
- Backend compute: AWS App Runner
- CDN: CloudFront + S3

## Repository Structure
```
OutfitPicker/
  Dockerfile              # FastAPI production image
  docker-compose.yml      # local dev (to be created)
  .gitignore
  CLAUDE.md
  terraform/
    bootstrap/            # one-time: creates S3 state bucket + DynamoDB lock table
    modules/              # ecr, auth, storage, database, iam, queue, backend, frontend, monitoring
    environments/         # dev / stage / prod
  backend/                # FastAPI app (to be created)
  frontend/               # React app (to be created)
```

## Architecture Decisions Made
- App Runner over ECS Fargate: no ALB cost, no cluster ops, ~$5/mo idle
- DynamoDB over RDS: $0 idle, scales infinitely, fits user-scoped access patterns
- SQS + Lambda over container workers: free tier covers MVP, Rekognition jobs finish in <10s
- S3 + CloudFront over Amplify: full control, cheapest, no vendor lock-in
- AWS Rekognition over Google Vision: native S3+IAM, 5K free images/mo, swappable later
- Rule-based recommendations first: ship faster, add ML after real user data exists
- React collage preview for MVP: zero AI cost, gate real try-on (Replicate) behind credits

## AI Integration Flow
1. User uploads photo → S3 (presigned URL, no backend proxy)
2. POST /uploads/{id}/complete → FastAPI writes job to DynamoDB + sends to SQS
3. SQS triggers Lambda worker automatically
4. Lambda calls AWS Rekognition → detect_labels on S3 image
5. Lambda crops bounding boxes → saves thumbnails to S3
6. Lambda writes WardrobeItems to DynamoDB (confidence, ai_source, raw_output saved)
7. User reviews detected items, can correct category/color/name
8. Rule-based engine generates outfit recommendations from wardrobe
9. React collage renders outfit preview (no AI cost in MVP)

## DynamoDB Single-Table Key Design
- PK: USER#{user_id}  SK: ITEM#{item_id}        → wardrobe items
- PK: USER#{user_id}  SK: UPLOAD#{upload_id}     → closet uploads
- PK: USER#{user_id}  SK: OUTFIT#{outfit_id}     → outfits
- PK: JOB#{job_id}    SK: META                   → processing jobs
- GSI1: GSI1PK / GSI1SK → look up items by upload, jobs by user

## Mobile Strategy
- Web app is mobile-responsive from day one
- Add PWA support (manifest + service worker) for home screen install
- React Native added later as second client — backend/terraform unchanged
- Same Cognito auth, same API endpoints, same S3 presigned URL flow
- Expo Go used for React Native device testing during development
- Apple Developer ($99/yr) + Google Play Console ($25) needed for App Store submission
- Native camera needed eventually for closet photo uploads → main reason to go React Native

## Phone Testing Approach
- Now (web): open CloudFront URL in phone browser
- PWA: add to home screen, works like native app
- React Native (later): install Expo Go app, scan QR code from dev machine
- App Store release: download like any app

## Cost Estimates
- Just you testing: ~$5-6/mo (App Runner minimum, everything else free tier)
- 50-100 beta users: ~$25-40/mo
- 500-1000 users: ~$90-175/mo
- Virtual try-on (Replicate): $0.05-$0.20/call — MUST be credit-gated

## MVP Build Order
- Phase 0: Terraform bootstrap + AWS infra ← CURRENT
- Phase 1: Auth + React frontend shell
- Phase 2: Uploads + S3 storage
- Phase 3: AI closet detection (Rekognition + Lambda)
- Phase 4: Wardrobe review/edit UI
- Phase 5: Rule-based outfit recommendations
- Phase 6: Preview (collage placeholder)
- Phase 7: Production hardening

## What To Postpone
- Virtual try-on (expensive, add after paying users)
- ML personalization (need data first)
- React Native (ship web first)
- Social login (Cognito supports it, add when users ask)
- Custom domain (add in Phase 7)
- ECS Fargate workers (only if GPU jobs needed)

## Environment Differences
- dev: deletion protection off, no PITR, 14-day logs, 256CPU/512MB
- stage: same as dev config
- prod: deletion protection ON, PITR ON, 90-day logs, 512CPU/1024MB

## First Commands To Run
```bash
cd terraform/bootstrap && terraform init && terraform apply
cd terraform/environments/dev && terraform init && terraform apply
```

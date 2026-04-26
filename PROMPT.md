# OutfitPicker — Full Build Prompt

## What You Are Building

An AI-powered personal styling platform called **OutfitPicker**. Users photograph their physical closet, AI detects and catalogs every clothing item automatically, builds a digital wardrobe, generates outfit recommendations from what they actually own, and lets them virtually try on outfits using a photo of themselves.

---

## Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Frontend | React (web-first, PWA) | Mobile-responsive from day one; React Native added later |
| Backend | FastAPI + Docker | Python ecosystem fits AI/ML integrations |
| Cloud | AWS | Native integrations with Rekognition, S3, Cognito |
| IaC | Terraform (required) | All infrastructure must be code |
| Auth | AWS Cognito | Built-in user pools, JWT, social login ready |
| Storage | Amazon S3 | Presigned URLs for direct client uploads |
| Database | DynamoDB (PAY_PER_REQUEST, single-table) | $0 idle, scales infinitely, user-scoped access patterns |
| Async jobs | SQS + Lambda | Free tier covers MVP; Rekognition jobs finish in <10s |
| Container registry | ECR | |
| Backend compute | AWS App Runner | No ALB cost, no cluster ops, ~$5/mo idle |
| CDN | CloudFront + S3 | Full control, cheapest, no vendor lock-in |
| AI detection | AWS Rekognition | Native S3+IAM, 5K free images/mo |
| Virtual try-on | Replicate API | AI diffusion models, $0.05–$0.20/call, credit-gated |
| Recommendations | Rule-based engine (MVP) | Ship faster; add ML after real user data exists |

---

## Repository Structure

```
OutfitPicker/
  Dockerfile                  # FastAPI production image
  docker-compose.yml          # Local dev
  CLAUDE.md                   # Project memory
  frontend/
    prototype.html            # Self-contained React prototype (no build step)
  docs/
    index.html                # GitHub Pages deployment (copy of prototype)
  terraform/
    bootstrap/                # One-time: S3 state bucket + DynamoDB lock table
    modules/                  # ecr, auth, storage, database, iam, queue, backend, frontend, monitoring
    environments/             # dev / stage / prod
  backend/                    # FastAPI app (to be built)
```

---

## DynamoDB Single-Table Key Design

| PK | SK | Record |
|---|---|---|
| `USER#{user_id}` | `ITEM#{item_id}` | Wardrobe items |
| `USER#{user_id}` | `UPLOAD#{upload_id}` | Closet uploads |
| `USER#{user_id}` | `OUTFIT#{outfit_id}` | Saved outfits |
| `JOB#{job_id}` | `META` | Processing jobs |

GSI1: `GSI1PK` / `GSI1SK` — look up items by upload, jobs by user.

---

## AI Integration Flow

1. User uploads closet photo → S3 via presigned URL (no backend proxy)
2. `POST /uploads/{id}/complete` → FastAPI writes job to DynamoDB + sends to SQS
3. SQS triggers Lambda worker automatically
4. Lambda calls `Rekognition.detect_labels` on the S3 image
5. Lambda crops bounding boxes → saves thumbnails to S3
6. Lambda writes `WardrobeItem` records to DynamoDB (confidence, ai_source, raw_output saved)
7. User reviews detected items, can correct category/color/name
8. Rule-based engine generates outfit recommendations from wardrobe
9. React renders outfit collage preview (MVP — no AI cost)
10. Virtual try-on: user photo + clothing item → Replicate API → rendered result (credit-gated)

---

## Environment Differences

| Setting | dev/stage | prod |
|---|---|---|
| Deletion protection | Off | On |
| PITR | Off | On |
| Log retention | 14 days | 90 days |
| App Runner CPU/RAM | 256/512MB | 512/1024MB |

---

## MVP Build Phases

- **Phase 0** — Terraform bootstrap + AWS infra ✅ Done
- **Phase 1** — Auth + React frontend shell
- **Phase 2** — Uploads + S3 storage
- **Phase 3** — AI closet detection (Rekognition + Lambda)
- **Phase 4** — Wardrobe review/edit UI
- **Phase 5** — Rule-based outfit recommendations
- **Phase 6** — Collage preview (placeholder for virtual try-on)
- **Phase 7** — Production hardening

**Postpone:** Virtual try-on (Replicate), ML personalization, React Native, social login, custom domain, ECS Fargate workers.

---

## Cost Estimates

| Usage | Monthly cost |
|---|---|
| Solo testing | ~$5–6/mo |
| 50–100 beta users | ~$25–40/mo |
| 500–1000 users | ~$90–175/mo |
| Virtual try-on (Replicate) | $0.05–$0.20/call — must be credit-gated |

---

## UI — Design System

**Colors:**
- Brand: purple — `#a855f7` (500), `#9333ea` (600), `#7e22ce` (700)
- Brand light: `#fdf4ff` (50), `#fae8ff` (100)
- Sidebar/dark: ink — `#0f0f11` (900), `#1a1a1f` (800), `#25252d` (700)
- Background: `#f8f7f5` (warm off-white, not pure gray)

**Typography:**
- Body/UI: Inter (300–900)
- Display headings: Playfair Display (700, 900, italic) — used for screen titles, outfit names, hero text

**Border radius:** `rounded-2xl` (cards), `rounded-3xl` (hero cards, modals)

**Animations:**
- `fade-in`: `opacity 0→1 + translateY 6px→0`, 0.28s ease
- `slide-up`: 0.32s cubic-bezier(0.22,1,0.36,1)
- `card-pop`: scale 0.92→1, cubic-bezier(0.34,1.56,0.64,1)
- `shimmer`: loading skeleton gradient
- `pulse-ring`: expanding ring for AI loading states
- `spin-icon`: 360° rotation for shuffle button

---

## UI — Navigation

**Sidebar (desktop, dark ink background):**
- Logo: "OP" badge + "OutfitPicker" wordmark
- Primary nav (large): Try On 🪞, Outfits ✨
- Secondary nav (smaller, under "Library" divider): Wardrobe 👗, Upload 📸
- Bottom: AI Credits progress bar, How it works button, user avatar + name/email
- Active state: left purple accent bar + `bg-ink-700`

**Mobile bottom nav:**
- Primary items (Try On, Outfits): larger text, `font-black`
- Secondary items (Wardrobe, Upload): smaller, muted

**Default view on load:** Outfits (after onboarding completes)
**Skip tour navigates to:** Try On

---

## UI — Screens

### 1. Welcome Modal (on first load)
- Full-screen dark blurred overlay
- White card, max-w-sm, rounded-3xl
- Hero: gradient + fashion photo with 👗 emoji overlay
- Title (Playfair Display): "Welcome to OutfitPicker"
- Description: brief 2-line pitch
- 4-step progress strip (colored gradient bars, one per step)
- "Let's get started →" primary CTA
- "Skip for now" text link → navigates to Try On

### 2. Guided Tour (floating bottom bar, 4 steps)
Step 1 — Upload your closet
Step 2 — Review your wardrobe
Step 3 — Pick an outfit
Step 4 — Try it on

Each step shows:
- Gradient emoji icon, step number, heading, instruction text
- 💡 tip card
- Colored "Do it now →" CTA that navigates to the relevant screen and advances the step
- Back ← and "Skip step" buttons
- Progress bar across the top of the bar (fills as steps complete)
- ✕ to dismiss (navigates to Try On)

On tour complete: toast "You're all set! Enjoy OutfitPicker 🎉"
"How it works" in sidebar replays from welcome modal.

---

### 3. Outfits Screen (default)

**Hero banner:** Full-bleed featured outfit photo (h-64), gradient overlay, "Today's Pick" label (small caps), outfit name in Playfair Display, score ring top-right. Clickable — opens outfit detail.

**Surprise Me section:**
- Header row: "🎲 Surprise Me" + "🔀 Shuffle" button (spins on click)
- Full-width gradient card (brand-500 → violet-600), white text
- Randomly picks 1 Top + 1 Bottom + 1 Shoe + optionally 1 Outerwear from wardrobe
- Shows: stacked item thumbnails, outfit name (random from pool), vibe score (80–97), AI-generated witty reason
- CTAs: "Keep This" (white button), "Again 🎲" (ghost button)
- Card re-animates with `card-pop` on each shuffle

**Curated Picks grid** (2 columns):
- Each card: full-bleed hero photo (h-64), gradient overlay, occasion badge, outfit name (Playfair Display), piece thumbnail strip + count overlaid at bottom
- Score ring in top-right corner
- Hover: image scale 1.05, shadow-xl

**Outfit Detail view:**
- Back ← button
- Hero image h-96, gradient overlay, occasion badge, name in Playfair Display (3xl), score ring
- AI reason card (💡 icon + italic text)
- "The Pieces" horizontal scroll row (w-36 cards, h-44 images, name + color below)
- CTAs: "Wear This Outfit" (ink-900), bookmark icon button

---

### 4. Try On Screen (primary feature)

**5-step flow:** Your Photo → Closet Photo → Pick Outfit → Generate → Result

**Step bar:** 5 dots with labels, connecting lines fill purple as steps complete.

**Step 1 — Your Photo:**
- Split-screen hero (h-72): left = "You" (demo person photo), right = "AI Styled" (fashion result photo)
- White divider line in center, "You" / "AI Styled" labels
- Title (Playfair Display): "See it on you first"
- Two CTAs: "📷 Upload My Photo" (ink-900) + "Use Demo Photo →" (brand-500)
- Tips grid: Stand straight / Good lighting / Full body
- File input reads actual uploaded file using `FileReader` as data URL

**Step 2 — Closet Photo:**
- If wardrobe has items:
  - Green "✓ Closet already scanned" banner with item count
  - Horizontal scroll thumbnail strip of all wardrobe items
  - "Use These Items → Pick Outfit" primary CTA
  - "📸 Rescan my closet instead" secondary link
- If no items:
  - Amber "! No closet scanned yet" warning
  - "📸 Scan My Closet Now" CTA

**Step 2b — Rescan (inline):**
- Dashed border upload zone, 🚪 door emoji
- "Open your closet and take a photo of everything hanging inside"
- "Try Demo Scan" button

**Step 3 — Pick Outfit:**
- User photo thumbnail + "Looking good 👋" + credit cost reminder
- "🎲 Surprise Me — pick a random outfit" full-width dashed button (picks random, auto-selects)
- "Or choose one" label
- Outfit list: each row shows piece thumbnails, name, piece count + occasion, radio circle
- Disabled "✨ Generate Try-On · 2 credits" CTA until outfit selected

**Step 4 — Generating:**
- Pulsing ring + ✨ emoji
- "AI is styling you" heading
- Cycling messages: "Analyzing your body shape…" → "Mapping fabric drape…" → "Rendering lighting…" → "Blending textures…" → "Adding finishing touches…"
- Progress bar
- Preview row: user photo + clothing thumbnails + shimmer placeholder

**Step 5 — Result:**
- Before/after drag slider (h-96): user photo on left, AI result on right
- White divider line with ↔ handle
- "Before" / "AI Try-On" labels
- "Drag to compare · AI-simulated result" caption
- Selected outfit summary row (thumbnails + name + score ring)
- CTAs: "🔖 Save Look", "Try Another", ↺ reset

---

### 5. Wardrobe Screen

Header: "My Wardrobe" (2xl bold) + item count
Sort button (top-right): "Sort: Recent" (decorative in prototype)

Category filter pills: All / Tops / Bottoms / Shoes / Outerwear
Active: `bg-gray-900 text-white`, inactive: white border

**Item cards** (grid: 2 cols mobile, 3 sm, 4 lg):
- Full-bleed image (h-52), overflow hidden
- Hover: image scales 1.06 (CSS transition)
- Category pill (colored) top-left over image
- AI confidence % badge top-right (frosted dark bg)
- Gradient overlay bottom half
- Item name (white, bold) + color (white/60) overlaid at bottom

---

### 6. Upload Screen

Header: "Upload Closet Photo" (2xl bold)
Subtext: "AI detects and catalogs every clothing item automatically."

**Upload zone** (rounded-3xl, dashed border):
- Idle: 📸 icon, "Drop your photo here", file type note, "Try Demo Upload" button
- Uploading: progress bar + percentage
- Scanning: pulsing ring + 🤖 emoji + "AWS Rekognition at work"

**Detection complete view:**
- "✓ Detection complete" green pill badge
- "3 items found" heading
- Closet photo with bounding boxes overlaid (hardcoded positions in prototype, real bounding boxes from Rekognition in production)
- Each detected item as a review card: color swatch initial, item name, sublabel, confidence %, Edit + Keep buttons
- Staggered slide-up animation per card
- "Add N items to Wardrobe →" full-width CTA

Tips row (3 cards): 📷 Snap or upload / 🤖 AI detection / ✏️ Review & save

---

## User Profile

- Name: Jesse
- Email: jesscoshirts@gmail.com
- Avatar: Asian male (Unsplash `photo-1506794778202-cad84cf45f1d`)
- AI Credits: 20/50 used (displayed as progress bar in sidebar)

---

## Key Product Decisions

1. **Upload is secondary** — Try On and Outfits are primary nav; Upload is in the "Library" section because the interesting part is what happens after upload, not the upload itself.
2. **Skip always goes to Try On** — it's the hero feature; new users should land on it.
3. **AI confidence shown everywhere** — builds trust; users can see why the AI made decisions.
4. **Review before saving** — users must confirm AI detections before items hit their wardrobe.
5. **Rule-based recommendations first** — ship faster; ML personalization added after real user data exists.
6. **Credits shown upfront** — try-on costs are displayed before the user commits, never after.
7. **Closet photo, not individual items** — users photograph the whole open closet at once; AI detects everything in one scan.

---

## What to Build Next (Backend — Phase 1–3)

### Phase 1: Auth + Frontend Shell
- Cognito User Pool + App Client
- React app with `react-router-dom`, auth context, Amplify or raw Cognito SDK
- Login / Signup / Forgot password pages
- Protected routes

### Phase 2: Uploads + S3
- `GET /uploads/presigned-url` — returns S3 presigned POST
- `POST /uploads/{id}/complete` — writes Upload record to DynamoDB, sends job to SQS
- React upload component uses presigned URL directly (no backend proxy)

### Phase 3: AI Detection Pipeline
- Lambda function triggered by SQS
- Calls `rekognition.detect_labels` with `MinConfidence=70`
- Filters labels to clothing categories (shirt, pants, shoes, jacket, dress, etc.)
- Crops bounding boxes from S3 image → saves thumbnails to S3
- Writes `WardrobeItem` records to DynamoDB with: `name`, `category`, `color`, `confidence`, `thumbnail_url`, `ai_source: "rekognition"`, `raw_output`
- Updates Upload record status to `complete`

### FastAPI Endpoints Needed
```
POST   /auth/signup
POST   /auth/login
GET    /wardrobe                    # list user's items
POST   /wardrobe                    # manual add
PATCH  /wardrobe/{item_id}          # edit name/category/color
DELETE /wardrobe/{item_id}
GET    /uploads/presigned-url
POST   /uploads/{id}/complete
GET    /outfits                     # rule-based recommendations
POST   /outfits                     # save an outfit
GET    /tryon/presigned-url         # for user photo upload
POST   /tryon                       # trigger Replicate, costs credits
GET    /user/credits
```

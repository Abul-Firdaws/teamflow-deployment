# Frontend Build and Deployment Guide

## Prerequisites

- Node.js v18+ installed locally
- npm v9+ installed
- AWS CLI configured (optional — S3 upload can be done via console)

---

## Step 1 — Clone the Frontend Repository

```bash
git clone https://github.com/ts-a-devops/taskapp_frontend.git
cd taskapp_frontend
```

---

## Step 2 — Configure Environment Variables

### Important: Vite uses `.env.production` for production builds

Vite has a specific priority order for environment files:

| File | When Used |
|---|---|
| `.env` | All environments (development and production) |
| `.env.production` | Production builds only (`npm run build`) |
| `.env.development` | Development only (`npm run dev`) |

**`.env.production` takes precedence over `.env` during builds.**

Always check if `.env.production` exists in the repo — it may contain
hardcoded values that override your `.env`.

```bash
# Check for existing env files
ls -la | grep env

# View .env.production if it exists
cat .env.production
```

### Create/Update .env.production

```bash
nano .env.production
```

For direct EC2 connection (HTTP):
```
VITE_API_URL=http://YOUR_EC2_PUBLIC_IP:5000/api
```

For CloudFront API proxy (HTTPS — recommended):
```
VITE_API_URL=https://YOUR_CLOUDFRONT_DOMAIN/api
```

> Use the CloudFront option to avoid Mixed Content errors when the
> frontend is served over HTTPS via CloudFront.

---

## Step 3 — Install Dependencies

```bash
npm install
```

---

## Step 4 — Build for Production

```bash
npm run build
```

This generates a `dist/` folder containing:
```
dist/
├── index.html
└── assets/
    ├── index-xxxxxxxx.js
    └── index-xxxxxxxx.css
```

> Note: Vite generates `dist/` not `build/`. These are equivalent.

---

## Step 5 — Upload to S3

### Via AWS Console:
1. Go to S3 → your bucket → Upload
2. Upload the **contents** of `dist/` (not the folder itself)
3. Ensure `index.html` is at the root level of the bucket

### Via AWS CLI:
```bash
aws s3 sync dist/ s3://YOUR_BUCKET_NAME/ --delete
```

---

## Step 6 — Invalidate CloudFront Cache

After re-uploading, always invalidate the CloudFront cache so users
get the latest version:

### Via AWS Console:
1. CloudFront → Distributions → your distribution
2. Invalidations tab → Create invalidation
3. Object paths: `/*`

### Via AWS CLI:
```bash
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

---

## Troubleshooting

### "Failed to fetch" / Login not working on CloudFront URL
**Cause:** Mixed Content — browser blocks HTTP API calls from HTTPS pages.
**Fix:** Configure CloudFront as an API proxy (see deployment guide).

### Login works on S3 URL but not CloudFront URL
**Cause:** Same Mixed Content issue as above.
**Fix:** Use `VITE_API_URL=https://YOUR_CLOUDFRONT_DOMAIN/api` and add
a CloudFront behavior routing `/api/*` to EC2.

### Old version still showing after re-upload
**Cause:** CloudFront is serving cached content.
**Fix:** Create a CloudFront invalidation for `/*`.


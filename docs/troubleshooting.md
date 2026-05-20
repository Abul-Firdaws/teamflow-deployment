# Troubleshooting Guide

Real issues encountered during this deployment and how they were resolved.

---

## Issue 1 — SSH Permission Denied / Key Not Found

### Error
```
Warning: Identity file /path/to/taskapp-key.pem not accessible: No such file or directory
ubuntu@xx.xx.xx.xx: Permission denied (publickey)
```

### Cause
- Typed `/path/to/` literally instead of the actual file path
- File path contained spaces (e.g. "Key Pair") which broke the command

### Fix
Wrap the full path in double quotes to handle spaces:
```bash
ssh -i "C:/Users/username/Documents/Key Pair/taskapp-key.pem" ubuntu@YOUR_EC2_IP
```

Better: move the key to a path with no spaces:
```bash
# Move key to clean path
# Then connect:
ssh -i "C:/Users/username/Documents/AWS/taskapp-key.pem" ubuntu@YOUR_EC2_IP
```

---

## Issue 2 — Backend Connecting to localhost Instead of RDS

### Error
```
psycopg2.OperationalError: connection to server at "localhost" (127.0.0.1),
port 5432 failed: Connection refused
```

### Cause
The original `run.py` never called `load_dotenv()`. The app was designed
for Ansible deployment, which injects environment variables at the system
level. Without `load_dotenv()`, the `.env` file is never read, and
`os.getenv()` returns `None` for all variables — triggering the
`localhost` fallback in `app/__init__.py`.

### Fix
Add `load_dotenv()` to the top of `run.py` **before** `create_app()`:

```python
from dotenv import load_dotenv
load_dotenv()   # Must come first

from app import create_app
import os
```

---

## Issue 3 — RDS Still Refusing Connection After .env Fix

### Error
Same `localhost` connection refused error, even after fixing `run.py`.

### Cause
The RDS security group did not have an inbound rule allowing the EC2
instance to connect on port 5432.

### Fix
1. Get the EC2 Security Group ID from EC2 → Security tab (e.g. `sg-0abc123`)
2. Go to RDS → taskapp-db → Security Group → Edit Inbound Rules
3. Add rule:

| Type | Port | Source |
|---|---|---|
| PostgreSQL | 5432 | sg-0abc123 (EC2 Security Group) |

---

## Issue 4 — "Failed to Fetch" on CloudFront Login

### Error (Browser Console)
```
POST https://api.devops-tsacademy.com/api/auth/login net::ERR_CONNECTION_TIMED_OUT
```

### Cause 1 — Hardcoded URL in .env.production
The frontend repository had `.env.production` with the instructor's domain
hardcoded. Vite uses `.env.production` for production builds, overriding
the regular `.env`.

### Fix
```bash
cat .env.production  # Check for hardcoded URLs
nano .env.production # Fix it
```
```
VITE_API_URL=https://YOUR_CLOUDFRONT_DOMAIN/api
```

### Cause 2 — Mixed Content Blocking
Even with the correct EC2 IP in `.env.production`, browsers block HTTP API
calls made from HTTPS pages (CloudFront is HTTPS, EC2 is HTTP).

### Fix
Configure CloudFront as an API reverse proxy:
1. Add EC2 as a second origin in CloudFront
2. Add a behavior routing `/api/*` to EC2
3. Set `VITE_API_URL=https://YOUR_CLOUDFRONT_DOMAIN/api`
4. Rebuild, re-upload, and invalidate cache

---

## Issue 5 — Old Version Showing After S3 Re-upload

### Symptom
Updated frontend uploaded to S3 but CloudFront still serves the old version.

### Cause
CloudFront caches content at its edge locations globally. Re-uploading to
S3 does not automatically clear the cache.

### Fix
Create a CloudFront invalidation:
1. CloudFront → your distribution → Invalidations → Create invalidation
2. Object paths: `/*`

Or via CLI:
```bash
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

---

## Quick Diagnostic Commands

```bash
# Check if backend is running
ps aux | grep python

# Check backend logs
cat app.log

# Test backend API locally
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'

# Check what environment variables are loaded
python3 -c "from dotenv import load_dotenv; import os; load_dotenv(); print(os.getenv('DATABASE_HOST'))"

# Restart backend
pkill -f "python3 run.py"
nohup python3 run.py > app.log 2>&1 &
```


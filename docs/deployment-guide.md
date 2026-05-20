# Full Deployment Guide

## Prerequisites

- AWS account with console access
- EC2 Key Pair (.pem file) saved securely
- Node.js v18+ installed locally
- Git installed locally
- WSL2 or Linux/Mac terminal

---

## Step 0 — Set Up RDS (Do This First)

Setting up the database first means you have the connection string
ready when configuring the backend.

1. Go to **RDS → Create Database**
2. Engine: PostgreSQL
3. Template: Free Tier
4. Settings:
   - DB identifier: `taskapp-db`
   - Master username: `postgres`
   - Master password: (save this securely)
5. Instance: `db.t4g.micro`
6. Storage: 20 GiB, gp2
7. Connectivity:
   - **Public access: No** ← Critical
   - VPC Security Group: Create new → name it `taskapp-rds-sg`
8. Additional config:
   - Initial database name: `taskapp`
9. Click **Create Database**

**Save your RDS endpoint** — found under Connectivity & Security tab:
```
taskapp-db.xxxxxxxxx.us-east-1.rds.amazonaws.com
```

---

## Step 1 — Deploy Backend on EC2

### 1.1 Launch EC2 Instance

1. Go to **EC2 → Launch Instance**
2. Name: `taskapp-backend`
3. AMI: Ubuntu Server 22.04 LTS (64-bit x86)
4. Instance type: t2.micro
5. Key pair: select your existing `.pem` key pair
6. Security group (create new):

| Type | Port | Source |
|---|---|---|
| SSH | 22 | My IP |
| Custom TCP | 5000 | 0.0.0.0/0 |
| HTTP | 80 | 0.0.0.0/0 |

7. Storage: 20 GiB gp3
8. Click **Launch Instance**

### 1.2 SSH Into the Server

```bash
ssh -i "C:/path/to/your-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

> If path has spaces, wrap in double quotes.

### 1.3 Set Up the Server

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install python3 python3-pip python3-venv git -y
git clone https://github.com/ts-a-devops/taskapp_backend.git
cd taskapp_backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 1.4 Fix run.py (Critical)

The original `run.py` does not load the `.env` file. Add `load_dotenv()`:

```bash
nano run.py
```

Replace all content with:
```python
from dotenv import load_dotenv
load_dotenv()

from app import create_app
import os

app = create_app()

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
```

### 1.5 Create .env File

```bash
nano .env
```

```env
DATABASE_HOST=taskapp-db.xxxxxxxxx.us-east-1.rds.amazonaws.com
DATABASE_PORT=5432
DATABASE_NAME=taskapp
DATABASE_USER=postgres
DATABASE_PASSWORD=your-rds-password
SECRET_KEY=your-strong-secret-key
PORT=5000
```

The DATABASE_PORT, DATABASE_NAME and DATABASE_USER fields has actual values of my deployment. Replace them with your actuals

### 1.6 Update RDS Security Group

1. Go to RDS → taskapp-db → Security Group → Edit Inbound Rules
2. Add rule:

| Type | Port | Source |
|---|---|---|
| PostgreSQL | 5432 | EC2 Security Group ID (sg-xxxxxxxx) |

### 1.7 Run the Backend

```bash
nohup python3 run.py > app.log 2>&1 &
```

Test it:
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'
```

Expected response:
```json
{"token": "eyJ...", "user": {"id": 1, "username": "admin"}}
```

---

## Step 2 — Build Frontend for Production

On your **local machine**:

```bash
git clone https://github.com/ts-a-devops/taskapp_frontend.git
cd taskapp_frontend
```

Check for existing env files:
```bash
ls -la | grep env
cat .env.production  # Check for hardcoded URLs
```

Create/update `.env.production`:
```bash
nano .env.production
```
```
VITE_API_URL=https://YOUR_CLOUDFRONT_DOMAIN/api
```

Build:
```bash
npm install
npm run build
```

This generates the `dist/` folder.

---

## Step 3 — Deploy Frontend to S3

1. Go to **S3 → Create Bucket**
   - Name: `taskapp-frontend-yourname` (must be globally unique)
   - Uncheck "Block all public access"
2. **Properties → Static Website Hosting → Enable**
   - Index document: `index.html`
   - Error document: `index.html`
3. **Upload** contents of `dist/` folder
4. **Permissions → Bucket Policy** → paste:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*"
  }]
}
```

---

## Step 4 — Create CloudFront Distribution

1. Go to **CloudFront → Create Distribution**
2. Origin: use S3 website endpoint (click "Use website endpoint")
3. Default root object: `index.html`
4. Viewer protocol policy: Redirect HTTP to HTTPS
5. Click **Create Distribution**

Note your CloudFront domain: `dxxxxxxxxx.cloudfront.net`

### Add EC2 as Second Origin (API Proxy)

1. **Origins tab → Create origin**
   - Domain: `ec2-xx-xx-xx-xx.compute-1.amazonaws.com`
   - Protocol: HTTP only
   - Port: 5000
2. **Behaviors tab → Create behavior**
   - Path pattern: `/api/*`
   - Origin: EC2 origin
   - Allowed HTTP methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
   - Cache policy: CachingDisabled
   - Origin request policy: AllViewer

---

## Step 5 — Final Test

1. Update `.env.production` with your CloudFront domain
2. Rebuild: `npm run build`
3. Re-upload `dist/` contents to S3
4. Invalidate CloudFront cache: `/*`
5. Visit: `https://YOUR_CLOUDFRONT_DOMAIN`
6. Login with `admin` / `admin123`

---

## Default Credentials

| Username | Password |
|---|---|
| admin | admin123 |
| student1 | Password123 |

---

## Cleanup (After Assignment)

To avoid ongoing AWS charges:
- EC2: Stop or Terminate instance
- RDS: Delete database
- S3: Empty and delete bucket
- CloudFront: Disable and delete distribution


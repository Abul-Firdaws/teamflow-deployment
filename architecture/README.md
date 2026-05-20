# Architecture Diagram

Place your architecture diagram screenshot here named `architecture-diagram.png`.

## How to Create One

### Option 1 — Screenshot from AWS Console
Take a screenshot of your running AWS services showing:
- CloudFront distribution
- S3 bucket
- EC2 instance
- RDS database

### Option 2 — Draw.io (Free)
Visit https://draw.io and recreate this architecture:

```
User
  ↓ HTTPS
Amazon CloudFront
  ↓ /api/*              ↓ /*
EC2 (Flask:5000)     S3 (React)
  ↓
RDS PostgreSQL
(Private VPC)
```

### Option 3 — AWS Architecture Icons
Download official AWS architecture icons from:
https://aws.amazon.com/architecture/icons/


# AWS Security Group Configuration

## Overview

Security groups act as virtual firewalls controlling inbound and outbound
traffic for AWS resources. This document outlines the security group rules
configured for this deployment.

---

## EC2 Security Group (taskapp-backend-sg)

Controls traffic to and from the EC2 instance running the Flask backend.

### Inbound Rules

| Type | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| SSH | TCP | 22 | My IP only (x.x.x.x/32) | Secure remote access |
| Custom TCP | TCP | 5000 | 0.0.0.0/0 | Flask backend API access |
| HTTP | TCP | 80 | 0.0.0.0/0 | HTTP web traffic |

### Security Notes

- SSH is restricted to **your IP only** — never open to 0.0.0.0/0
- Port 5000 is open publicly so CloudFront can reach the backend API
- In a more hardened setup, port 5000 would only allow CloudFront IP ranges

### Outbound Rules

| Type | Protocol | Port | Destination |
|---|---|---|---|
| All traffic | All | All | 0.0.0.0/0 |

---

## RDS Security Group (taskapp-rds-sg)

Controls traffic to and from the RDS PostgreSQL database.

### Inbound Rules

| Type | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| PostgreSQL | TCP | 5432 | EC2 Security Group ID | Allow backend to connect |

### Security Notes

- **Public access is DISABLED** on RDS — no public IP assigned
- Only the EC2 instance can reach the database, via its Security Group ID
- This is the correct production pattern — database is never exposed to internet

### Outbound Rules

| Type | Protocol | Port | Destination |
|---|---|---|---|
| All traffic | All | All | 0.0.0.0/0 |

---

## Architecture Security Flow

```
Internet
   ↓
CloudFront (HTTPS termination)
   ↓
S3 (Frontend - static files)
EC2:5000 (Backend API - via CloudFront behavior)
   ↓
RDS:5432 (Database - private, EC2 only)
```

No direct path exists from the internet to the RDS database.

---

## Best Practices Applied

1. **Principle of Least Privilege** — each service only allows the minimum
   required inbound traffic
2. **Private Database** — RDS has no public IP and is only reachable from
   within the VPC
3. **SSH Hardening** — SSH access locked to a specific IP, not open to world
4. **HTTPS Enforcement** — CloudFront redirects all HTTP to HTTPS
5. **Secrets Management** — credentials stored in environment variables,
   never hardcoded in source code


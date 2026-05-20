# TeamFlow Deployment — AWS Full Stack Architecture

![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazonaws)
![Flask](https://img.shields.io/badge/Backend-Flask-blue?logo=python)
![React](https://img.shields.io/badge/Frontend-React+Vite-61DAFB?logo=react)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791?logo=postgresql)
![CloudFront](https://img.shields.io/badge/CDN-CloudFront-orange?logo=amazonaws)

---

## Overview

This repository documents the end-to-end deployment of a full-stack web application (**TeamFlow Task Manager**) on AWS using a real-world cloud deployment architecture.

The project was completed as part of the **TS Academy DevOps programme** and demonstrates practical skills in:

- Cloud infrastructure provisioning
- Linux server configuration
- Secure backend deployment
- Static frontend hosting
- CDN configuration
- Production debugging and troubleshooting

---

## Architecture


User
↓ HTTPS
Amazon CloudFront (CDN + API Reverse Proxy)
↓ /api/* ↓ /*
EC2 (Flask Backend) S3 (React Frontend)
↓
RDS PostgreSQL
(Private — no public access)


### Services Used

| Service | Purpose |
|---|---|
| Amazon EC2 (Ubuntu 22.04) | Hosts Flask REST API backend |
| Amazon RDS (PostgreSQL) | Managed private relational database |
| Amazon S3 | Hosts static React production build |
| Amazon CloudFront | CDN, HTTPS termination, API routing |
| VPC Security Groups | Network-level access control |

---

## Tech Stack

### Backend
- Python 3.12
- Flask 3.0
- Flask-SQLAlchemy
- Flask-CORS
- PyJWT (Authentication)
- psycopg2 (PostgreSQL driver)
- Gunicorn (recommended for production)

### Frontend
- React 18
- TypeScript
- Vite
- Tailwind CSS

### Database
- PostgreSQL (Amazon RDS)

---

## Security Design

- RDS is **not publicly accessible** (private subnet only)
- EC2 SSH access restricted to specific IP address
- CloudFront enforces HTTPS for all frontend traffic
- Backend credentials managed using environment variables
- JWT authentication for protected API routes
- CORS configured for controlled frontend communication

---

## Live Deployment URLs

| Component | URL |
|---|---|
| Frontend (CloudFront) | https://d1jq7sb61dnewr.cloudfront.net |
| Backend (EC2) | http://<EC2_PUBLIC_IP>:5000 |
| Database (RDS) | Private (VPC-only access) |

> Note: Infrastructure was decommissioned after completion to avoid AWS billing charges.

---

## Repository Structure


teamflow-deployment/
│
├── README.md
├── architecture/
│ └── architecture-diagram.png
│
├── backend/
│ ├── setup.sh
│ └── run.py.patch
│
├── frontend/
│ ├── build-steps.md
│ └── .env.production.example
│
├── infrastructure/
│ ├── s3-bucket-policy.json
│ └── security-groups.md
│
├── docs/
│ ├── deployment-guide.md
│ └── troubleshooting.md
│
└── screenshots/


---

## Key Engineering Concepts Demonstrated

- AWS multi-tier architecture design
- Separation of frontend, backend, and database layers
- CDN-based frontend delivery
- Reverse proxy API routing using CloudFront
- Environment-based configuration management
- Network security using VPC security groups
- Production debugging and root cause analysis
- Cloud cost awareness and resource cleanup

---

## Lessons Learned

- Environment variable order of execution can break backend connectivity
- CloudFront caching requires explicit invalidation
- Mixed Content errors occur when HTTPS frontend calls HTTP backend
- Security groups define critical service-to-service communication
- Proper separation of infrastructure layers improves scalability
- Debugging cloud deployments requires systematic isolation of components

---

## Future Improvements

- Replace EC2 deployment with Docker + ECS
- Add CI/CD pipeline using GitHub Actions
- Use Terraform for Infrastructure as Code (IaC)
- Introduce AWS Secrets Manager for credentials
- Add Route53 custom domain + HTTPS certificates
- Replace Flask dev server with Gunicorn + Nginx
- Automate deployment pipeline end-to-end

---

## Source Repositories

| Component | Link |
|---|---|
| Backend | https://github.com/ts-a-devops/taskapp_backend |
| Frontend | https://github.com/ts-a-devops/taskapp_frontend |

---

## Author

**Firdaws Saaka**  
Assistant Water Safety Specialist
DevOps Trainee at TS Academy
Certified AWS Cloud Practitioner | Studying for AWS Solutions Architect Associate  


---

## License

This project is for educational and portfolio purposes.

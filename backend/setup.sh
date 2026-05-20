#!/bin/bash
# ============================================================
# EC2 Backend Setup Script
# Project: TeamFlow Task Manager
# Author: Abdul-Firdaws Saaka
# Description: Automates backend setup on a fresh Ubuntu EC2
# ============================================================

set -e  # Exit immediately if any command fails

echo "============================================"
echo " Step 1: Update and upgrade the system"
echo "============================================"
sudo apt update -y
sudo apt upgrade -y

echo "============================================"
echo " Step 2: Install Python, pip, venv and Git"
echo "============================================"
sudo apt install -y python3 python3-pip python3-venv git

echo "============================================"
echo " Step 3: Verify installations"
echo "============================================"
python3 --version
git --version

echo "============================================"
echo " Step 4: Clone the backend repository"
echo "============================================"
git clone https://github.com/ts-a-devops/taskapp_backend.git
cd taskapp_backend

echo "============================================"
echo " Step 5: Create and activate virtual env"
echo "============================================"
python3 -m venv venv
source venv/bin/activate

echo "============================================"
echo " Step 6: Install Python dependencies"
echo "============================================"
pip install -r requirements.txt

echo "============================================"
echo " Step 7: Create .env file"
echo "============================================"
# IMPORTANT: Replace the values below with your actual credentials
# before running this script, or create the .env manually.

cat > .env <<EOF
DATABASE_HOST=YOUR_RDS_ENDPOINT_HERE
DATABASE_PORT=5432
DATABASE_NAME=taskapp
DATABASE_USER=postgres
DATABASE_PASSWORD=YOUR_RDS_PASSWORD_HERE
SECRET_KEY=your-strong-secret-key-here
PORT=5000
EOF

echo ".env file created. Please verify it with: cat .env"

echo "============================================"
echo " Step 8: Apply fix to run.py (load_dotenv)"
echo "============================================"
# The original run.py does not call load_dotenv().
# This patch adds it before create_app() is called.
cat > run.py <<EOF
from dotenv import load_dotenv
load_dotenv()

from app import create_app
import os

app = create_app()

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
EOF

echo "run.py patched successfully."

echo "============================================"
echo " Step 9: Run the backend in the background"
echo "============================================"
nohup python3 run.py > app.log 2>&1 &

echo ""
echo "============================================"
echo " Backend is now running!"
echo " Test it with:"
echo " curl -X POST http://localhost:5000/api/auth/login \\"
echo "   -H 'Content-Type: application/json' \\"
echo "   -d '{\"username\": \"admin\", \"password\": \"admin123\"}'"
echo "============================================"


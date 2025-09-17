# Credentials Setup Instructions

This directory contains Google Cloud service account credentials required for Vertex AI integration.

## Required Files:
- `behaviorfirst-515f1-87e4804bb9f1.json` - Google Cloud service account key

## Setup Steps:
1. Go to Google Cloud Console: https://console.cloud.google.com
2. Select project: behaviorfirst-515f1
3. Navigate to IAM & Admin → Service Accounts
4. Find service account: vertex-ai-service@behaviorfirst-515f1.iam.gserviceaccount.com
5. Click on the service account → Keys tab
6. Create new key (JSON format)
7. Download and place in this directory with the correct filename

## Security Note:
- Never commit actual credential files to version control
- Credential files are excluded via .gitignore
- Each developer needs their own copy of the credentials file
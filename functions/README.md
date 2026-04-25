# TaskMate Functions

This folder contains Firebase Cloud Functions for server-side workflows.

## Password reset email with button

Function: `requestPasswordReset`

- Accepts `POST` with JSON body: `{ "email": "user@example.com" }`
- Generates reset link via Firebase Admin SDK.
- Sends a branded HTML email using SMTP (`nodemailer`).
- Returns a generic success response to avoid user enumeration.

## Required secrets

Set these before deploying:

```bash
npx -y firebase-tools@latest functions:secrets:set SMTP_HOST
npx -y firebase-tools@latest functions:secrets:set SMTP_PORT
npx -y firebase-tools@latest functions:secrets:set SMTP_USER
npx -y firebase-tools@latest functions:secrets:set SMTP_PASS
npx -y firebase-tools@latest functions:secrets:set SMTP_FROM
npx -y firebase-tools@latest functions:secrets:set RESET_CONTINUE_URL
npx -y firebase-tools@latest functions:secrets:set APP_DISPLAY_NAME
```

Suggested values:

- `SMTP_PORT`: `587` (or `465` for SSL)
- `SMTP_FROM`: `TaskMate <noreply@yourdomain.com>`
- `RESET_CONTINUE_URL`: e.g. `https://taskmate-chat-test.firebaseapp.com/reset-password`
- `APP_DISPLAY_NAME`: `TaskMate`

## Deploy

```bash
npx -y firebase-tools@latest deploy --only functions
```

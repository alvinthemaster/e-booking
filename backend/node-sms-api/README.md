# Node SMS API (Spark-Compatible)

Lightweight backend for sending PhilSMS notifications without Firebase Cloud Functions.

## Endpoints

- `GET /health`
- `POST /send-sms`

## Request body

```json
{
  "phoneNumber": "09123456789",
  "message": "Your document is ready for claiming."
}
```

## Security

- Keep `PHILSMS_API_KEY` only in backend environment variables.
- Optional request token check via `API_TOKEN` and `x-api-token` header.
- Built-in basic cooldown per recipient.

## Setup

1. Copy `.env.example` to `.env`.
2. Set `PHILSMS_API_KEY` and optionally `API_TOKEN`.
3. Install deps:
   - `npm install`
4. Run:
   - `npm start`

## Deploy (free tiers)

### Render
1. Create a new Web Service from `backend/node-sms-api`.
2. Build command: `npm install`
3. Start command: `npm start`
4. Add env vars from `.env.example`.

### Railway
1. Create project from folder/repo.
2. Add env vars.
3. Deploy with default Node start command.

## Postman

### Health check
- Method: `GET`
- URL: `https://<your-domain>/health`

### Send SMS
- Method: `POST`
- URL: `https://<your-domain>/send-sms`
- Header: `Content-Type: application/json`
- Optional Header: `x-api-token: <API_TOKEN>`
- Body:
```json
{
  "phoneNumber": "09123456789",
  "message": "Your document is ready for claiming."
}
```

## Sample success response

```json
{
  "success": true,
  "message": "SMS sent successfully.",
  "response": {"data": []},
  "statusCode": 200,
  "sender": "PhilSMS",
  "recipient": "639123456789"
}
```

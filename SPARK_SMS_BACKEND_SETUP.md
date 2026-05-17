# Spark Plan PhilSMS Integration (No Cloud Functions)

This setup keeps Firebase on Spark Plan and uses a free lightweight backend:

Flutter App -> Backend API (Render/Railway/etc.) -> PhilSMS API

## 1) Backend implementation

Implemented backend code is in:
- `backend/node-sms-api/server.js`
- `backend/node-sms-api/package.json`
- `backend/node-sms-api/.env.example`

### Endpoint
- `POST /send-sms`

Request body:
```json
{
  "phoneNumber": "09123456789",
  "message": "Your document is ready for claiming."
}
```

### Behavior
- Validates phone number and message.
- Normalizes PH numbers to `639XXXXXXXXX` format.
- Sends secure request to `https://app.philsms.com/api/v3/sms/send`.
- Uses headers:
  - `Authorization: Bearer <API_KEY>`
  - `Content-Type: application/json`
- Uses payload fields:
  - `recipient`
  - `sender_id`
  - `type`
  - `message`
- Adds basic anti-spam cooldown.

## 2) Backend environment values

In backend `.env`:
- `PHILSMS_API_KEY=<your PhilSMS API key>`
- `PHILSMS_SENDER_ID=PhilSMS`
- Optional: `API_TOKEN=<random-token>`
- Optional: `COOLDOWN_SECONDS=30`

## 3) Flutter integration

`lib/services/philsms_service.dart` now:
- Calls backend via HTTP.
- Handles timeout/network/backend errors.
- Adds basic per-recipient cooldown.
- Writes logs to Firestore `sms_logs`.

Set backend URL via dart define:
```powershell
flutter run --dart-define=SMS_BACKEND_BASE_URL=https://your-backend-domain
```

## 4) Firestore logging

Collection: `sms_logs`

Fields written by app:
- `phoneNumber`
- `message`
- `status`
- `timestamp`
- `response`
- `statusCode`
- `sender`
- `requestedBy`

## 5) Firestore rule updates

`firestore.rules` now allows authenticated create/read on `sms_logs`.

Deploy rules:
```powershell
firebase deploy --only firestore:rules
```

## 6) Postman tests

### Health
- Method: `GET`
- URL: `https://your-backend-domain/health`

### Send SMS
- Method: `POST`
- URL: `https://your-backend-domain/send-sms`
- Headers:
  - `Content-Type: application/json`
  - Optional: `x-api-token: <API_TOKEN>`
- Body:
```json
{
  "phoneNumber": "09123456789",
  "message": "Your document is ready for claiming."
}
```

### Sample success response
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

## 7) Free deployment choices

### Render free tier
1. Create Web Service from `backend/node-sms-api`.
2. Build command: `npm install`
3. Start command: `npm start`
4. Set environment variables.

### Railway free tier
1. Create project from repository.
2. Set root directory to `backend/node-sms-api`.
3. Add environment variables.
4. Deploy.

## 8) Why this is Spark-compatible

- No Firebase Cloud Functions required for SMS sending.
- API key is never embedded in Flutter app code.
- Firebase is only used for auth + Firestore logs within Spark limits.

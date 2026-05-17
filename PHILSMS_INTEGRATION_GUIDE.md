# PhilSMS Integration Guide

## API Details

| Field | Value |
|-------|-------|
| Endpoint | `https://app.philsms.com/api/v3/sms/send` |
| Method | `POST` |
| Auth | `Authorization: Bearer YOUR_API_KEY` |
| Content-Type | `application/json` |

---

## Correct Request Body

```json
{
  "recipient": "639123456789",
  "sender_id": "PhilSMS",
  "type": "plain",
  "message": "Your message here."
}
```

> **Important:** `recipient` must be in `639XXXXXXXXX` format (no `+`, no spaces).

---

## Phone Number Conversion

| Input | Normalized | Valid |
|-------|-----------|-------|
| `09123456789` | `639123456789` | ✅ |
| `9123456789` | `639123456789` | ✅ |
| `639123456789` | `639123456789` | ✅ |
| `+639123456789` | ❌ not accepted | ❌ |
| `12345` | ❌ too short | ❌ |

---

## Postman Setup

### 1. Create a new POST request

- URL: `https://app.philsms.com/api/v3/sms/send`

### 2. Headers tab

| Key | Value |
|-----|-------|
| Authorization | `Bearer 3014|jRf9R1jJx7MXnThKHeD5w0UcReHDts5SbrYPRmjcbda549d5` |
| Content-Type | `application/json` |
| Accept | `application/json` |

### 3. Body tab → raw → JSON

```json
{
  "recipient": "639XXXXXXXXXX",
  "sender_id": "PhilSMS",
  "type": "plain",
  "message": "GODTRASCO Demo Test"
}
```

Replace `639XXXXXXXXXX` with a real number you own.

### 4. Expected success response

```json
{
  "status": "queued",
  "message": "SMS queued successfully."
}
```

### 5. Expected error responses

| Scenario | Response |
|----------|----------|
| Invalid key | `{"status":"error","message":"Unauthenticated."}` |
| Invalid number | `{"status":"error","message":"Invalid recipient."}` |
| No credits | `{"status":"error","message":"Insufficient credits."}` |

---

## Troubleshooting Checklist

### ❌ "Unauthenticated" error

1. Go to [https://app.philsms.com](https://app.philsms.com) → Developers tab
2. Click **Regenerate Token**
3. Copy the new token
4. Update `defaultValue` in `lib/services/philsms_service.dart`
5. Hot restart the app

### ❌ SMS says success but no message received

1. Check PhilSMS dashboard → **SMS Logs** section
2. Confirm the recipient number is correct (format: `639XXXXXXXXX`)
3. Check account has sufficient credits
4. Verify `sender_id` is `PhilSMS` (custom IDs need registration)

### ❌ CORS error on Flutter Web

PhilSMS does **not** support browser CORS requests. The app automatically routes through `corsproxy.io` on Flutter Web builds. If corsproxy.io is down:

- Run on a physical Android/iOS device instead
- Or use the Node backend in `backend/node-sms-api/`

### ❌ Timeout

- Check phone internet connection
- Try on Wi-Fi
- PhilSMS status page: [https://status.philsms.com](https://status.philsms.com)

### ❌ Invalid phone number

The app validates that the number must match: `^63[0-9]{10}$`

Valid inputs: `09XXXXXXXXX`, `639XXXXXXXXX`, `9XXXXXXXXX`

---

## Flutter Debug Logs

All PhilSMS requests print to the debug console with `[PhilSMS]` prefix.

Example successful output:
```
[PhilSMS] ══════════════════════════════════════
[PhilSMS] Platform : Native
[PhilSMS] Endpoint : https://app.philsms.com/api/v3/sms/send
[PhilSMS] Headers  : {Authorization: Bearer ..., Content-Type: application/json, Accept: application/json}
[PhilSMS] Body     : {"recipient":"639123456789","sender_id":"PhilSMS","type":"plain","message":"..."}
[PhilSMS] ════════════════════════════════════════
[PhilSMS] Status   : 200
[PhilSMS] Response : {"status":"queued","message":"SMS queued successfully."}
```

---

## Flutter Web CORS Note

| Platform | Behavior |
|----------|----------|
| Android / iOS | Direct call to `app.philsms.com` ✅ |
| Flutter Web (Chrome) | Routes through `corsproxy.io` (demo proxy) ⚠️ |

For production web, deploy the Node backend in `backend/node-sms-api/` and set:
```
--dart-define=SMS_BACKEND_BASE_URL=https://your-backend-domain
```

# PhilSMS via Firebase Functions Setup

## What was added

- Backend function: `sendSMSNotification`
- Backend files:
  - `functions/index.js`
  - `functions/package.json`
- Flutter client integration:
  - `lib/services/philsms_service.dart` (now calls callable function)
- Firebase project config:
  - `firebase.json` includes `functions.source`

## Security model

- PhilSMS API key is stored only in Firebase Functions Secret Manager.
- Flutter app no longer calls PhilSMS directly.
- Callable function requires authenticated user.

## 1) Install dependencies

From project root:

```powershell
flutter pub get
cd functions
npm install
cd ..
```

## 2) Set backend secrets/config

Set PhilSMS secret key:

```powershell
firebase functions:secrets:set PHILSMS_API_KEY
```

When prompted, paste this value:

`3014|jRf9R1jJx7MXnThKHeD5w0UcReHDts5SbrYPRmjcbda549d5`

Set optional sender id config:

```powershell
firebase functions:config:set philsms.sender_id="GODTRASCO"
```

Note: Current function uses a default sender id `GODTRASCO` via params. You can harden this by moving sender id to secrets as well if needed.

## 3) Deploy functions

```powershell
firebase deploy --only functions
```

## 4) Firestore logs

Every SMS attempt is logged in `sms_logs` with:

- recipientNumber
- message
- status (`sent` or `failed`)
- timestamp
- errorMessage (if failed)
- provider response/status code
- requestedBy (uid)

## 5) Callable function contract

Function name: `sendSMSNotification`

Input:

- `phoneNumber`
- `message`

Behavior:

- Validates required params
- Normalizes PH numbers to `+63XXXXXXXXXX`
- Sends to PhilSMS endpoint using Bearer token
- Returns `{ success, message, statusCode }`
- Throws Firebase callable errors on invalid input/auth/network/API failure

## 6) Flutter usage example

```dart
final service = PhilSmsService();
final result = await service.sendSms(
  recipient: '09171234567',
  message: 'Your document is ready for claiming.',
);

if (result.success) {
  // show success snackbar
} else {
  // show error snackbar
}
```

## 7) App Check (optional)

The function is ready for App Check and currently has:

- `enforceAppCheck: false`

When your app has App Check fully configured, change to:

- `enforceAppCheck: true`

in `functions/index.js`, then redeploy functions.

## 8) Important billing note

Cloud Functions deployment generally requires Firebase project billing enabled (Blaze). If deployment is blocked on Spark plan, this is a Firebase platform limitation.

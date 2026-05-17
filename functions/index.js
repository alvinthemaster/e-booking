const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineString} = require("firebase-functions/params");
const functions = require("firebase-functions");
const {logger} = functions;

admin.initializeApp();

const db = admin.firestore();
const PHILSMS_SENDER_ID = defineString("PHILSMS_SENDER_ID", {
  default: "PhilSMS",
});

function getPhilSmsApiKey() {
  const runtimeConfig = functions.config();
  return (
    runtimeConfig?.philsms?.api_key ||
    process.env.PHILSMS_API_KEY ||
    ""
  );
}

function buildBearerAuthHeader(rawApiKey) {
  const token = String(rawApiKey || "").trim();
  if (!token) return "";
  return token.toLowerCase().startsWith("bearer ") ? token : `Bearer ${token}`;
}

function getPhilSmsSenderId() {
  const runtimeConfig = functions.config();
  return runtimeConfig?.philsms?.sender_id || PHILSMS_SENDER_ID.value();
}

function normalizePhone(raw) {
  const digits = String(raw || "").replace(/[^0-9]/g, "");
  if (digits.startsWith("63") && digits.length >= 12) return `+${digits}`;
  if (digits.startsWith("0") && digits.length >= 11) return `+63${digits.slice(1)}`;
  if (digits.length === 10 && digits.startsWith("9")) return `+63${digits}`;
  return digits;
}

function validatePayload(data) {
  const phoneNumber = String(data?.phoneNumber || "").trim();
  const message = String(data?.message || "").trim();

  if (!phoneNumber) {
    throw new HttpsError("invalid-argument", "phoneNumber is required.");
  }
  if (!message) {
    throw new HttpsError("invalid-argument", "message is required.");
  }

  const normalized = normalizePhone(phoneNumber);
  if (!/^\+63\d{10}$/.test(normalized)) {
    throw new HttpsError("invalid-argument", "Invalid Philippine mobile number format.");
  }

  if (message.length > 1000) {
    throw new HttpsError("invalid-argument", "message is too long.");
  }

  return {normalized, message};
}

exports.sendSMSNotification = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 30,
    memory: "256MiB",
    // Set to true when App Check is fully enabled in your clients.
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const {normalized, message} = validatePayload(request.data);

    const authHeader = buildBearerAuthHeader(getPhilSmsApiKey());
    if (!authHeader) {
      throw new HttpsError(
        "failed-precondition",
        "PhilSMS API key is not configured in backend runtime config.",
      );
    }

    const payload = {
      recipient: normalized,
      sender_id: getPhilSmsSenderId(),
      type: "plain",
      message,
    };

    let status = "failed";
    let errorMessage = null;
    let statusCode = null;
    let responseBody = null;

    try {
      logger.info("Sending SMS via PhilSMS", {
        recipient: normalized,
        senderId: payload.sender_id,
        uid: request.auth.uid,
      });

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 15000);

      const response = await fetch("https://app.philsms.com/api/v3/sms/send", {
        method: "POST",
        headers: {
          Authorization: authHeader,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });

      clearTimeout(timeout);

      statusCode = response.status;
      const rawText = await response.text();
      try {
        responseBody = JSON.parse(rawText);
      } catch (_) {
        responseBody = rawText;
      }

      if (!response.ok) {
        errorMessage = `PhilSMS API failure: HTTP ${response.status}`;
        logger.error(errorMessage, {responseBody});
        throw new HttpsError("internal", errorMessage);
      }

      status = "sent";
      logger.info("SMS sent successfully", {
        recipient: normalized,
        statusCode,
      });

      await db.collection("sms_logs").add({
        recipientNumber: normalized,
        message,
        status,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        errorMessage: null,
        provider: "philsms",
        providerStatusCode: statusCode,
        providerResponse: responseBody,
        requestedBy: request.auth.uid,
      });

      return {
        success: true,
        message: "SMS sent successfully.",
        statusCode,
      };
    } catch (error) {
      if (!errorMessage) {
        if (error?.name === "AbortError") {
          errorMessage = "SMS request timed out.";
        } else {
          errorMessage = error?.message || "Failed to send SMS.";
        }
      }

      logger.error("sendSMSNotification failed", {
        recipient: normalized,
        statusCode,
        errorMessage,
      });

      await db.collection("sms_logs").add({
        recipientNumber: normalized,
        message,
        status,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        errorMessage,
        provider: "philsms",
        providerStatusCode: statusCode,
        providerResponse: responseBody,
        requestedBy: request.auth.uid,
      });

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", errorMessage);
    }
  }
);

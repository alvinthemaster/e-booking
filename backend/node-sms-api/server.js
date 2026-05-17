require('dotenv').config();

const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json({limit: '64kb'}));

const PHILSMS_API_KEY = process.env.PHILSMS_API_KEY || '3026|byj3XBrWzBu0juloft2cOuEKJk7A2AQ6UX7gfkFL75d08edd';
const PHILSMS_SENDER_ID = process.env.PHILSMS_SENDER_ID || 'PhilSMS';
const API_TOKEN = process.env.API_TOKEN || '';
const COOLDOWN_SECONDS = Number(process.env.COOLDOWN_SECONDS || '30');
const HOST = process.env.HOST || '0.0.0.0';

const recipientCooldown = new Map();

function normalizePhone(raw) {
  const digits = String(raw || '').replace(/[^0-9]/g, '');
  if (digits.startsWith('63') && digits.length >= 12) return digits;
  if (digits.startsWith('0') && digits.length >= 11) return `63${digits.slice(1)}`;
  if (digits.length === 10 && digits.startsWith('9')) return `63${digits}`;
  return digits;
}

function validatePayload(body) {
  const phoneNumber = String(body?.phoneNumber || '').trim();
  const message = String(body?.message || '').trim();

  if (!phoneNumber) return 'phoneNumber is required.';
  if (!message) return 'message is required.';

  const normalized = normalizePhone(phoneNumber);
  if (!/^63\d{10}$/.test(normalized)) {
    return 'Invalid Philippine phone number.';
  }

  if (message.length > 1000) return 'message is too long.';
  return null;
}

function checkCooldown(normalizedPhone) {
  const now = Date.now();
  const last = recipientCooldown.get(normalizedPhone);
  if (last && now - last < COOLDOWN_SECONDS * 1000) {
    return false;
  }
  recipientCooldown.set(normalizedPhone, now);
  return true;
}

function buildBearerAuthHeader(rawApiKey) {
  const token = String(rawApiKey || '').trim();
  if (!token) return '';
  return token.toLowerCase().startsWith('bearer ') ? token : `Bearer ${token}`;
}

app.get('/health', (_, res) => {
  res.json({ok: true, service: 'node-sms-api'});
});

app.post('/send-sms', async (req, res) => {
  try {
    const authHeader = buildBearerAuthHeader(PHILSMS_API_KEY);
    if (!authHeader) {
      return res.status(500).json({success: false, message: 'Backend SMS key is not configured.'});
    }

    if (API_TOKEN) {
      const token = req.header('x-api-token');
      if (token !== API_TOKEN) {
        return res.status(401).json({success: false, message: 'Unauthorized request.'});
      }
    }

    const validationError = validatePayload(req.body);
    if (validationError) {
      return res.status(400).json({success: false, message: validationError});
    }

    const normalizedPhone = normalizePhone(req.body.phoneNumber);
    const message = String(req.body.message).trim();

    if (!checkCooldown(normalizedPhone)) {
      return res.status(429).json({
        success: false,
        message: `Cooldown active. Try again after ${COOLDOWN_SECONDS} seconds.`,
      });
    }

    const payload = {
      recipient: normalizedPhone,
      sender_id: PHILSMS_SENDER_ID,
      type: 'plain',
      message,
    };

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    const response = await fetch('https://dashboard.philsms.com/api/v3/sms/send', {
      method: 'POST',
      headers: {
        Authorization: authHeader,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    const rawText = await response.text();
    let parsed;
    try {
      parsed = JSON.parse(rawText);
    } catch (_) {
      parsed = rawText;
    }

    if (!response.ok) {
      return res.status(response.status).json({
        success: false,
        message: `PhilSMS API failure: HTTP ${response.status}`,
        response: parsed,
        statusCode: response.status,
      });
    }

    return res.status(200).json({
      success: true,
      message: 'SMS sent successfully.',
      response: parsed,
      statusCode: response.status,
      sender: PHILSMS_SENDER_ID,
      recipient: normalizedPhone,
    });
  } catch (error) {
    if (error?.name === 'AbortError') {
      return res.status(504).json({
        success: false,
        message: 'SMS request timeout.',
      });
    }

    return res.status(500).json({
      success: false,
      message: `Backend server error: ${error?.message || error}`,
    });
  }
});

const port = Number(process.env.PORT || 3000);
app.listen(port, HOST, () => {
  console.log(`node-sms-api listening on http://${HOST}:${port}`);
});

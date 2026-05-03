  
const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const Stripe = require("stripe");
const admin = require("firebase-admin");

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

if (!process.env.STRIPE_SECRET_KEY) {
  console.error("❌ Falta STRIPE_SECRET_KEY en backend/.env");
  process.exit(1);
}


let firebaseInitialized = false;

try {
  let serviceAccount;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else {
    serviceAccount = require("./serviceAccountKey.json");
  }
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  firebaseInitialized = true;
  console.log("✅ Firebase Admin SDK inicializado");
} catch (error) {
  console.warn("⚠️ Firebase Admin no inicializado. Agrega serviceAccountKey.json o FIREBASE_SERVICE_ACCOUNT en .env");
}

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

function requireFirebase(res) {
  if (!firebaseInitialized) {
    res.status(503).json({ error: "Firebase Admin no está configurado." });
    return false;
  }
  return true;
}


app.get("/", (req, res) => {
  res.json({ ok: true, message: "Multi Store Backend running", fcm: firebaseInitialized });
});


app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount, currency } = req.body;
    if (typeof amount !== "number" || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount." });
    }
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: currency || "usd",
      automatic_payment_methods: { enabled: true },
    });
    return res.status(200).json({ clientSecret: paymentIntent.client_secret, paymentIntentId: paymentIntent.id });
  } catch (error) {
    console.error("Stripe error:", error);
    return res.status(500).json({ error: error.message });
  }
});


app.post("/send-to-topic", async (req, res) => {
  if (!requireFirebase(res)) return;
  try {
    const { topic, title, body, data = {} } = req.body;
    if (!topic || !title || !body) return res.status(400).json({ error: "Faltan: topic, title, body" });

    const message = {
      notification: { title, body },
      data,
      topic,
      android: { notification: { channelId: "multi_store_high_importance", priority: "high", sound: "default" } },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    };

    const response = await admin.messaging().send(message);
    console.log(`✅ [TOPIC] '${topic}': ${response}`);
    return res.status(200).json({ success: true, messageId: response });
  } catch (error) {
    console.error("FCM topic error:", error);
    return res.status(500).json({ error: error.message });
  }
});


app.post("/send-to-token", async (req, res) => {
  if (!requireFirebase(res)) return;
  try {
    const { token, title, body, data = {} } = req.body;
    if (!token || !title || !body) return res.status(400).json({ error: "Faltan: token, title, body" });

    const message = {
      notification: { title, body },
      data,
      token,
      android: { notification: { channelId: "multi_store_high_importance", priority: "high", sound: "default" } },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    };

    const response = await admin.messaging().send(message);
    console.log(`✅ [TOKEN] ${response}`);
    return res.status(200).json({ success: true, messageId: response });
  } catch (error) {
    if (error.code === "messaging/registration-token-not-registered") {
      return res.status(410).json({ error: "Token expirado", code: "TOKEN_EXPIRED" });
    }
    console.error("FCM token error:", error);
    return res.status(500).json({ error: error.message });
  }
});


app.post("/send-to-multiple-tokens", async (req, res) => {
  if (!requireFirebase(res)) return;
  try {
    const { tokens, title, body, data = {} } = req.body;
    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      return res.status(400).json({ error: "tokens debe ser un array no vacío" });
    }
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data,
      android: { notification: { channelId: "multi_store_high_importance", priority: "high" } },
    });
    return res.status(200).json({ success: true, successCount: response.successCount, failureCount: response.failureCount });
  } catch (error) {
    console.error("FCM multicast error:", error);
    return res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Backend running on http://0.0.0.0:${PORT}`);
});
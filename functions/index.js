const functions = require("firebase-functions");
const Stripe = require("stripe");

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: "2023-10-16",
});

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  const amount = data.amount;

  if (!amount || typeof amount !== "number") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Amount is required"
    );
  }

  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(amount * 100), // convertir a centavos
    currency: "usd",
    automatic_payment_methods: { enabled: true },
  });

  return {
    clientSecret: paymentIntent.client_secret,
    paymentIntentId: paymentIntent.id,
  };
});
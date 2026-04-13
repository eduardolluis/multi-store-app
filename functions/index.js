const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const Stripe = require("stripe");

admin.initializeApp();

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

exports.createPaymentIntent = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    try {
      const amount = request.data.amount;

      if (typeof amount !== "number" || amount <= 0) {
        throw new HttpsError(
          "invalid-argument",
          "amount debe ser un número mayor que 0"
        );
      }

      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100),
        currency: "usd",
        automatic_payment_methods: {
          enabled: true,
        },
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      };
    } catch (error) {
      logger.error("Error creating payment intent:", error);

      throw new HttpsError(
        "internal",
        error.message || "No se pudo crear el PaymentIntent"
      );
    }
  }
);
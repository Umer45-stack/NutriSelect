const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
const stripe = require("stripe")("sk_test_51R4fQy02d7vmy8enxribTDtC1XyhSgbxSW0ID9tFluczKSUeUBA4EoBeOwuV0vJrPO5u5P0sdtjYzk4zWcWZk7ad00UxCnpOtm");

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Create Payment Intent
app.post("/createPaymentIntent", async (req, res) => {
  try {
    const { amount, currency } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,  // Amount in cents
      currency: currency,
    });

    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (error) {
    console.error("Error creating payment intent:", error);
    res.status(400).json({ error: error.message });
  }
});

exports.api = functions.https.onRequest(app);  
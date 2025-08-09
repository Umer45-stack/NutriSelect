const functions = require("firebase-functions");
const stripe = require("stripe")("sk_test_51R4fQy02d7vmy8enxribTDtC1XyhSgbxSW0ID9tFluczKSUeUBA4EoBeOwuV0vJrPO5u5P0sdtjYzk4zWcWZk7ad00UxCnpOtm");

exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
    try {
        // Ensure it's a POST request
        if (req.method !== "POST") {
            return res.status(405).send("Method Not Allowed");
        }

        // Parse request body
        const { amount, currency } = req.body;
        if (!amount || !currency) {
            return res.status(400).send("Missing amount or currency");
        }

        // Create a payment intent
        const paymentIntent = await stripe.paymentIntents.create({
            amount,
            currency,
        });

        res.status(200).json({ clientSecret: paymentIntent.client_secret });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

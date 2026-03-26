// routes/stripeWebhookRoutes.js
import express from "express";
import PaymentService from "../services/paymentService.js";

const router = express.Router();

router.post("/webhook", express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.log(`⚠️ Webhook signature verification failed.`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      await PaymentService.handlePaymentSuccess(paymentIntent.id);
      break;
      
    case 'payment_intent.payment_failed':
      console.log('Payment failed:', event.data.object);
      break;
      
    case 'payout.paid':
      console.log('Payout completed:', event.data.object);
      break;
  }

  res.json({ received: true });
});

export default router;
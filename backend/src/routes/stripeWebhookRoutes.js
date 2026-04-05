// backend/src/routes/stripeWebhookRoutes.js

import express from "express";
import stripe from "../config/stripe.js";
import PaymentService from "../services/paymentService.js";
import SubscriptionService from "../services/subscriptionService.js";

const router = express.Router();

router.post(
  "/webhook",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    const sig = req.headers["stripe-signature"];
    let event;

    console.log("🔔 Webhook received");
    console.log("🔔 Signature:", sig ? "Present" : "Missing");

    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.STRIPE_WEBHOOK_SECRET,
      );
      console.log("✅ Webhook verified, event type:", event.type);
    } catch (err) {
      console.log(`⚠️ Webhook signature verification failed.`, err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    try {
      switch (event.type) {
        case "checkout.session.completed":
          const session = event.data.object;
          console.log("💰 Checkout session completed:", session.id);
          console.log("🔍 Session mode:", session.mode);
          console.log("🔍 Session metadata:", session.metadata);
          console.log("🔍 Session subscription:", session.subscription);

          if (session.mode === "subscription") {
            console.log("🎯 Processing subscription checkout");
            await SubscriptionService.handleSubscriptionCheckoutSuccess(
              session,
            );
          } else if (session.metadata?.type === "subscription") {
            console.log("🎯 Processing subscription checkout (from metadata)");
            await SubscriptionService.handleSubscriptionCheckoutSuccess(
              session,
            );
          } else if (session.mode === "payment") {
            console.log("💰 Processing one-time payment checkout");
          }
          break;

        case "customer.subscription.updated":
          console.log("🔄 Subscription updated");
          await SubscriptionService.handleSubscriptionWebhook(event);
          break;

        case "invoice.payment_succeeded":
          console.log("💵 Invoice payment succeeded");
          await SubscriptionService.handleSubscriptionWebhook(event);
          break;

        case "customer.subscription.deleted":
          console.log("🗑️ Subscription deleted");
          await SubscriptionService.handleSubscriptionWebhook(event);
          break;

        case "payment_intent.succeeded":
          const paymentIntent = event.data.object;
          console.log("💰 PaymentIntent succeeded:", paymentIntent.id);
          console.log("🔍 PaymentIntent metadata:", paymentIntent.metadata);

          if (
            paymentIntent.metadata &&
            paymentIntent.metadata.type === "subscription"
          ) {
            console.log("🎯 Processing subscription payment intent");
            const userId = parseInt(paymentIntent.metadata.userId);
            console.log("👤 Extracted userId:", userId);

            await SubscriptionService.confirmSubscriptionPayment(
              paymentIntent.metadata.planSlug,
              paymentIntent.id,
              userId,
            );
          } else {
            console.log("💰 Processing contract payment intent");
            await PaymentService.handlePaymentSuccess(paymentIntent.id);
          }
          break;

        default:
          console.log(`Unhandled event type ${event.type}`);
      }
    } catch (err) {
      console.error("❌ Error processing webhook:", err);
    }

    res.json({ received: true });
  },
);

export default router;

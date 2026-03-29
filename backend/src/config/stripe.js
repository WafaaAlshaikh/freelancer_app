// config/stripe.js
import Stripe from 'stripe';
import dotenv from 'dotenv';

dotenv.config();

if (!process.env.STRIPE_SECRET_KEY) {
  console.error('❌ STRIPE_SECRET_KEY is missing in .env file');
  throw new Error('STRIPE_SECRET_KEY is required');
}

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2025-02-24.acacia', 
});

console.log('✅ Stripe initialized with key:', process.env.STRIPE_SECRET_KEY.substring(0, 8) + '...');

export default stripe;
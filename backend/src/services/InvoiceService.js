import stripe from "../config/stripe.js";
import Invoice from "../models/Invoice.js";
import UserSubscription from "../models/UserSubscription.js";
import SubscriptionPlan from "../models/SubscriptionPlan.js";
import User from "../models/User.js";
import PDFDocument from "pdfkit";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class InvoiceService {
  static async createInvoice(subscriptionId, paymentIntentId = null) {
    try {
      const subscription = await UserSubscription.findByPk(subscriptionId, {
        include: [
          { model: SubscriptionPlan, as: "SubscriptionPlan" },
          { model: User, as: "user" },
        ],
      });

      if (!subscription) {
        throw new Error("Subscription not found");
      }

      const invoiceNumber = `INV-${Date.now()}-${subscription.user_id}`;
      const plan = subscription.SubscriptionPlan;

      const taxRate = 0.05;
      const tax = plan.price * taxRate;
      const total = plan.price + tax;

      const invoice = await Invoice.create({
        user_id: subscription.user_id,
        subscription_id: subscriptionId,
        invoice_number: invoiceNumber,
        amount: plan.price,
        discount: 0,
        tax: tax,
        total: total,
        status: paymentIntentId ? "paid" : "pending",
        billing_period_start: subscription.current_period_start,
        billing_period_end: subscription.current_period_end,
        paid_at: paymentIntentId ? new Date() : null,
      });

      await this.generateInvoicePDF(invoice, subscription, plan);

      return invoice;
    } catch (error) {
      console.error("Error creating invoice:", error);
      throw error;
    }
  }

  static async generateInvoicePDF(invoice, subscription, plan) {
    const doc = new PDFDocument();
    const filename = `invoice-${invoice.invoice_number}.pdf`;
    const filepath = `./invoices/${filename}`;

    doc.pipe(fs.createWriteStream(filepath));

    doc.fontSize(20).text("Invoice", { align: "center" });
    doc.moveDown();
    doc.fontSize(12).text(`Invoice #: ${invoice.invoice_number}`);
    doc.text(`Date: ${invoice.createdAt.toLocaleDateString()}`);
    doc.text(`Plan: ${plan.name}`);
    doc.text(`Amount: $${plan.price}`);
    doc.text(`Tax (5%): $${invoice.tax}`);
    doc.text(`Total: $${invoice.total}`);

    doc.end();

    const pdfUrl = `/invoices/${filename}`;
    await invoice.update({ pdf_url: pdfUrl });
    return pdfUrl;
  }

  static async getInvoice(invoiceId, userId) {
    const invoice = await Invoice.findOne({
      where: { id: invoiceId, user_id: userId },
      include: [
        {
          model: UserSubscription,
          as: "subscription",
          include: [{ model: SubscriptionPlan, as: "SubscriptionPlan" }],
        },
        { model: User, as: "user" },
      ],
    });

    if (!invoice) {
      throw new Error("Invoice not found");
    }

    return invoice;
  }

  static async getUserInvoices(userId, page = 1, limit = 10) {
    const offset = (page - 1) * limit;

    const { count, rows } = await Invoice.findAndCountAll({
      where: { user_id: userId },
      include: [
        {
          model: UserSubscription,
          as: "subscription",
          include: [{ model: SubscriptionPlan, as: "SubscriptionPlan" }],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit,
      offset,
    });

    return {
      invoices: rows,
      total: count,
      page,
      totalPages: Math.ceil(count / limit),
    };
  }

  static async markAsPaid(invoiceId, paymentIntentId) {
    const invoice = await Invoice.findByPk(invoiceId);
    if (!invoice) {
      throw new Error("Invoice not found");
    }

    await invoice.update({
      status: "paid",
      paid_at: new Date(),
      stripe_payment_intent_id: paymentIntentId,
    });

    return invoice;
  }

  static async refundInvoice(invoiceId, amount = null) {
    const invoice = await Invoice.findByPk(invoiceId);
    if (!invoice || invoice.status !== "paid") {
      throw new Error("Cannot refund unpaid invoice");
    }

    await invoice.update({ status: "refunded" });

    return invoice;
  }
}

export default InvoiceService;

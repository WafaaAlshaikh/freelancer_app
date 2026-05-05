import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const AdTransaction = sequelize.define("AdTransaction", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },

  campaign_id: { type: DataTypes.INTEGER, allowNull: false },

  advertiser_id: { type: DataTypes.INTEGER, allowNull: false },

  transaction_type: {
    type: DataTypes.ENUM("deposit", "charge", "refund", "adjustment"),
    defaultValue: "deposit",
  },

  amount: { type: DataTypes.DECIMAL(10, 2), allowNull: false },

  currency: { type: DataTypes.STRING, defaultValue: "USD" },

  payment_status: {
    type: DataTypes.ENUM("pending", "paid", "failed", "refunded"),
    defaultValue: "pending",
  },

  payment_method: {
    type: DataTypes.ENUM("stripe", "paypal", "bank_transfer", "wallet"),
    defaultValue: "stripe",
  },

  transaction_id: { type: DataTypes.STRING, unique: true },
  payment_intent_id: DataTypes.STRING,

  metadata: { type: DataTypes.TEXT, comment: "JSON data" },

  paid_at: DataTypes.DATE,
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
});

export default AdTransaction;

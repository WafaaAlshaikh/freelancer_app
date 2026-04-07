// ===== backend/src/models/FinancialTransaction.js =====
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const FinancialTransaction = sequelize.define("FinancialTransaction", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  user_role: {
    type: DataTypes.ENUM("freelancer", "client"),
    allowNull: false,
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  type: {
    type: DataTypes.ENUM(
      "payment_received",
      "payment_sent",
      "withdrawal",
      "deposit",
      "platform_fee",
      "refund",
      "bonus",
      "subscription"
    ),
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM("pending", "completed", "failed", "cancelled"),
    defaultValue: "pending",
  },
  reference_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  reference_type: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  transaction_date: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  metadata: {
    type: DataTypes.TEXT,
    defaultValue: "{}",
    get() {
      const raw = this.getDataValue('metadata');
      return raw ? JSON.parse(raw) : {};
    },
    set(val) {
      this.setDataValue('metadata', JSON.stringify(val));
    },
  },
}, {
  timestamps: true,
  indexes: [
    {
      fields: ['user_id', 'transaction_date'],
    },
    {
      fields: ['type', 'status'],
    },
  ],
});

export default FinancialTransaction;
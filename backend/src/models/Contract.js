// models/Contract.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Contract = sequelize.define("Contract", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  FreelancerId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  ClientId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  ProjectId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  agreed_amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  contract_document: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  terms_agreed: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  client_signed_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  freelancer_signed_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  signed_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  start_date: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  end_date: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM("draft", "pending_client", "pending_freelancer", "active", "completed", "cancelled", "disputed"),
    defaultValue: "draft",
  },
  terms: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  milestones: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const rawValue = this.getDataValue('milestones');
      return rawValue ? JSON.parse(rawValue) : [];
    },
    set(value) {
      this.setDataValue('milestones', JSON.stringify(value));
    }
  },
  payment_status: {
    type: DataTypes.ENUM("pending", "partial", "paid", "escrow"),
    defaultValue: "pending",
  },
  payment_method: {
    type: DataTypes.ENUM("wallet", "stripe", "paypal"),
    defaultValue: "stripe",
  },
  escrow_id: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  escrow_status: {
    type: DataTypes.ENUM("pending", "funded", "partial", "released", "refunded"),
    defaultValue: "pending",
  },
  released_amount: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  client_review: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  freelancer_review: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  client_rating: {
    type: DataTypes.INTEGER,
    validate: { min: 1, max: 5 },
    allowNull: true,
  },
  freelancer_rating: {
    type: DataTypes.INTEGER,
    validate: { min: 1, max: 5 },
    allowNull: true,
  },
  client_verification_method: {
    type: DataTypes.ENUM('simple', 'otp', 'docusign', 'digital_certificate'),
    defaultValue: 'simple'
  },
  client_verification_data: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  freelancer_verification_method: {
    type: DataTypes.ENUM('simple', 'otp', 'docusign', 'digital_certificate'),
    defaultValue: 'simple'
  },
  freelancer_verification_data: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  contract_pdf_url: {
    type: DataTypes.STRING,
    allowNull: true
  },
  github_repo: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  github_branch: {
    type: DataTypes.STRING,
    defaultValue: 'main',
  },
  github_last_commit: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  github_webhook_secret: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  reminders: {
    type: DataTypes.TEXT,
    defaultValue: '[]',
    get() {
      const rawValue = this.getDataValue('reminders');
      return rawValue ? JSON.parse(rawValue) : [];
    },
    set(value) {
      this.setDataValue('reminders', JSON.stringify(value));
    }
  },
  milestone_progress: {
    type: DataTypes.TEXT,
    defaultValue: '{}',
    get() {
      const rawValue = this.getDataValue('milestone_progress');
      return rawValue ? JSON.parse(rawValue) : {};
    },
    set(value) {
      this.setDataValue('milestone_progress', JSON.stringify(value));
    }
  },
  coupon_code: {
    type: DataTypes.STRING(50),
    allowNull: true,
  },
  coupon_discount_amount: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  /** Actual USD funded into escrow after Stripe (may differ from agreed_amount if coupon applied). */
  funded_escrow_amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
}, {
  timestamps: true,
});

export default Contract;
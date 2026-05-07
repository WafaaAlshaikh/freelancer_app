// models/Dispute.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Dispute = sequelize.define("Dispute", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  ContractId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  ClientId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  FreelancerId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  InitiatedBy: {
    type: DataTypes.ENUM('client', 'freelancer'),
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM('open', 'resolved', 'rejected'),
    defaultValue: 'open',
  },
  evidence_files: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: [],
  },
  admin_notes: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  resolution: {
    type: DataTypes.ENUM('full_refund', 'partial_refund', 'no_refund'),
    allowNull: true,
  },
  refund_amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  decision_date: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  createdAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  updatedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
});

export default Dispute;
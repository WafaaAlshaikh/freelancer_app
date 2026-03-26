// models/Wallet.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Wallet = sequelize.define("Wallet", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  UserId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true,
  },
  balance: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  pending_balance: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  total_earned: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  total_withdrawn: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  stripe_account_id: {
    type: DataTypes.STRING,
    allowNull: true,
  },
});

export default Wallet;
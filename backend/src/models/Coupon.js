import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Coupon = sequelize.define(
  "Coupon",
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    code: {
      type: DataTypes.STRING(50),
      unique: true,
      allowNull: false,
    },
    discount_percent: {
      type: DataTypes.DECIMAL(5, 2),
      allowNull: true,
      validate: {
        min: 0,
        max: 100,
      },
    },
    discount_amount: {
      type: DataTypes.DECIMAL(10, 2),
      defaultValue: 0,
    },
    valid_from: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    valid_until: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    max_uses: {
      type: DataTypes.INTEGER,
      defaultValue: null,
    },
    used_count: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    min_subscription_months: {
      type: DataTypes.INTEGER,
      defaultValue: 1,
    },
    applicable_plans: {
      type: DataTypes.JSON,
      defaultValue: null,
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
  },
  {
    tableName: "Coupons",
    timestamps: true,
  },
);

export default Coupon;

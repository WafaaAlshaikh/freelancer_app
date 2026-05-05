import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const AdImpression = sequelize.define("AdImpression", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  campaign_id: { type: DataTypes.INTEGER, allowNull: false },
  user_id: { type: DataTypes.INTEGER, allowNull: true },
  user_ip: DataTypes.STRING,
  user_country: DataTypes.STRING,
  user_role: DataTypes.STRING,
  type: {
    type: DataTypes.ENUM("impression", "click", "conversion"),
    defaultValue: "impression",
  },
  revenue: { type: DataTypes.DECIMAL(10, 4), defaultValue: 0 },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
});

export default AdImpression;

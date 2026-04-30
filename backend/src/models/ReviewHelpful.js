// models/ReviewHelpful.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const ReviewHelpful = sequelize.define(
  "ReviewHelpful",
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    reviewId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      field: "review_id",
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      field: "user_id",
    },
    createdAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
      field: "created_at",
    },
  },
  {
    tableName: "review_helpful",
    timestamps: false,
    indexes: [
      {
        unique: true,
        fields: ["review_id", "user_id"],
      },
    ],
  },
);

export default ReviewHelpful;

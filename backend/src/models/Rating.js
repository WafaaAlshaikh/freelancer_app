// models/Rating.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Rating = sequelize.define(
  "Rating",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },

    contractId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: "Contracts",
        key: "id",
      },
    },

    fromUserId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: "Users",
        key: "id",
      },
    },

    toUserId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: "Users",
        key: "id",
      },
    },

    rating: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: 1,
        max: 5,
      },
    },

    comment: {
      type: DataTypes.TEXT,
      allowNull: true,
    },

    reply: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    repliedAt: {
      type: DataTypes.DATE,
      allowNull: true,
      field: "replied_at",
    },
    helpfulCount: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      field: "helpful_count",
    },

    role: {
      type: DataTypes.ENUM("client", "freelancer"),
      allowNull: false,
    },
  },
  {
    timestamps: true,
    indexes: [
      {
        unique: true,
        fields: ["contractId", "fromUserId"],
      },
    ],
  },
);

export default Rating;

// ===== backend/src/models/SavedFilter.js =====
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const SavedFilter = sequelize.define("SavedFilter", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  filter_data: {
    type: DataTypes.TEXT,
    allowNull: false,
    get() {
      const raw = this.getDataValue('filter_data');
      return raw ? JSON.parse(raw) : {};
    },
    set(val) {
      this.setDataValue('filter_data', JSON.stringify(val));
    },
  },
  is_default: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  timestamps: true,
});

export default SavedFilter;
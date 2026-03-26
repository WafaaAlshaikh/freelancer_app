import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Skill = sequelize.define("Skill", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  name: DataTypes.STRING,
});

export default Skill;
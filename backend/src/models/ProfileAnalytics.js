import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const ProfileAnalytics = sequelize.define("ProfileAnalytics", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  
  user_id: { type: DataTypes.INTEGER, allowNull: false },
  profile_id: { type: DataTypes.INTEGER, allowNull: true },
  
  date: { type: DataTypes.DATEONLY, allowNull: false },
  profile_views: { type: DataTypes.INTEGER, defaultValue: 0 },
  unique_views: { type: DataTypes.INTEGER, defaultValue: 0 },
  
  search_appearances: { type: DataTypes.INTEGER, defaultValue: 0 },
  search_clicks: { type: DataTypes.INTEGER, defaultValue: 0 },
  
  messages_received: { type: DataTypes.INTEGER, defaultValue: 0 },
  invitations_sent: { type: DataTypes.INTEGER, defaultValue: 0 },
  invitations_accepted: { type: DataTypes.INTEGER, defaultValue: 0 },
  proposals_submitted: { type: DataTypes.INTEGER, defaultValue: 0 },
  
  views_by_country: { type: DataTypes.TEXT, defaultValue: "{}" },
  views_by_city: { type: DataTypes.TEXT, defaultValue: "{}" },
  
  views_by_device: { type: DataTypes.TEXT, defaultValue: "{}" },
  views_by_source: { type: DataTypes.TEXT, defaultValue: "{}" },
  
  peak_view_hours: { type: DataTypes.TEXT, defaultValue: "[]" },
  
  view_to_message_rate: { type: DataTypes.FLOAT, defaultValue: 0 },
  view_to_invitation_rate: { type: DataTypes.FLOAT, defaultValue: 0 },
  
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
});

export default ProfileAnalytics;

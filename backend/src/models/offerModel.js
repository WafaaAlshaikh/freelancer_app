// models/offerModel.js
import { DataTypes } from 'sequelize';
import { sequelize } from '../config/db.js';

const Offer = sequelize.define('Offer', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  clientId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'client_id',
  },
  freelancerId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'freelancer_id',
  },
  projectId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'project_id',
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM('pending', 'accepted', 'declined', 'expired'),
    defaultValue: 'pending',
  },
  expiresAt: {
    type: DataTypes.DATE,
    field: 'expires_at',
    defaultValue: () => new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), 
  },
  viewedAt: {
    type: DataTypes.DATE,
    field: 'viewed_at',
    allowNull: true,
  },
  createdAt: {
    type: DataTypes.DATE,
    field: 'created_at',
    defaultValue: DataTypes.NOW,
  },
  updatedAt: {
    type: DataTypes.DATE,
    field: 'updated_at',
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'offers',
  timestamps: true,
  underscored: true,
});

export default Offer;
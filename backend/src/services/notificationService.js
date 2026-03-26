// services/notificationService.js
import { Notification, User } from "../models/index.js";
import { Op } from "sequelize";

class NotificationService {
  
  static async createNotification({
    userId,
    type,
    title,
    body,
    data = {},
  }) {
    try {
      const notification = await Notification.create({
        userId,
        type,
        title,
        body,
        data: JSON.stringify(data),
      });
      
      console.log(`📧 Notification created for user ${userId}: ${title}`);
      return notification;
    } catch (error) {
      console.error('Error creating notification:', error);
      return null;
    }
  }

  static async getUserNotifications(userId, limit = 50, offset = 0) {
    try {
      const { count, rows } = await Notification.findAndCountAll({
        where: { userId },
        order: [['createdAt', 'DESC']],
        limit,
        offset,
      });
      
      return {
        total: count,
        unreadCount: await Notification.count({
          where: { userId, isRead: false }
        }),
        notifications: rows,
      };
    } catch (error) {
      console.error('Error getting notifications:', error);
      return { total: 0, unreadCount: 0, notifications: [] };
    }
  }

  static async markAsRead(notificationId, userId) {
    try {
      const notification = await Notification.findOne({
        where: { id: notificationId, userId }
      });
      
      if (notification && !notification.isRead) {
        await notification.update({
          isRead: true,
          readAt: new Date(),
        });
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error marking notification as read:', error);
      return false;
    }
  }

  static async markAllAsRead(userId) {
    try {
      await Notification.update(
        { isRead: true, readAt: new Date() },
        { where: { userId, isRead: false } }
      );
      return true;
    } catch (error) {
      console.error('Error marking all as read:', error);
      return false;
    }
  }

  static async deleteNotification(notificationId, userId) {
    try {
      const deleted = await Notification.destroy({
        where: { id: notificationId, userId }
      });
      return deleted > 0;
    } catch (error) {
      console.error('Error deleting notification:', error);
      return false;
    }
  }

  static async cleanupOldNotifications() {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const deleted = await Notification.destroy({
        where: {
          createdAt: { [Op.lt]: thirtyDaysAgo },
          isRead: true,
        }
      });
      
      console.log(`🧹 Cleaned up ${deleted} old notifications`);
      return deleted;
    } catch (error) {
      console.error('Error cleaning up notifications:', error);
      return 0;
    }
  }

  static async notifyProposalReceived(project, freelancer) {
    return await this.createNotification({
      userId: project.UserId, 
      type: 'proposal_received',
      title: 'New Proposal Received',
      body: `${freelancer.name} submitted a proposal for "${project.title}"`,
      data: {
        projectId: project.id,
        proposalId: freelancer.proposalId,
        screen: 'project_proposals',
      },
    });
  }

  static async notifyProposalAccepted(proposal, project) {
    return await this.createNotification({
      userId: proposal.UserId, 
      type: 'proposal_accepted',
      title: 'Your Proposal Was Accepted! 🎉',
      body: `Your proposal for "${project.title}" has been accepted. Please review the contract.`,
      data: {
        projectId: project.id,
        contractId: proposal.contractId,
        screen: 'contract',
      },
    });
  }

  static async notifyContractSigned(contract, signer, otherParty) {
    return await this.createNotification({
      userId: otherParty.id,
      type: 'contract_signed',
      title: 'Contract Signed',
      body: `${signer.name} has signed the contract for "${contract.project?.title}"`,
      data: {
        contractId: contract.id,
        screen: 'contract',
      },
    });
  }

  static async notifyMilestoneDue(milestone, contract) {
    return await this.createNotification({
      userId: contract.FreelancerId,
      type: 'milestone_due',
      title: 'Milestone Due Soon! ⏰',
      body: `"${milestone.title}" is due in ${milestone.daysLeft} days`,
      data: {
        contractId: contract.id,
        milestoneIndex: milestone.index,
        screen: 'contract',
      },
    });
  }
}

export default NotificationService;

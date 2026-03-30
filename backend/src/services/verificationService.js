import FreelancerProfile from '../models/FreelancerProfile.js';
import ClientProfile from '../models/ClientProfile.js';
import User from '../models/User.js';
import Badge from '../models/Badge.js';
import UserBadge from '../models/UserBadge.js';
import nodemailer from 'nodemailer';

class VerificationService {
  static transporter = nodemailer.createTransporter({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  static async initializeDefaultBadges() {
    try {
      const defaultBadges = [
        {
          name: 'Top Rated',
          slug: 'top-rated',
          description: 'Elite freelancers with exceptional performance',
          icon: 'star',
          color: '#FFB800',
          badge_type: 'status',
          criteria: JSON.stringify({
            min_rating: 4.8,
            min_reviews: 20,
            min_job_success: 95,
            min_earnings: 10000
          }),
          is_featured: true,
          display_priority: 100,
        },
        {
          name: 'Rising Talent',
          slug: 'rising-talent',
          description: 'Promising new freelancers with strong early performance',
          icon: 'trending_up',
          color: '#10B981',
          badge_type: 'status',
          criteria: JSON.stringify({
            max_reviews: 10,
            min_rating: 4.5,
            min_job_success: 90,
            max_member_months: 6
          }),
          is_featured: true,
          display_priority: 90,
        },
        {
          name: 'Expert Vetted',
          slug: 'expert-vetted',
          description: 'Top 1% of talent through rigorous screening',
          icon: 'verified',
          color: '#6366F1',
          badge_type: 'verification',
          criteria: JSON.stringify({
            manual_verification: true,
            skill_tests_passed: true,
            interview_completed: true
          }),
          is_featured: true,
          display_priority: 95,
        },
        {
          name: 'Payment Verified',
          slug: 'payment-verified',
          description: 'Payment method has been verified',
          icon: 'payment',
          color: '#059669',
          badge_type: 'verification',
          criteria: JSON.stringify({
            payment_method_verified: true
          }),
          is_permanent: false,
          display_priority: 80,
        },
        {
          name: 'Identity Verified',
          slug: 'identity-verified',
          description: 'Identity has been verified through document verification',
          icon: 'person_verified',
          color: '#DC2626',
          badge_type: 'verification',
          criteria: JSON.stringify({
            id_document_verified: true
          }),
          is_permanent: true,
          display_priority: 85,
        },
        {
          name: 'Company Verified',
          slug: 'company-verified',
          description: 'Company registration and business documents verified',
          icon: 'business',
          color: '#7C3AED',
          badge_type: 'verification',
          criteria: JSON.stringify({
            business_documents_verified: true
          }),
          is_permanent: true,
          display_priority: 75,
        },
        {
          name: '100% Job Success',
          slug: 'perfect-job-success',
          description: 'Maintained perfect job success score',
          icon: 'workspace_premium',
          color: '#F59E0B',
          badge_type: 'achievement',
          criteria: JSON.stringify({
            job_success_score: 100,
            min_completed_jobs: 5
          }),
          is_permanent: false,
          display_priority: 70,
        },
        {
          name: 'Quick Responder',
          slug: 'quick-responder',
          description: 'Responds to messages within 2 hours on average',
          icon: 'bolt',
          color: '#06B6D4',
          badge_type: 'performance',
          criteria: JSON.stringify({
            max_response_time_hours: 2,
            min_messages: 50
          }),
          is_permanent: false,
          expires_after_days: 30,
          display_priority: 60,
        },
        {
          name: 'Top Earner',
          slug: 'top-earner',
          description: 'Among the top 10% earners on the platform',
          icon: 'trending_up',
          color: '#10B981',
          badge_type: 'achievement',
          criteria: JSON.stringify({
            earnings_percentile: 90
          }),
          is_permanent: false,
          expires_after_days: 90,
          display_priority: 65,
        },
      ];

      for (const badgeData of defaultBadges) {
        await Badge.findOrCreate({
          where: { slug: badgeData.slug },
          defaults: badgeData,
        });
      }

      console.log('Default badges initialized successfully');
    } catch (error) {
      console.error('Error initializing default badges:', error);
    }
  }

  static async checkAndAwardBadges(userId, userType) {
    try {
      const badges = await Badge.findAll({ where: { is_active: true } });
      let profile, user;

      if (userType === 'freelancer') {
        profile = await FreelancerProfile.findOne({ where: { user_id: userId } });
      } else {
        profile = await ClientProfile.findOne({ where: { user_id: userId } });
      }
      
      user = await User.findByPk(userId);

      if (!profile || !user) return;

      for (const badge of badges) {
        const criteria = JSON.parse(badge.criteria || '{}');
        const shouldAward = await this.evaluateBadgeCriteria(criteria, profile, user, userType);

        if (shouldAward) {
          await this.awardBadge(userId, badge.id);
        } else {
          await this.revokeBadge(userId, badge.id);
        }
      }
    } catch (error) {
      console.error('Error checking and awarding badges:', error);
    }
  }

  static async evaluateBadgeCriteria(criteria, profile, user, userType) {
    try {
      if (criteria.min_rating && profile.rating < criteria.min_rating) return false;
      
      if (criteria.min_reviews && profile.total_reviews < criteria.min_reviews) return false;
      if (criteria.max_reviews && profile.total_reviews > criteria.max_reviews) return false;
      
      if (criteria.min_job_success && profile.job_success_score < criteria.min_job_success) return false;
      if (criteria.job_success_score && profile.job_success_score < criteria.job_success_score) return false;
      
      if (criteria.min_earnings && profile.total_earnings < criteria.min_earnings) return false;
      
      if (criteria.max_response_time_hours && profile.response_time > criteria.max_response_time_hours) return false;
      
      if (criteria.min_completed_jobs && profile.completed_projects_count < criteria.min_completed_jobs) return false;
      
      if (criteria.payment_method_verified && userType === 'client' && !profile.payment_verified) return false;
      if (criteria.id_document_verified && !user.is_verified) return false;
      if (criteria.business_documents_verified && userType === 'client' && !profile.company_verified) return false;
      
      if (criteria.max_member_months) {
        const memberSince = new Date(profile.member_since || user.created_at);
        const monthsDiff = (new Date() - memberSince) / (1000 * 60 * 60 * 24 * 30);
        if (monthsDiff > criteria.max_member_months) return false;
      }
      
      if (criteria.manual_verification && !profile.is_verified) return false;
      
      if (criteria.skill_tests_passed && !profile.skills_verified) return false;
      if (criteria.interview_completed && !profile.interview_completed) return false;
      
      if (criteria.min_messages && profile.total_messages < criteria.min_messages) return false;
      
      if (criteria.earnings_percentile) {
        if (criteria.earnings_percentile === 90 && profile.total_earnings < 50000) return false;
      }

      return true;
    } catch (error) {
      console.error('Error evaluating badge criteria:', error);
      return false;
    }
  }

  static async awardBadge(userId, badgeId, awardedBy = null) {
    try {
      const existingUserBadge = await UserBadge.findOne({
        where: { user_id: userId, badge_id: badgeId },
      });

      if (existingUserBadge && existingUserBadge.is_active) return; 

      const badge = await Badge.findByPk(badgeId);
      if (!badge) return;

      if (existingUserBadge) {
        await existingUserBadge.update({
          is_active: true,
          awarded_at: new Date(),
          awarded_by: awardedBy,
        });
      } else {
        await UserBadge.create({
          user_id: userId,
          badge_id: badgeId,
          awarded_at: new Date(),
          awarded_by: awardedBy,
          is_displayed: true,
        });
      }

      await this.sendBadgeNotification(userId, badge, 'awarded');
      
      console.log(`Badge "${badge.name}" awarded to user ${userId}`);
    } catch (error) {
      console.error('Error awarding badge:', error);
    }
  }

  static async revokeBadge(userId, badgeId) {
    try {
      const userBadge = await UserBadge.findOne({
        where: { user_id: userId, badge_id: badgeId, is_active: true },
      });

      if (!userBadge) return; 

      await userBadge.update({ is_active: false });

      const badge = await Badge.findByPk(badgeId);
      if (badge) {
        await this.sendBadgeNotification(userId, badge, 'revoked');
      }
      
      console.log(`Badge revoked from user ${userId}`);
    } catch (error) {
      console.error('Error revoking badge:', error);
    }
  }

  static async sendBadgeNotification(userId, badge, action) {
    try {
      const user = await User.findByPk(userId);
      if (!user || !user.email) return;

      const subject = action === 'awarded' 
        ? `🎉 Congratulations! You've earned the "${badge.name}" badge`
        : `ℹ️ Your "${badge.name}" badge has been updated`;

      const html = action === 'awarded'
        ? `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
              <h1 style="color: white; margin: 0; font-size: 24px;">🎉 Congratulations!</h1>
              <p style="color: white; margin: 10px 0; font-size: 16px;">You've earned a new badge</p>
            </div>
            <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
              <div style="text-align: center; margin-bottom: 30px;">
                <div style="display: inline-block; background: ${badge.color}20; padding: 20px; border-radius: 50%; margin-bottom: 15px;">
                  <span style="font-size: 48px;">🏆</span>
                </div>
                <h2 style="color: #1f2937; margin: 0; font-size: 24px;">${badge.name}</h2>
                <p style="color: #6b7280; margin: 10px 0; font-size: 16px;">${badge.description}</p>
              </div>
              <div style="text-align: center;">
                <a href="${process.env.FRONTEND_URL}/profile" style="background: ${badge.color}; color: white; padding: 12px 30px; text-decoration: none; border-radius: 25px; display: inline-block; font-weight: 600;">
                  View Your Profile
                </a>
              </div>
            </div>
          </div>
        `
        : `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: #f3f4f6; padding: 30px; text-align: center; border-radius: 10px;">
              <h1 style="color: #374151; margin: 0; font-size: 24px;">Badge Update</h1>
              <p style="color: #6b7280; margin: 10px 0; font-size: 16px;">Your badge status has changed</p>
            </div>
            <div style="background: white; padding: 30px; border-radius: 0 0 10px 10px;">
              <div style="text-align: center;">
                <h3 style="color: #1f2937; margin: 0;">${badge.name}</h3>
                <p style="color: #6b7280; margin: 10px 0;">This badge is no longer active on your profile.</p>
                <a href="${process.env.FRONTEND_URL}/profile" style="background: #6b7280; color: white; padding: 12px 30px; text-decoration: none; border-radius: 25px; display: inline-block; font-weight: 600;">
                  View Profile
                </a>
              </div>
            </div>
          </div>
        `;

      await this.transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: user.email,
        subject,
        html,
      });

    } catch (error) {
      console.error('Error sending badge notification:', error);
    }
  }

  static async updateVerificationStatus(userId, verificationType, status, documents = null) {
    try {
      let profile;
      const user = await User.findByPk(userId);

      if (!user) return { success: false, message: 'User not found' };

      if (user.role === 'freelancer') {
        profile = await FreelancerProfile.findOne({ where: { user_id: userId } });
      } else {
        profile = await ClientProfile.findOne({ where: { user_id: userId } });
      }

      if (!profile) return { success: false, message: 'Profile not found' };

      const updateData = {};
      
      switch (verificationType) {
        case 'identity':
          updateData.is_verified = status;
          user.is_verified = status;
          await user.save();
          break;
          
        case 'payment':
          if (user.role === 'client') {
            updateData.payment_verified = status;
          }
          break;
          
        case 'company':
          if (user.role === 'client') {
            updateData.company_verified = status;
          }
          break;
          
        case 'skills':
          if (user.role === 'freelancer') {
            updateData.skills_verified = documents || [];
          }
          break;
          
        default:
          return { success: false, message: 'Invalid verification type' };
      }

      await profile.update(updateData);

      await this.checkAndAwardBadges(userId, user.role);

      return { 
        success: true, 
        message: `${verificationType} verification ${status ? 'completed' : 'failed'}` 
      };
    } catch (error) {
      console.error('Error updating verification status:', error);
      return { success: false, message: 'Internal server error' };
    }
  }

  static async getUserBadges(userId) {
    try {
      const userBadges = await UserBadge.findAll({
        where: { 
          user_id: userId, 
          is_active: true,
          is_displayed: true 
        },
        include: [{
          model: Badge,
          as: 'badge',
        }],
        order: [
          [{ model: Badge, as: 'badge' }, 'display_priority', 'DESC'],
          ['awarded_at', 'DESC'],
        ],
      });

      return userBadges.map(ub => ({
        id: ub.badge.id,
        name: ub.badge.name,
        description: ub.badge.description,
        icon: ub.badge.icon,
        color: ub.badge.color,
        badge_type: ub.badge.badge_type,
        awarded_at: ub.awarded_at,
        expires_at: ub.expires_at,
      }));
    } catch (error) {
      console.error('Error getting user badges:', error);
      return [];
    }
  }

  static async checkExpiredBadges() {
    try {
      const expiredBadges = await UserBadge.findAll({
        where: {
          is_active: true,
          expires_at: {
            [require('sequelize').Op.lt]: new Date(),
          },
        },
      });

      for (const userBadge of expiredBadges) {
        await userBadge.update({ is_active: false });
        
        const badge = await Badge.findByPk(userBadge.badge_id);
        if (badge) {
          await this.sendBadgeNotification(userBadge.user_id, badge, 'expired');
        }
      }

      console.log(`Checked and expired ${expiredBadges.length} badges`);
    } catch (error) {
      console.error('Error checking expired badges:', error);
    }
  }

  static async updateAllUserBadges() {
    try {
      console.log('Starting badge update process...');

      const users = await User.findAll({
        attributes: ['id', 'role'],
      });

      for (const user of users) {
        await this.checkAndAwardBadges(user.id, user.role);
      }

      console.log('Badge update process completed');
    } catch (error) {
      console.error('Error updating all user badges:', error);
    }
  }
}

export default VerificationService;

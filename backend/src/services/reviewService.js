import Rating from '../models/Rating.js';
import Project from '../models/Project.js';
import FreelancerProfile from '../models/FreelancerProfile.js';
import ClientProfile from '../models/ClientProfile.js';
import User from '../models/User.js';
import { Op } from 'sequelize';

class ReviewService {
  static async createReview(req, res) {
    try {
      const { projectId, rating, comment, communication_score, quality_score, deadline_score, professionalism_score } = req.body;
      const reviewerId = req.user.id;

      if (!projectId || !rating || !comment) {
        return res.status(400).json({
          success: false,
          message: 'Project ID, rating, and comment are required',
        });
      }

      if (rating < 1 || rating > 5) {
        return res.status(400).json({
          success: false,
          message: 'Rating must be between 1 and 5',
        });
      }

      const project = await Project.findByPk(projectId, {
        include: [
          { model: User, as: 'client' },
          { model: User, as: 'freelancer' },
        ],
      });

      if (!project) {
        return res.status(404).json({
          success: false,
          message: 'Project not found',
        });
      }

      if (project.status !== 'completed') {
        return res.status(400).json({
          success: false,
          message: 'Reviews can only be created for completed projects',
        });
      }

      let revieweeId, reviewerRole, revieweeRole;
      
      if (project.client.id === reviewerId) {
        revieweeId = project.freelancer.id;
        reviewerRole = 'client';
        revieweeRole = 'freelancer';
      } else if (project.freelancer.id === reviewerId) {
        revieweeId = project.client.id;
        reviewerRole = 'freelancer';
        revieweeRole = 'client';
      } else {
        return res.status(403).json({
          success: false,
          message: 'You can only review projects you participated in',
        });
      }

      const existingReview = await Rating.findOne({
        where: {
          project_id: projectId,
          reviewer_id: reviewerId,
          reviewee_id: revieweeId,
        },
      });

      if (existingReview) {
        return res.status(400).json({
          success: false,
          message: 'You have already reviewed this project',
        });
      }

      const review = await Rating.create({
        project_id: projectId,
        reviewer_id: reviewerId,
        reviewee_id: revieweeId,
        rating,
        comment,
        communication_score: communication_score || rating,
        quality_score: quality_score || rating,
        deadline_score: deadline_score || rating,
        professionalism_score: professionalism_score || rating,
        reviewer_role: reviewerRole,
        reviewee_role: revieweeRole,
        is_public: true,
        helpful_count: 0,
      });

      await this.updateAggregateRatings(revieweeId, revieweeRole);

      await this.updateProjectStats(projectId, revieweeRole, rating);

      res.status(201).json({
        success: true,
        data: review,
        message: 'Review created successfully',
      });
    } catch (error) {
      console.error('Error creating review:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async getUserReviews(req, res) {
    try {
      const { userId } = req.params;
      const { page = 1, limit = 10, rating, sort = 'recent' } = req.query;

      const whereClause = { reviewee_id: userId };
      if (rating) {
        whereClause.rating = parseInt(rating);
      }

      let orderClause;
      switch (sort) {
        case 'rating_high':
          orderClause = [['rating', 'DESC']];
          break;
        case 'rating_low':
          orderClause = [['rating', 'ASC']];
          break;
        case 'helpful':
          orderClause = [['helpful_count', 'DESC']];
          break;
        default:
          orderClause = [['created_at', 'DESC']];
      }

      const reviews = await Rating.findAndCountAll({
        where: whereClause,
        include: [
          {
            model: Project,
            as: 'project',
            attributes: ['id', 'title'],
          },
          {
            model: User,
            as: 'reviewer',
            attributes: ['id', 'name', 'avatar'],
          },
        ],
        limit: parseInt(limit),
        offset: (parseInt(page) - 1) * parseInt(limit),
        order: orderClause,
      });

      res.json({
        success: true,
        data: reviews.rows,
        pagination: {
          total: reviews.count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(reviews.count / parseInt(limit)),
        },
      });
    } catch (error) {
      console.error('Error getting user reviews:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async getProjectReviews(req, res) {
    try {
      const { projectId } = req.params;

      const reviews = await Rating.findAll({
        where: { project_id: projectId },
        include: [
          {
            model: User,
            as: 'reviewer',
            attributes: ['id', 'name', 'avatar'],
          },
          {
            model: User,
            as: 'reviewee',
            attributes: ['id', 'name', 'avatar'],
          },
        ],
        order: [['created_at', 'DESC']],
      });

      res.json({
        success: true,
        data: reviews,
      });
    } catch (error) {
      console.error('Error getting project reviews:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async updateReview(req, res) {
    try {
      const { reviewId } = req.params;
      const { rating, comment, communication_score, quality_score, deadline_score, professionalism_score } = req.body;
      const reviewerId = req.user.id;

      const review = await Rating.findOne({
        where: { id: reviewId, reviewer_id: reviewerId },
      });

      if (!review) {
        return res.status(404).json({
          success: false,
          message: 'Review not found or you do not have permission to update it',
        });
      }

      const reviewAge = Date.now() - new Date(review.created_at).getTime();
      const sevenDaysInMs = 7 * 24 * 60 * 60 * 1000;
      
      if (reviewAge > sevenDaysInMs) {
        return res.status(400).json({
          success: false,
          message: 'Reviews can only be edited within 7 days of creation',
        });
      }

      const updateData = {};
      if (rating !== undefined) updateData.rating = rating;
      if (comment !== undefined) updateData.comment = comment;
      if (communication_score !== undefined) updateData.communication_score = communication_score;
      if (quality_score !== undefined) updateData.quality_score = quality_score;
      if (deadline_score !== undefined) updateData.deadline_score = deadline_score;
      if (professionalism_score !== undefined) updateData.professionalism_score = professionalism_score;

      await review.update(updateData);

      await this.updateAggregateRatings(review.reviewee_id, review.reviewee_role);

      res.json({
        success: true,
        data: review,
        message: 'Review updated successfully',
      });
    } catch (error) {
      console.error('Error updating review:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async deleteReview(req, res) {
    try {
      const { reviewId } = req.params;
      const reviewerId = req.user.id;

      const review = await Rating.findOne({
        where: { id: reviewId, reviewer_id: reviewerId },
      });

      if (!review) {
        return res.status(404).json({
          success: false,
          message: 'Review not found or you do not have permission to delete it',
        });
      }

      const revieweeId = review.reviewee_id;
      const revieweeRole = review.reviewee_role;

      await review.destroy();

      await this.updateAggregateRatings(revieweeId, revieweeRole);

      res.json({
        success: true,
        message: 'Review deleted successfully',
      });
    } catch (error) {
      console.error('Error deleting review:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async markHelpful(req, res) {
    try {
      const { reviewId } = req.params;
      const userId = req.user.id;

      const review = await Rating.findByPk(reviewId);
      if (!review) {
        return res.status(404).json({
          success: false,
          message: 'Review not found',
        });
      }

      const helpfulUsers = JSON.parse(review.helpful_users || '[]');
      const userIndex = helpfulUsers.indexOf(userId);

      if (userIndex > -1) {
        helpfulUsers.splice(userIndex, 1);
        await review.update({
          helpful_users: JSON.stringify(helpfulUsers),
          helpful_count: helpfulUsers.length,
        });
        
        res.json({
          success: true,
          data: { helpful: false, count: helpfulUsers.length },
          message: 'Helpful mark removed',
        });
      } else {
        helpfulUsers.push(userId);
        await review.update({
          helpful_users: JSON.stringify(helpfulUsers),
          helpful_count: helpfulUsers.length,
        });
        
        res.json({
          success: true,
          data: { helpful: true, count: helpfulUsers.length },
          message: 'Review marked as helpful',
        });
      }
    } catch (error) {
      console.error('Error marking review as helpful:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async reportReview(req, res) {
    try {
      const { reviewId } = req.params;
      const { reason, description } = req.body;
      const reporterId = req.user.id;

      const review = await Rating.findByPk(reviewId);
      if (!review) {
        return res.status(404).json({
          success: false,
          message: 'Review not found',
        });
      }

      await ReviewReport.create({
        review_id: reviewId,
        reporter_id: reporterId,
        reason,
        description,
        status: 'pending',
      });

      res.json({
        success: true,
        message: 'Review reported successfully',
      });
    } catch (error) {
      console.error('Error reporting review:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async updateAggregateRatings(userId, userRole) {
    try {
      const reviews = await Rating.findAll({
        where: { reviewee_id: userId, reviewee_role: userRole },
        attributes: [
          'rating',
          'communication_score',
          'quality_score',
          'deadline_score',
          'professionalism_score',
        ],
      });

      if (reviews.length === 0) return;

      const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
      const avgRating = totalRating / reviews.length;

      const avgCommunication = reviews.reduce((sum, r) => sum + r.communication_score, 0) / reviews.length;
      const avgQuality = reviews.reduce((sum, r) => sum + r.quality_score, 0) / reviews.length;
      const avgDeadline = reviews.reduce((sum, r) => sum + r.deadline_score, 0) / reviews.length;
      const avgProfessionalism = reviews.reduce((sum, r) => sum + r.professionalism_score, 0) / reviews.length;

      const ratingDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
      reviews.forEach(r => {
        ratingDistribution[r.rating]++;
      });

      if (userRole === 'freelancer') {
        await FreelancerProfile.update(
          {
            rating: avgRating,
            total_reviews: reviews.length,
            avg_communication_score: avgCommunication,
            avg_quality_score: avgQuality,
            avg_deadline_score: avgDeadline,
            avg_professionalism_score: avgProfessionalism,
            rating_distribution: JSON.stringify(ratingDistribution),
          },
          { where: { user_id: userId } }
        );
      } else {
        await ClientProfile.update(
          {
            client_rating: avgRating,
            total_reviews_received: reviews.length,
            avg_communication_score: avgCommunication,
            avg_quality_score: avgQuality,
            avg_deadline_score: avgDeadline,
            avg_professionalism_score: avgProfessionalism,
            rating_distribution: JSON.stringify(ratingDistribution),
          },
          { where: { user_id: userId } }
        );
      }
    } catch (error) {
      console.error('Error updating aggregate ratings:', error);
    }
  }

  static async updateProjectStats(projectId, revieweeRole, rating) {
    try {
      const project = await Project.findByPk(projectId);
      if (!project) return;

      if (revieweeRole === 'freelancer') {
        const freelancerProfile = await FreelancerProfile.findOne({
          where: { user_id: project.freelancer_id },
        });

        if (freelancerProfile) {
          const completedProjects = freelancerProfile.completed_projects_count || 0;
          const totalProjects = completedProjects + 1;
          
          const jobSuccessScore = rating >= 4 ? 100 : rating >= 3 ? 75 : rating >= 2 ? 50 : 25;
          
          await freelancerProfile.update({
            completed_projects_count: totalProjects,
            job_success_score: Math.round((freelancerProfile.job_success_score * completedProjects + jobSuccessScore) / totalProjects),
          });
        }
      } else {
        const clientProfile = await ClientProfile.findOne({
          where: { user_id: project.client_id },
        });

        if (clientProfile) {
          const completedContracts = clientProfile.completed_contracts || 0;
          const totalContracts = completedContracts + 1;
          
          await clientProfile.update({
            completed_contracts: totalContracts,
            hire_rate: rating >= 4 ? Math.round((clientProfile.hire_rate * completedContracts + 100) / totalContracts) : clientProfile.hire_rate,
          });
        }
      }
    } catch (error) {
      console.error('Error updating project stats:', error);
    }
  }

  static async getReviewStats(req, res) {
    try {
      const { userId } = req.params;

      const reviews = await Rating.findAll({
        where: { reviewee_id: userId },
        attributes: ['rating', 'reviewee_role'],
      });

      const freelancerReviews = reviews.filter(r => r.reviewee_role === 'freelancer');
      const clientReviews = reviews.filter(r => r.reviewee_role === 'client');

      const calculateStats = (reviewList) => {
        if (reviewList.length === 0) {
          return {
            total: 0,
            average: 0,
            distribution: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
            percentage_5_star: 0,
            percentage_4_plus: 0,
          };
        }

        const total = reviewList.length;
        const average = reviewList.reduce((sum, r) => sum + r.rating, 0) / total;
        
        const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
        reviewList.forEach(r => {
          distribution[r.rating]++;
        });

        return {
          total,
          average: Math.round(average * 10) / 10,
          distribution,
          percentage_5_star: Math.round((distribution[5] / total) * 100),
          percentage_4_plus: Math.round(((distribution[4] + distribution[5]) / total) * 100),
        };
      };

      res.json({
        success: true,
        data: {
          freelancer: calculateStats(freelancerReviews),
          client: calculateStats(clientReviews),
        },
      });
    } catch (error) {
      console.error('Error getting review stats:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async getTrendingReviews(req, res) {
    try {
      const { limit = 10, timeframe = 30 } = req.query;
      
      const dateThreshold = new Date();
      dateThreshold.setDate(dateThreshold.getDate() - parseInt(timeframe));

      const reviews = await Rating.findAll({
        where: {
          created_at: {
            [Op.gte]: dateThreshold,
          },
          rating: {
            [Op.gte]: 4,
          },
        },
        include: [
          {
            model: User,
            as: 'reviewee',
            attributes: ['id', 'name', 'avatar'],
          },
          {
            model: User,
            as: 'reviewer',
            attributes: ['id', 'name', 'avatar'],
          },
          {
            model: Project,
            as: 'project',
            attributes: ['id', 'title'],
          },
        ],
        order: [
          ['helpful_count', 'DESC'],
          ['rating', 'DESC'],
          ['created_at', 'DESC'],
        ],
        limit: parseInt(limit),
      });

      res.json({
        success: true,
        data: reviews,
      });
    } catch (error) {
      console.error('Error getting trending reviews:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }
}

export default ReviewService;

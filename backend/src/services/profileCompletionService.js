import FreelancerProfile from '../models/FreelancerProfile.js';
import ClientProfile from '../models/ClientProfile.js';
import User from '../models/User.js';

class ProfileCompletionService {
  static async calculateFreelancerProfileCompletion(userId) {
    try {
      const profile = await FreelancerProfile.findOne({ where: { user_id: userId } });
      const user = await User.findByPk(userId);

      if (!profile || !user) return 0;

      let completionScore = 0;
      const maxScore = 100;
      const weights = {
        title: 8,
        bio: 7,
        tagline: 5,
        avatar: 5,
        location: 5,

        skills: 10,
        hourly_rate: 8,
        availability: 7,

        work_experience: 10,
        education: 5,
        certifications: 5,

        portfolio_items_count: 8,
        cv_url: 4,
        video_intro_url: 3,

        is_verified: 5,
        social_links: 3,
        languages: 2,
      };

      if (profile.title && profile.title.trim()) completionScore += weights.title;
      if (profile.bio && profile.bio.trim()) completionScore += weights.bio;
      if (profile.tagline && profile.tagline.trim()) completionScore += weights.tagline;
      if (user.avatar && user.avatar.trim()) completionScore += weights.avatar;
      if ((profile.location || user.location) && (profile.location || user.location).trim()) {
        completionScore += weights.location;
      }

      const skills = this.parseJsonField(profile.skills);
      if (skills && skills.length > 0) completionScore += weights.skills;
      if (profile.hourly_rate && profile.hourly_rate > 0) completionScore += weights.hourly_rate;
      if (profile.availability && profile.availability !== 'not_available') {
        completionScore += weights.availability;
      }

      const workExperience = this.parseJsonField(profile.work_experience);
      if (workExperience && workExperience.length > 0) completionScore += weights.work_experience;
      const education = this.parseJsonField(profile.education);
      if (education && education.length > 0) completionScore += weights.education;
      const certifications = this.parseJsonField(profile.certifications);
      if (certifications && certifications.length > 0) completionScore += weights.certifications;

      if (profile.portfolio_items_count > 0) completionScore += weights.portfolio_items_count;
      if (profile.cv_url && profile.cv_url.trim()) completionScore += weights.cv_url;
      if (profile.video_intro_url && profile.video_intro_url.trim()) completionScore += weights.video_intro_url;

      if (profile.is_verified) completionScore += weights.is_verified;
      const socialLinks = this.parseJsonField(profile.social_links);
      if (socialLinks && Object.keys(socialLinks).length > 0) completionScore += weights.social_links;
      const languages = this.parseJsonField(profile.languages);
      if (languages && languages.length > 0) completionScore += weights.languages;

      const profileStrength = Math.round(completionScore);

      await profile.update({
        profile_completion_percentage: profileStrength,
        profile_strength: profileStrength,
        last_profile_update: new Date(),
      });

      return profileStrength;
    } catch (error) {
      console.error('Error calculating freelancer profile completion:', error);
      return 0;
    }
  }

  static async calculateClientProfileCompletion(userId) {
    try {
      const profile = await ClientProfile.findOne({ where: { user_id: userId } });
      const user = await User.findByPk(userId);

      if (!profile || !user) return 0;

      let completionScore = 0;
      const maxScore = 100;
      const weights = {
        company_name: 8,
        bio: 7,
        tagline: 5,
        avatar: 5,

        industry: 8,
        company_size: 7,
        company_website: 6,
        founded_year: 4,
        company_logo: 5,

        preferred_skills: 10,
        preferred_contract_type: 5,
        budget_range_min: 5,
        budget_range_max: 5,

        payment_verified: 8,
        id_verified: 6,
        social_links: 6,
      };

      if (profile.company_name && profile.company_name.trim()) completionScore += weights.company_name;
      if ((profile.bio || user.bio) && (profile.bio || user.bio).trim()) completionScore += weights.bio;
      if ((profile.tagline || user.tagline) && (profile.tagline || user.tagline).trim()) {
        completionScore += weights.tagline;
      }
      if (user.avatar && user.avatar.trim()) completionScore += weights.avatar;

      if (profile.industry && profile.industry.trim()) completionScore += weights.industry;
      if (profile.company_size && profile.company_size !== '1') completionScore += weights.company_size;
      if (profile.company_website && profile.company_website.trim()) completionScore += weights.company_website;
      if (profile.founded_year && profile.founded_year > 1900) completionScore += weights.founded_year;
      if (profile.company_logo && profile.company_logo.trim()) completionScore += weights.company_logo;

      const preferredSkills = this.parseJsonField(profile.preferred_skills);
      if (preferredSkills && preferredSkills.length > 0) completionScore += weights.preferred_skills;
      if (profile.preferred_contract_type && profile.preferred_contract_type !== 'both') {
        completionScore += weights.preferred_contract_type;
      }
      if (profile.budget_range_min && profile.budget_range_min > 0) completionScore += weights.budget_range_min;
      if (profile.budget_range_max && profile.budget_range_max > 0) completionScore += weights.budget_range_max;

      if (profile.payment_verified) completionScore += weights.payment_verified;
      if (profile.id_verified) completionScore += weights.id_verified;
      const socialLinks = {
        linkedin: profile.linkedin,
        twitter: profile.twitter,
        facebook: profile.facebook,
        instagram: profile.instagram,
      };
      const hasSocialLinks = Object.values(socialLinks).some(link => link && link.trim());
      if (hasSocialLinks) completionScore += weights.social_links;

      const profileStrength = Math.round(completionScore);

      await profile.update({
        profile_completion_percentage: profileStrength,
        profile_strength: profileStrength,
        last_profile_update: new Date(),
      });

      return profileStrength;
    } catch (error) {
      console.error('Error calculating client profile completion:', error);
      return 0;
    }
  }

  static async getProfileCompletionSuggestions(userId, userType) {
    try {
      let profile, user;
      
      if (userType === 'freelancer') {
        profile = await FreelancerProfile.findOne({ where: { user_id: userId } });
      } else {
        profile = await ClientProfile.findOne({ where: { user_id: userId } });
      }
      
      user = await User.findByPk(userId);

      if (!profile || !user) return [];

      const suggestions = [];

      if (userType === 'freelancer') {
        if (!profile.title || !profile.title.trim()) {
          suggestions.push({
            field: 'title',
            priority: 'high',
            message: 'Add a professional title to attract more clients',
            points: 8,
          });
        }

        if (!profile.bio || !profile.bio.trim()) {
          suggestions.push({
            field: 'bio',
            priority: 'high',
            message: 'Write a compelling bio to showcase your expertise',
            points: 7,
          });
        }

        const skills = this.parseJsonField(profile.skills);
        if (!skills || skills.length === 0) {
          suggestions.push({
            field: 'skills',
            priority: 'high',
            message: 'Add your key skills to help clients find you',
            points: 10,
          });
        }

        if (!profile.hourly_rate || profile.hourly_rate <= 0) {
          suggestions.push({
            field: 'hourly_rate',
            priority: 'medium',
            message: 'Set your hourly rate to appear in search results',
            points: 8,
          });
        }

        const workExperience = this.parseJsonField(profile.work_experience);
        if (!workExperience || workExperience.length === 0) {
          suggestions.push({
            field: 'work_experience',
            priority: 'medium',
            message: 'Add your work experience to build credibility',
            points: 10,
          });
        }

        if (profile.portfolio_items_count === 0) {
          suggestions.push({
            field: 'portfolio',
            priority: 'medium',
            message: 'Upload portfolio items to showcase your work',
            points: 8,
          });
        }

        if (!profile.is_verified) {
          suggestions.push({
            field: 'verification',
            priority: 'low',
            message: 'Get verified to build trust with clients',
            points: 5,
          });
        }
      } else {
        if (!profile.company_name || !profile.company_name.trim()) {
          suggestions.push({
            field: 'company_name',
            priority: 'high',
            message: 'Add your company name to appear professional',
            points: 8,
          });
        }

        if (!profile.industry || !profile.industry.trim()) {
          suggestions.push({
            field: 'industry',
            priority: 'high',
            message: 'Specify your industry to attract relevant freelancers',
            points: 8,
          });
        }

        const preferredSkills = this.parseJsonField(profile.preferred_skills);
        if (!preferredSkills || preferredSkills.length === 0) {
          suggestions.push({
            field: 'preferred_skills',
            priority: 'high',
            message: 'Add preferred skills to find the right talent',
            points: 10,
          });
        }

        if (!profile.payment_verified) {
          suggestions.push({
            field: 'payment_verification',
            priority: 'medium',
            message: 'Verify your payment method to build trust',
            points: 8,
          });
        }

        if (!profile.company_website || !profile.company_website.trim()) {
          suggestions.push({
            field: 'company_website',
            priority: 'low',
            message: 'Add your company website for credibility',
            points: 6,
          });
        }
      }

      suggestions.sort((a, b) => {
        const priorityOrder = { high: 3, medium: 2, low: 1 };
        const priorityDiff = priorityOrder[b.priority] - priorityOrder[a.priority];
        if (priorityDiff !== 0) return priorityDiff;
        return b.points - a.points;
      });

      return suggestions;
    } catch (error) {
      console.error('Error getting profile completion suggestions:', error);
      return [];
    }
  }

  static async updateAllProfileCompletions() {
    try {
      console.log('Starting profile completion update...');

      const freelancerProfiles = await FreelancerProfile.findAll({
        attributes: ['user_id'],
      });

      for (const profile of freelancerProfiles) {
        await this.calculateFreelancerProfileCompletion(profile.user_id);
      }

      const clientProfiles = await ClientProfile.findAll({
        attributes: ['user_id'],
      });

      for (const profile of clientProfiles) {
        await this.calculateClientProfileCompletion(profile.user_id);
      }

      console.log('Profile completion update completed.');
    } catch (error) {
      console.error('Error updating profile completions:', error);
    }
  }

  static parseJsonField(field) {
    if (!field) return null;
    try {
      return typeof field === 'string' ? JSON.parse(field) : field;
    } catch (error) {
      return null;
    }
  }

  static getProfileStrengthLevel(percentage) {
    if (percentage >= 90) return { level: 'Excellent', color: '#10B981', icon: '🏆' };
    if (percentage >= 75) return { level: 'Strong', color: '#3B82F6', icon: '💪' };
    if (percentage >= 50) return { level: 'Good', color: '#F59E0B', icon: '👍' };
    if (percentage >= 25) return { level: 'Fair', color: '#FB923C', icon: '📈' };
    return { level: 'Needs Work', color: '#EF4444', icon: '⚠️' };
  }
}

export default ProfileCompletionService;

// controllers/freelancerController.js 
import { FreelancerProfile, Proposal, Project, Contract, Wallet, Message, User } from "../models/index.js";
import { Op } from "sequelize";
import multer from "multer";
import path from "path";
import fs from "fs";
import AIService from '../services/aiService.js';



const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/cvs';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, `cv-${req.user.id}-${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

export const uploadCV = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf') {
      cb(null, true);
    } else {
      cb(new Error('Only PDF files are allowed'));
    }
  },
  limits: { fileSize: 5 * 1024 * 1024 } 
}).single('cv');

export const uploadAndAnalyzeCV = async (req, res) => {
  try {
    console.log('📤 Upload CV request received');
    
    if (!req.file) {
      return res.status(400).json({ message: "Please upload a PDF file" });
    }

    console.log('📁 File received:', req.file.filename);
    const cvUrl = `/uploads/cvs/${req.file.filename}`;
    const cvPath = req.file.path;

    console.log('📖 Extracting text from PDF...');
    const cvText = await AIService.extractTextFromPDF(cvPath);
    
    console.log('🤖 Analyzing CV with AI...');
    const aiAnalysis = await AIService.analyzeCV(cvText);

    let profile = await FreelancerProfile.findOne({
      where: { UserId: req.user.id }
    });

    const updateData = {
      cv_url: cvUrl,
      cv_text: cvText,
      title: aiAnalysis?.professional_info?.title || profile?.title,
      bio: aiAnalysis?.bio || profile?.bio,
      location: aiAnalysis?.personal_info?.location || profile?.location,
      experience_years: aiAnalysis?.professional_info?.years_experience || profile?.experience_years,
      skills: JSON.stringify(aiAnalysis?.professional_info?.skills || []),
      languages: JSON.stringify(aiAnalysis?.professional_info?.languages || []),
      education: JSON.stringify(aiAnalysis?.education || []),
      certifications: JSON.stringify(aiAnalysis?.professional_info?.certifications || []),
      
      social_links: JSON.stringify({
        github: aiAnalysis?.social_links?.github || profile?.social_links?.github,
        linkedin: aiAnalysis?.social_links?.linkedin || profile?.social_links?.linkedin,
        website: aiAnalysis?.social_links?.website || profile?.social_links?.website,
      }),
      
      github: aiAnalysis?.social_links?.github,
      linkedin: aiAnalysis?.social_links?.linkedin,
      website: aiAnalysis?.social_links?.website,
    };

    if (!profile) {
      profile = await FreelancerProfile.create({
        UserId: req.user.id,
        ...updateData
      });
    } else {
      await profile.update(updateData);
    }

    if (aiAnalysis?.personal_info?.full_name && 
        aiAnalysis.personal_info.full_name !== req.user.name) {
      await User.update(
        { name: aiAnalysis.personal_info.full_name },
        { where: { id: req.user.id } }
      );
    }

    console.log('✅ CV processed successfully');
    
    res.json({
      message: "✅ CV uploaded and analyzed successfully",
      profile: {
        ...profile.toJSON(),
        aiAnalysis: {
          title: aiAnalysis?.professional_info?.title,
          skills: aiAnalysis?.professional_info?.skills,
          languages: aiAnalysis?.professional_info?.languages,
          education: aiAnalysis?.education,
          certifications: aiAnalysis?.professional_info?.certifications,
          social_links: aiAnalysis?.social_links,
          bio: aiAnalysis?.bio,
          confidence: aiAnalysis?.confidence_score
        }
      }
    });

  } catch (err) {
    console.error("❌ Error in uploadAndAnalyzeCV:", err);
    res.status(500).json({ 
      message: "Server error", 
      error: err.message 
    });
  }
};


export const updateLocation = async (req, res) => {
  try {
    const { lat, lng, address } = req.body;

    if (!lat || !lng) {
      return res.status(400).json({ message: "Latitude and longitude are required" });
    }

    const coordinates = `${lat},${lng}`;

    let profile = await FreelancerProfile.findOne({
      where: { UserId: req.user.id }
    });

    if (!profile) {
      profile = await FreelancerProfile.create({
        UserId: req.user.id,
        location: address || `${lat},${lng}`,
        location_coordinates: coordinates
      });
    } else {
      await profile.update({
        location: address || `${lat},${lng}`,
        location_coordinates: coordinates
      });
    }

    res.json({
      message: "✅ Location updated successfully",
      location: address,
      coordinates
    });

  } catch (err) {
    console.error("Error in updateLocation:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "Please upload an image" });
    }

    const avatarUrl = `/uploads/avatars/${req.file.filename}`;

    await User.update(
      { avatar: avatarUrl },
      { where: { id: req.user.id } }
    );

    res.json({
      message: "✅ Avatar uploaded successfully",
      avatar: avatarUrl
    });

  } catch (err) {
    console.error("Error in uploadAvatar:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getSuggestedProjects = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;

    const suggestedProjects = await suggestProjectsForFreelancer(req.user.id, limit);

    const aiSuggestions = await getAIPersonalizedSuggestions(req.user.id);

    res.json({
      projects: suggestedProjects,
      aiSuggestions,
      message: "✅ Suggested projects retrieved successfully"
    });

  } catch (err) {
    console.error("Error in getSuggestedProjects:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProfile = async (req, res) => {
  try {
    const profile = await FreelancerProfile.findOne({
      where: { UserId: req.user.id },
      include: [{ model: User, attributes: ["name", "avatar", "email"] }]
    });

    const parseJSON = (field, defaultValue = []) => {
      try {
        return field ? JSON.parse(field) : defaultValue;
      } catch {
        return defaultValue;
      }
    };

    const parseSocialLinks = (field) => {
      try {
        if (!field) return {};
        return typeof field === 'string' ? JSON.parse(field) : field;
      } catch {
        return {};
      }
    };

    res.json({
      id: profile?.id,
      name: profile?.User?.name || req.user.name,
      avatar: profile?.User?.avatar || req.user.avatar,
      email: profile?.User?.email,
      title: profile?.title || "",
      bio: profile?.bio || "",
      location: profile?.location || "",
      location_coordinates: profile?.location_coordinates,
      experience_years: profile?.experience_years || 0,
      rating: profile?.rating ?? 0,
      skills: parseJSON(profile?.skills),
      languages: parseJSON(profile?.languages),
      education: parseJSON(profile?.education),
      certifications: parseJSON(profile?.certifications),
      cv_url: profile?.cv_url,
      is_available: profile?.is_available,
      hourly_rate: profile?.hourly_rate,
      completed_projects_count: profile?.completed_projects_count || 0,
      
      website: profile?.website,
      github: profile?.github,
      linkedin: profile?.linkedin,
      behance: profile?.behance,
      social_links: parseSocialLinks(profile?.social_links),
    });
  } catch (err) {
    console.error("Error in getProfile:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const updateProfile = async (req, res) => {
  try {
    let profile = await FreelancerProfile.findOne({
      where: { UserId: req.user.id }
    });

    const updateData = { ...req.body };

    ['skills', 'languages', 'education', 'certifications'].forEach(field => {
      if (updateData[field] && Array.isArray(updateData[field])) {
        updateData[field] = JSON.stringify(updateData[field]);
      }
    });

    if (!profile) {
      profile = await FreelancerProfile.create({
        ...updateData,
        UserId: req.user.id
      });
    } else {
      await profile.update(updateData);
    }

    if (updateData.name && updateData.name !== req.user.name) {
      await User.update(
        { name: updateData.name },
        { where: { id: req.user.id } }
      );
    }

    res.json({
      message: "✅ Profile updated successfully",
      profile
    });

  } catch (err) {
    console.error("Error in updateProfile:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getFreelancerStats = async (req, res) => {
  try {
    const userId = req.user.id;

    const completedProjects = await Contract.count({
      where: { FreelancerId: userId, status: 'completed' }
    });

    const activeProjects = await Contract.count({
      where: { FreelancerId: userId, status: 'active' }
    });

    const totalProposals = await Proposal.count({
      where: { UserId: userId }
    });

    const acceptedProposals = await Proposal.count({
      where: { UserId: userId, status: 'accepted' }
    });

    const profile = await FreelancerProfile.findOne({
      where: { UserId: userId },
      attributes: ['rating']
    });

    res.json({
      stats: {
        completedProjects,
        activeProjects,
        totalProposals,
        acceptedProposals,
        acceptanceRate: totalProposals > 0 
          ? (acceptedProposals / totalProposals * 100).toFixed(1)
          : 0,
        rating: profile?.rating || 0
      }
    });

  } catch (err) {
    console.error("Error in getFreelancerStats:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};


export const getProposals = async (req, res) => {
  try {
    console.log('📥 Fetching freelancer proposals...');
    
    const proposals = await Proposal.findAll({
      where: { UserId: req.user.id },
      include: [
        {
          model: Project,
          as: 'Project',  
          include: [
            {
              model: User,
              as: 'client',
              attributes: ['id', 'name', 'avatar', 'email']
            }
          ]
        }
      ],
      order: [['createdAt', 'DESC']]
    });
    
    console.log(`✅ Found ${proposals.length} proposals`);
    res.json(proposals);
    
  } catch (err) {
    console.error('❌ Error in getProposals:', err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjects = async (req, res) => {
  try {
    console.log('📥 Fetching freelancer projects...');
    
    const contracts = await Contract.findAll({
      where: { 
        FreelancerId: req.user.id,
        status: 'active'
      },
      include: [
        {
          model: Project,
          include: [
            {
              model: User,
              as: 'client',
              attributes: ['id', 'name', 'avatar', 'email']
            }
          ]
        }
      ]
    });
    
    const projects = contracts
      .filter(contract => contract.Project) 
      .map(contract => contract.Project);
    
    console.log(`✅ Found ${projects.length} active projects for freelancer`);
    res.json(projects);
    
  } catch (err) {
    console.error('❌ Error in getProjects:', err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getMessages = async (req, res) => {
  try {
    const messages = await Message.findAll({
      where: { senderId: req.user.id },
    });
    res.json(messages);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

export const getAISuggestedProjects = async (req, res) => {
  try {
    const result = await AIMatchingService.suggestProjectsForFreelancer(
      req.user.id,
      req.query.limit || 10
    );
    
    res.json({
      success: true,
      message: "✅ AI suggestions generated",
      ...result
    });
  } catch (err) {
    console.error("Error in AI suggestions:", err);
    res.status(500).json({ 
      success: false,
      message: "Server error", 
      error: err.message 
    });
  }
};


export const getFreelancerContracts = async (req, res) => {
  try {
    const contracts = await Contract.findAll({
      where: { FreelancerId: req.user.id },
      include: [
        {
          model: Project,
          include: [
            {
              model: User,
              as: 'client',
              attributes: ['id', 'name', 'avatar']
            }
          ]
        },
        {
          model: User,
          as: 'client', 
          attributes: ['id', 'name', 'avatar']
        }
      ],
      order: [['createdAt', 'DESC']]
    });

    res.json(contracts);
  } catch (err) {
    console.error("❌ Error in getFreelancerContracts:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};


export const updateMilestoneProgress = async (req, res) => {
  try {
    const { contractId, milestoneIndex } = req.params;
    const { progress, status } = req.body;

    const contract = await Contract.findOne({
      where: { id: contractId, FreelancerId: req.user.id }
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const milestones = contract.milestones;
    const milestone = milestones[milestoneIndex];

    if (!milestone) {
      return res.status(404).json({ message: "Milestone not found" });
    }

    if (milestone.status === 'approved') {
      return res.status(400).json({ message: "Milestone already approved" });
    }

    if (progress !== undefined) {
      milestone.progress = Math.min(100, Math.max(0, parseFloat(progress)));
    }

    if (status === 'completed' && milestone.progress >= 100) {
      milestone.status = 'completed';
      milestone.completed_at = new Date();
      
      await NotificationService.createNotification({
        userId: contract.ClientId,
        type: 'milestone_completed',
        title: 'Milestone Completed',
        body: `"${milestone.title}" has been marked as completed by the freelancer`,
        data: { contractId: contract.id, milestoneIndex, screen: 'contract' },
      });
    } else if (status === 'in_progress') {
      milestone.status = 'in_progress';
    }

    milestones[milestoneIndex] = milestone;

    await contract.update({ milestones: JSON.stringify(milestones) });

    res.json({
      message: "✅ Milestone progress updated",
      milestone,
      totalProgress: milestones.reduce((sum, m) => sum + (m.progress || 0), 0) / milestones.length,
    });

  } catch (err) {
    console.error("Error in updateMilestoneProgress:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};


export const getWallet = async (req, res) => {
  try {
    let wallet = await Wallet.findOne({ where: { UserId: req.user.id } });
    
    if (!wallet) {
      wallet = await Wallet.create({ UserId: req.user.id, balance: 0 });
    }
    
    const transactions = await Transaction.findAll({
      where: { wallet_id: wallet.id },
      order: [['createdAt', 'DESC']],
      limit: 50,
    });
    
    res.json({
      wallet,
      transactions,
    });
  } catch (err) {
    console.error("Error in getWallet:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};


export const requestWithdrawal = async (req, res) => {
  try {
    const { amount } = req.body;
    
    const result = await PaymentService.requestWithdrawal(req.user.id, amount);
    
    res.json(result);
  } catch (err) {
    console.error("Error in requestWithdrawal:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};


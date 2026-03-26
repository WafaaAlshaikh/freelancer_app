// services/aiMatchingService.js
import {
  Project,
  Proposal,
  FreelancerProfile,
  User,
  Contract,
} from "../models/index.js";
import { Op } from "sequelize";
import Groq from "groq-sdk";

const groqClient = new Groq({ apiKey: process.env.GROQ_API_KEY });

const parseSkills = (skillsField) => {
  if (!skillsField) return [];

  if (Array.isArray(skillsField)) {
    return skillsField;
  }

  if (typeof skillsField === "string") {
    try {
      const parsed = JSON.parse(skillsField);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return skillsField
        .split(",")
        .map((s) => s.trim())
        .filter((s) => s.length > 0);
    }
  }

  return [];
};

class AIMatchingService {


static async suggestProjectsForFreelancer(freelancerId, limit = 10) {
  try {
    console.log('🎯 [AI] Searching projects for freelancer:', freelancerId);
    
    const freelancer = await FreelancerProfile.findOne({
      where: { UserId: freelancerId },
      include: [{ 
        model: User, 
        attributes: ['id', 'name', 'avatar']
      }]
    });

    if (!freelancer) {
      throw new Error('Freelancer profile not found');
    }

    console.log('👤 Freelancer found:', {
      name: freelancer.User?.name,
      skills: freelancer.skills,
      experience: freelancer.experience_years
    });

    const projects = await Project.findAll({
      where: { 
        status: 'open',
        UserId: { [Op.ne]: freelancerId }
      },
      include: [{ 
        model: User, 
        as: 'client',  
        attributes: ['id', 'name', 'avatar']
      }],
      limit: 50
    });

    console.log(`📊 Found ${projects.length} open projects`);

    const scoredProjects = await Promise.all(
      projects.map(async (project) => {
        const existingProposal = await Proposal.findOne({
          where: { ProjectId: project.id, UserId: freelancerId }
        });

        const matchScore = await this.calculateProjectMatchScore(
          project, 
          freelancer
        );

        const projectData = project.toJSON();
        projectData.skills = parseSkills(project.skills);

        return {
          ...projectData,
          matchScore: matchScore.total,
          matchDetails: matchScore,
          hasApplied: !!existingProposal
        };
      })
    );

    const sortedProjects = scoredProjects
      .sort((a, b) => b.matchScore - a.matchScore)
      .slice(0, limit);

    console.log(`✅ Returning ${sortedProjects.length} suggestions`);
    if (sortedProjects.length > 0) {
      console.log('🏆 Top match:', sortedProjects[0].title, 'Score:', sortedProjects[0].matchScore);
    }

    return {
      success: true,
      suggestions: sortedProjects,
      freelancer: {
        name: freelancer.User?.name,
        skills: parseSkills(freelancer.skills),
        experience: freelancer.experience_years
      }
    };

  } catch (error) {
    console.error('❌ [AI] Error in suggestProjects:', error);
    return { success: false, error: error.message, suggestions: [] };
  }
}

 
  static async calculateProjectMatchScore(project, freelancer) {
    const freelancerSkillsArray = parseSkills(freelancer.skills);
    const projectSkillsArray = parseSkills(project.skills);

    console.log("📊 Skills comparison:", {
      freelancer: freelancerSkillsArray,
      project: projectSkillsArray,
    });

    const freelancerSkills = new Set(
      freelancerSkillsArray.map((s) => s.toLowerCase()),
    );
    const projectSkills = new Set(
      projectSkillsArray.map((s) => s.toLowerCase()),
    );

    let skillsScore = 0;
    if (projectSkills.size > 0) {
      const matchedSkills = [...projectSkills].filter((skill) =>
        [...freelancerSkills].some(
          (fs) => fs.includes(skill) || skill.includes(fs),
        ),
      );
      skillsScore = (matchedSkills.length / projectSkills.size) * 50;
      console.log(
        `✅ Matched ${matchedSkills.length}/${projectSkills.size} skills`,
      );
    } else {
      skillsScore = 25;
    }

    const experienceScore = Math.min(
      20,
      (freelancer.experience_years || 0) * 2,
    );

    let budgetScore = 15;
    if (freelancer.hourly_rate && project.budget && project.duration) {
      const estimatedTotal = freelancer.hourly_rate * project.duration * 8;
      const budgetDiff =
        Math.abs(estimatedTotal - project.budget) / project.budget;
      budgetScore = Math.max(0, 15 - budgetDiff * 15);
    }

    let categoryScore = 5;
    if (project.category) {
      const hasMatchingCategory = freelancerSkillsArray.some(
        (skill) =>
          skill.toLowerCase().includes(project.category.toLowerCase()) ||
          project.category.toLowerCase().includes(skill.toLowerCase()),
      );
      categoryScore = hasMatchingCategory ? 15 : 5;
    }

    const total = Math.min(
      100,
      Math.round(skillsScore + experienceScore + budgetScore + categoryScore),
    );

    return {
      total,
      skillsScore: Math.round(skillsScore),
      experienceScore: Math.round(experienceScore),
      budgetScore: Math.round(budgetScore),
      categoryScore,
    };
  }


static async suggestFreelancersForClient(projectId, limit = 10) {
  try {
    console.log('🎯 [AI] Finding freelancers for project:', projectId);

    const project = await Project.findByPk(projectId, {
      include: [{
        model: User,
        as: 'client', 
        attributes: ['id', 'name']
      }]
    });
    
    if (!project) throw new Error('Project not found');

    const projectSkills = parseSkills(project.skills);
    console.log('📋 Project:', project.title, 'Skills:', projectSkills);

    const freelancers = await FreelancerProfile.findAll({
      where: { is_available: true },
      include: [
        { 
          model: User, 
          attributes: ['id', 'name', 'avatar', 'email'],
          where: { role: 'freelancer' }
        }
      ],
      limit: 100
    });

    console.log(`📊 Found ${freelancers.length} available freelancers`);

    const scoredFreelancers = await Promise.all(
      freelancers.map(async (freelancer) => {
        const hasProposal = await Proposal.findOne({
          where: { ProjectId: projectId, UserId: freelancer.UserId }
        });

        const matchScore = await this.calculateFreelancerMatchScore(
          freelancer,
          project
        );

        const completedProjects = await Contract.count({
          where: { 
            FreelancerId: freelancer.UserId,
            status: 'completed' 
          }
        });

        return {
          id: freelancer.UserId,
          name: freelancer.User?.name,
          avatar: freelancer.User?.avatar,
          title: freelancer.title,
          rating: freelancer.rating,
          skills: parseSkills(freelancer.skills),
          experience: freelancer.experience_years,
          hourlyRate: freelancer.hourly_rate,
          completedProjects,
          matchScore: matchScore.total,
          matchDetails: matchScore,
          hasProposal: !!hasProposal,
          profile: freelancer
        };
      })
    );

    const sortedFreelancers = scoredFreelancers
      .sort((a, b) => {
        if (a.hasProposal && !b.hasProposal) return -1;
        if (!a.hasProposal && b.hasProposal) return 1;
        return b.matchScore - a.matchScore;
      })
      .slice(0, limit);

    console.log(`✅ Returning ${sortedFreelancers.length} suggestions`);
    if (sortedFreelancers.length > 0) {
      console.log('🏆 Top freelancer:', sortedFreelancers[0].name, 'Score:', sortedFreelancers[0].matchScore);
    }

    return {
      success: true,
      suggestions: sortedFreelancers,
      project: {
        title: project.title,
        skills: projectSkills,
        budget: project.budget
      }
    };

  } catch (error) {
    console.error('❌ [AI] Error in suggestFreelancers:', error);
    return { success: false, error: error.message, suggestions: [] };
  }
}


  static async calculateFreelancerMatchScore(freelancer, project) {
    const freelancerSkillsArray = parseSkills(freelancer.skills);
    const projectSkillsArray = parseSkills(project.skills);

    const normalizeSkill = (skill) =>
      skill.toLowerCase().trim().replace(/\s+/g, " ");

    const freelancerSkills = new Set(freelancerSkillsArray.map(normalizeSkill));
    const projectSkills = new Set(projectSkillsArray.map(normalizeSkill));

    console.log("🔍 Matching skills:", {
      required: [...projectSkills],
      has: [...freelancerSkills],
    });

    let skillsScore = 0;
    if (projectSkills.size > 0) {
      const matches = [];
      const matchedSkills = [...projectSkills].filter((skill) => {
        const hasExact = [...freelancerSkills].some((fs) => fs === skill);
        const hasPartial = [...freelancerSkills].some(
          (fs) =>
            fs.includes(skill) ||
            skill.includes(fs) ||
            (skill === "springboot" && fs.includes("spring boot")) ||
            (skill === "mysql" && fs === "mysql") ||
            (skill === "rest api" && fs.includes("rest")),
        );

        if (hasExact || hasPartial) {
          matches.push({ skill, matched: true });
          return true;
        }
        matches.push({ skill, matched: false });
        return false;
      });

      console.log("📊 Match results:", matches);

      const matchRatio = matchedSkills.length / projectSkills.size;
      skillsScore = matchRatio * 60;

      if (matchRatio === 1) {
        skillsScore += 10;
      }
    }

    const ratingScore = (freelancer.rating || 0) * 4;

    const experienceScore = Math.min(10, freelancer.experience_years || 0);

    const projectsCount = freelancer.completed_projects_count || 0;
    const projectsScore = Math.min(10, projectsCount);

    let budgetCompatibility = 0;
    if (freelancer.hourly_rate && project.budget && project.duration) {
      const estimatedTotal = freelancer.hourly_rate * project.duration * 8;
      if (estimatedTotal <= project.budget * 1.2) {
        budgetCompatibility = 5;
      }
    }

    const total = Math.min(
      100,
      Math.round(
        skillsScore +
          ratingScore +
          experienceScore +
          projectsScore +
          budgetCompatibility,
      ),
    );

    console.log("✅ Final score:", {
      total,
      skillsScore: Math.round(skillsScore),
      ratingScore,
      experienceScore,
      projectsScore,
      budgetCompatibility,
    });

    return {
      total,
      skillsScore: Math.round(skillsScore),
      ratingScore: Math.round(ratingScore),
      experienceScore,
      projectsScore,
      budgetCompatibility,
    };
  }


  static async enhanceWithAI(project, freelancers) {
    try {
      const projectSkills = parseSkills(project.skills);

      const prompt = `
        Project: ${project.title}
        Description: ${project.description}
        Required Skills: ${projectSkills.join(", ")}

        I have ${freelancers.length} freelancers with these profiles:
        ${freelancers
          .map(
            (f, i) => `
          ${i + 1}. ${f.name} - ${f.title}
          Skills: ${f.skills.join(", ")}
          Experience: ${f.experience} years
          Rating: ${f.rating}
        `,
          )
          .join("\n")}

        Rank these freelancers from best to worst for this project. 
        Return ONLY a JSON array of indices [0,2,1,...] showing the best order.
        Consider: skill match, experience, past projects, and rating.
      `;

      const completion = await groqClient.chat.completions.create({
        model: "llama-3.3-70b-versatile",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3,
      });

      const response = completion.choices[0].message.content;
      const aiOrder = JSON.parse(response);

      return aiOrder.map((index) => freelancers[index]);
    } catch (error) {
      console.error("AI enhancement failed:", error);
      return freelancers;
    }
  }
}

export default AIMatchingService;

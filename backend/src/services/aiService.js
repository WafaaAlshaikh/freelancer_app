// services/aiService.js
import { Project, Proposal, FreelancerProfile, User } from "../models/index.js";
import { Op } from "sequelize";
import fs from 'fs';
import Groq from "groq-sdk";

const groqClient = new Groq({ apiKey: process.env.GROQ_API_KEY });

class AIService {
  
  static async extractTextFromPDF(filePath) {
    try {
      console.log('📄 [PDF] Reading PDF file...');
      const dataBuffer = await fs.promises.readFile(filePath);
      console.log('📄 [PDF] Buffer length:', dataBuffer.length);

      const pdfjsLib = await import('pdfjs-dist/legacy/build/pdf.mjs');
      
      const loadingTask = pdfjsLib.getDocument({ data: new Uint8Array(dataBuffer) });
      const pdfDoc = await loadingTask.promise;
      
      console.log(`📄 [PDF] Pages found: ${pdfDoc.numPages}`);
      
      let fullText = '';
      for (let i = 1; i <= pdfDoc.numPages; i++) {
        const page = await pdfDoc.getPage(i);
        const textContent = await page.getTextContent();
        const pageText = textContent.items.map(item => item.str).join(' ');
        fullText += pageText + '\n';
      }

      console.log(`✅ [PDF] Text extracted (${fullText.length} chars)`);
      this.logTextSample(fullText, 'PDF');
      return fullText;

    } catch (error) {
      console.error('❌ [PDF] Error extracting text:', error);
      throw new Error(`Failed to parse PDF: ${error.message}`);
    }
  }


static async analyzeCV(cvText) {
  try {
    console.log('🤖 [AI] STARTING CV ANALYSIS');
    
    const prompt = `
You are a professional CV analyzer. Extract structured information from the following resume.

**Resume Text:**
${cvText.substring(0, 4000)}

**Extract and return ONLY valid JSON with this structure:**
{
  "personal_info": {
    "full_name": "Full name",
    "email": "Email address",
    "phone": "Phone number",
    "location": "City, Country"
  },
  "professional_info": {
    "title": "Professional title (e.g., Senior Flutter Developer)",
    "years_experience": 0,
    "skills": ["skill1", "skill2", "skill3"],
    "languages": ["language1", "language2"],
    "certifications": ["cert1", "cert2"]
  },
  "education": [
    {"degree": "Degree name", "institution": "Institution", "year": "2020"}
  ],
  "bio": "Short professional summary",
  "social_links": {
    "github": "github username or url",
    "linkedin": "linkedin url",
    "website": "portfolio website"
  },
  "confidence_score": 0.95
}`;

    const completion = await groqClient.chat.completions.create({
      model: "llama-3.3-70b-versatile",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.3,
    });
    
    const responseText = completion.choices[0].message.content;
    const parsedData = this.extractJSONFromResponse(responseText);
    const validatedData = this.validateAIResponse(parsedData, cvText);
    
    console.log('✅ [AI] CV ANALYSIS COMPLETE');
    console.log('📊 Extracted:', {
      name: validatedData.personal_info?.full_name,
      title: validatedData.professional_info?.title,
      skills: validatedData.professional_info?.skills?.length,
      github: validatedData.social_links?.github,
      linkedin: validatedData.social_links?.linkedin,
    });
    
    return validatedData;
  } catch (error) {
    console.error('❌ [AI] Error in CV analysis:', error);
    return {
      personal_info: {},
      professional_info: { skills: [], languages: [] },
      education: [],
      bio: '',
      social_links: {},
      confidence_score: 0
    };
  }
}


  static async suggestProjectsForFreelancer(freelancerId, limit = 10) {
    try {
      console.log('=======================================');
      console.log('🎯 [SUGGESTIONS] Finding projects for freelancer:', freelancerId);
      console.log('=======================================');
      
      const freelancer = await FreelancerProfile.findOne({
        where: { UserId: freelancerId }
      });

      if (!freelancer) {
        console.log('❌ [SUGGESTIONS] Freelancer profile not found');
        return [];
      }

      let freelancerSkills = this.parseSkills(freelancer.skills);
      console.log(`📊 [SUGGESTIONS] Freelancer has ${freelancerSkills.length} skills`);

      const projects = await Project.findAll({
        where: {
          status: 'open',
          UserId: { [Op.ne]: freelancerId }
        },
        include: [
          {
            model: User,
            attributes: ['name', 'avatar', 'rating']
          }
        ],
        order: [['createdAt', 'DESC']],
        limit: 50
      });

      console.log(`📊 [SUGGESTIONS] Found ${projects.length} open projects`);

      const scoredProjects = await Promise.all(
        projects.map(async (project) => {
          const existingProposal = await Proposal.findOne({
            where: {
              ProjectId: project.id,
              UserId: freelancerId
            }
          });

          const matchScore = this.calculateMatchScore(
            project,
            freelancerSkills,
            freelancer.experience_years || 0
          );

          return {
            id: project.id,
            title: project.title,
            description: project.description,
            budget: project.budget,
            duration: project.duration,
            category: project.category,
            skills: this.parseSkills(project.skills),
            status: project.status,
            client: project.User,
            createdAt: project.createdAt,
            matchScore,
            hasApplied: !!existingProposal
          };
        })
      );

      scoredProjects.sort((a, b) => {
        if (b.matchScore !== a.matchScore) {
          return b.matchScore - a.matchScore;
        }
        return new Date(b.createdAt) - new Date(a.createdAt);
      });

      const topProjects = scoredProjects.slice(0, limit);
      
      console.log(`✅ [SUGGESTIONS] Returning ${topProjects.length} suggestions`);
      
      return topProjects;

    } catch (error) {
      console.error('❌ [SUGGESTIONS] Error:', error);
      return [];
    }
  }


  static async getAIPersonalizedSuggestions(freelancerId) {
    try {
      console.log('=======================================');
      console.log('🤖 [AI SUGGESTIONS] Getting personalized suggestions');
      console.log('=======================================');
      
      const freelancer = await FreelancerProfile.findOne({
        where: { UserId: freelancerId }
      });

      if (!freelancer) {
        return {
          recommended_categories: [],
          keywords: [],
          reasoning: 'Complete your profile to get suggestions',
          confidence: 0
        };
      }

      let cvText = freelancer.cv_text || '';
      let skills = this.parseSkills(freelancer.skills);

      if (cvText.length > 100) {
        const prompt = `
Based on this freelancer's resume, suggest project categories and search keywords.

Resume: ${cvText.substring(0, 2000)}

Return ONLY valid JSON with no extra text or markdown:
{
  "recommended_categories": ["category1", "category2", "category3", "category4", "category5"],
  "keywords": ["keyword1", "keyword2", "keyword3", "keyword4", "keyword5", "keyword6", "keyword7", "keyword8", "keyword9", "keyword10"],
  "reasoning": "Brief explanation of why these categories fit",
  "confidence": 0.95
}`;

        console.log('🤖 [AI SUGGESTIONS] Sending to Groq...');
        const completion = await groqClient.chat.completions.create({
          model: "llama-3.3-70b-versatile",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.3,
        });
        const responseText = completion.choices[0].message.content;
        const parsed = this.extractJSONFromResponse(responseText);
        
        if (parsed && parsed.recommended_categories) {
          console.log('✅ [AI SUGGESTIONS] AI suggestions generated');
          return parsed;
        }
      }

      console.log('📊 [AI SUGGESTIONS] Using skill-based suggestions');
      const categories = this.getCategoriesFromSkills(skills);
      
      return {
        recommended_categories: categories.slice(0, 5),
        keywords: skills.slice(0, 10),
        reasoning: 'Based on your listed skills',
        confidence: 0.7
      };

    } catch (error) {
      console.error('❌ [AI SUGGESTIONS] Error:', error);
      return {
        recommended_categories: [],
        keywords: [],
        reasoning: 'Unable to generate suggestions',
        confidence: 0
      };
    }
  }

  static extractJSONFromResponse(text) {
    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
      return JSON.parse(text);
    } catch (error) {
      console.error('❌ [JSON] Error parsing JSON:', error.message);
      return null;
    }
  }

  static validateAIResponse(aiData, originalText) {
    if (!aiData || typeof aiData !== 'object') {
      return {
        personal_info: {},
        professional_info: { skills: [], languages: [] },
        education: [],
        bio: '',
        confidence_score: 0.3
      };
    }

    const validated = {
      personal_info: aiData.personal_info || {},
      professional_info: {
        title: aiData.professional_info?.title || aiData.title || '',
        years_experience: aiData.professional_info?.years_experience || aiData.experience_years || 0,
        skills: aiData.professional_info?.skills || aiData.skills || [],
        languages: aiData.professional_info?.languages || aiData.languages || [],
        certifications: aiData.professional_info?.certifications || aiData.certifications || []
      },
      education: aiData.education || [],
      bio: aiData.bio || '',
      confidence_score: aiData.confidence_score || 0.8
    };

    return validated;
  }

  static parseSkills(skillsField) {
    if (!skillsField) return [];
    
    if (Array.isArray(skillsField)) {
      return skillsField;
    }
    
    if (typeof skillsField === 'string') {
      try {
        const parsed = JSON.parse(skillsField);
        return Array.isArray(parsed) ? parsed : [];
      } catch {
        return skillsField.split(',').map(s => s.trim()).filter(s => s.length > 0);
      }
    }
    
    return [];
  }

  static calculateMatchScore(project, freelancerSkills, freelancerExperience) {
    try {
      let score = 0;

      const projectSkills = this.parseSkills(project.skills || []);
      
      if (projectSkills.length > 0 && freelancerSkills.length > 0) {
        const matchedSkills = projectSkills.filter(skill =>
          freelancerSkills.some(fs =>
            fs.toLowerCase().includes(skill.toLowerCase()) ||
            skill.toLowerCase().includes(fs.toLowerCase())
          )
        );
        
        const matchRatio = matchedSkills.length / projectSkills.length;
        score += matchRatio * 70;
      }

      if (freelancerExperience > 0) {
        const experienceScore = Math.min(freelancerExperience / 10, 1) * 30;
        score += experienceScore;
      }

      return Math.min(Math.round(score), 100);
    } catch (error) {
      console.error('❌ [SCORE] Error calculating match score:', error);
      return 0;
    }
  }

  static getCategoriesFromSkills(skills) {
    const categoryMap = {
      'flutter': 'Mobile Development',
      'react': 'Web Development',
      'node': 'Backend Development',
      'python': 'Backend Development',
      'ui': 'UI/UX Design',
      'ux': 'UI/UX Design',
      'design': 'Graphic Design',
      'content': 'Content Writing',
      'seo': 'Digital Marketing',
      'marketing': 'Digital Marketing',
      'wordpress': 'Web Development',
      'php': 'Backend Development',
      'java': 'Mobile Development',
      'swift': 'Mobile Development',
      'kotlin': 'Mobile Development',
      'django': 'Backend Development',
      'mongodb': 'Database',
      'sql': 'Database',
      'aws': 'DevOps',
      'docker': 'DevOps',
      'git': 'Development Tools'
    };

    const categories = new Set();
    
    skills.forEach(skill => {
      const lowerSkill = skill.toLowerCase();
      for (const [key, category] of Object.entries(categoryMap)) {
        if (lowerSkill.includes(key)) {
          categories.add(category);
        }
      }
    });

    return Array.from(categories);
  }

  static logTextSample(text, source) {
    console.log(`📋 [${source} SAMPLE]`);
    const lines = text.split('\n').filter(line => line.trim().length > 0);
    console.log(`   Total lines: ${lines.length}`);
    console.log('   First 3 lines:');
    lines.slice(0, 3).forEach((line, i) => {
      if (line.trim().length > 3) {
        console.log(`   ${i + 1}. ${line.trim().substring(0, 100)}`);
      }
    });
  }

  static logAIResults(analysis) {
    console.log('📊 [AI RESULTS]');
    console.log(`   👤 Name: ${analysis.personal_info?.full_name || 'N/A'}`);
    console.log(`   📧 Email: ${analysis.personal_info?.email || 'Not found'}`);
    console.log(`   🎯 Title: ${analysis.professional_info?.title || 'N/A'}`);
    console.log(`   ⏳ Experience: ${analysis.professional_info?.years_experience || 0} years`);
    console.log(`   🔧 Skills: ${(analysis.professional_info?.skills || []).length} found`);
    console.log(`   ✅ Confidence: ${(analysis.confidence_score * 100).toFixed(0)}%`);
  }
}

export default AIService;
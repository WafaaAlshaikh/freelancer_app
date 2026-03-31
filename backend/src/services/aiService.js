// services/aiService.js
import { Project, Proposal, FreelancerProfile, User } from "../models/index.js";
import { Op } from "sequelize";
import fs from "fs";
import Groq from "groq-sdk";

const groqClient = new Groq({ apiKey: process.env.GROQ_API_KEY });

class AIService {
  static async extractTextFromPDF(filePath) {
    try {
      console.log("📄 [PDF] Reading PDF file...");
      const dataBuffer = await fs.promises.readFile(filePath);
      console.log("📄 [PDF] Buffer length:", dataBuffer.length);

      const pdfjsLib = await import("pdfjs-dist/legacy/build/pdf.mjs");

      const loadingTask = pdfjsLib.getDocument({
        data: new Uint8Array(dataBuffer),
      });
      const pdfDoc = await loadingTask.promise;

      console.log(`📄 [PDF] Pages found: ${pdfDoc.numPages}`);

      let fullText = "";
      for (let i = 1; i <= pdfDoc.numPages; i++) {
        const page = await pdfDoc.getPage(i);
        const textContent = await page.getTextContent();
        const pageText = textContent.items.map((item) => item.str).join(" ");
        fullText += pageText + "\n";
      }

      console.log(`✅ [PDF] Text extracted (${fullText.length} chars)`);
      this.logTextSample(fullText, "PDF");
      return fullText;
    } catch (error) {
      console.error("❌ [PDF] Error extracting text:", error);
      throw new Error(`Failed to parse PDF: ${error.message}`);
    }
  }

  static async analyzeCV(cvText) {
    try {
      console.log("🤖 [AI] STARTING CV ANALYSIS");

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

      console.log("✅ [AI] CV ANALYSIS COMPLETE");
      console.log("📊 Extracted:", {
        name: validatedData.personal_info?.full_name,
        title: validatedData.professional_info?.title,
        skills: validatedData.professional_info?.skills?.length,
        github: validatedData.social_links?.github,
        linkedin: validatedData.social_links?.linkedin,
      });

      return validatedData;
    } catch (error) {
      console.error("❌ [AI] Error in CV analysis:", error);
      return {
        personal_info: {},
        professional_info: { skills: [], languages: [] },
        education: [],
        bio: "",
        social_links: {},
        confidence_score: 0,
      };
    }
  }

  static async suggestProjectsForFreelancer(freelancerId, limit = 10) {
    try {
      console.log("=======================================");
      console.log(
        "🎯 [SUGGESTIONS] Finding projects for freelancer:",
        freelancerId,
      );
      console.log("=======================================");

      const freelancer = await FreelancerProfile.findOne({
        where: { UserId: freelancerId },
      });

      if (!freelancer) {
        console.log("❌ [SUGGESTIONS] Freelancer profile not found");
        return [];
      }

      let freelancerSkills = this.parseSkills(freelancer.skills);
      console.log(
        `📊 [SUGGESTIONS] Freelancer has ${freelancerSkills.length} skills`,
      );

      const projects = await Project.findAll({
        where: {
          status: "open",
          UserId: { [Op.ne]: freelancerId },
        },
        include: [
          {
            model: User,
            attributes: ["name", "avatar", "rating"],
          },
        ],
        order: [["createdAt", "DESC"]],
        limit: 50,
      });

      console.log(`📊 [SUGGESTIONS] Found ${projects.length} open projects`);

      const scoredProjects = await Promise.all(
        projects.map(async (project) => {
          const existingProposal = await Proposal.findOne({
            where: {
              ProjectId: project.id,
              UserId: freelancerId,
            },
          });

          const matchScore = this.calculateMatchScore(
            project,
            freelancerSkills,
            freelancer.experience_years || 0,
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
            hasApplied: !!existingProposal,
          };
        }),
      );

      scoredProjects.sort((a, b) => {
        if (b.matchScore !== a.matchScore) {
          return b.matchScore - a.matchScore;
        }
        return new Date(b.createdAt) - new Date(a.createdAt);
      });

      const topProjects = scoredProjects.slice(0, limit);

      console.log(
        `✅ [SUGGESTIONS] Returning ${topProjects.length} suggestions`,
      );

      return topProjects;
    } catch (error) {
      console.error("❌ [SUGGESTIONS] Error:", error);
      return [];
    }
  }

  static async getAIPersonalizedSuggestions(freelancerId) {
    try {
      console.log("=======================================");
      console.log("🤖 [AI SUGGESTIONS] Getting personalized suggestions");
      console.log("=======================================");

      const freelancer = await FreelancerProfile.findOne({
        where: { UserId: freelancerId },
      });

      if (!freelancer) {
        return {
          recommended_categories: [],
          keywords: [],
          reasoning: "Complete your profile to get suggestions",
          confidence: 0,
        };
      }

      let cvText = freelancer.cv_text || "";
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

        console.log("🤖 [AI SUGGESTIONS] Sending to Groq...");
        const completion = await groqClient.chat.completions.create({
          model: "llama-3.3-70b-versatile",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.3,
        });
        const responseText = completion.choices[0].message.content;
        const parsed = this.extractJSONFromResponse(responseText);

        if (parsed && parsed.recommended_categories) {
          console.log("✅ [AI SUGGESTIONS] AI suggestions generated");
          return parsed;
        }
      }

      console.log("📊 [AI SUGGESTIONS] Using skill-based suggestions");
      const categories = this.getCategoriesFromSkills(skills);

      return {
        recommended_categories: categories.slice(0, 5),
        keywords: skills.slice(0, 10),
        reasoning: "Based on your listed skills",
        confidence: 0.7,
      };
    } catch (error) {
      console.error("❌ [AI SUGGESTIONS] Error:", error);
      return {
        recommended_categories: [],
        keywords: [],
        reasoning: "Unable to generate suggestions",
        confidence: 0,
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
      console.error("❌ [JSON] Error parsing JSON:", error.message);
      return null;
    }
  }

  static validateAIResponse(aiData, originalText) {
    if (!aiData || typeof aiData !== "object") {
      return {
        personal_info: {},
        professional_info: { skills: [], languages: [] },
        education: [],
        bio: "",
        confidence_score: 0.3,
      };
    }

    const validated = {
      personal_info: aiData.personal_info || {},
      professional_info: {
        title: aiData.professional_info?.title || aiData.title || "",
        years_experience:
          aiData.professional_info?.years_experience ||
          aiData.experience_years ||
          0,
        skills: aiData.professional_info?.skills || aiData.skills || [],
        languages:
          aiData.professional_info?.languages || aiData.languages || [],
        certifications:
          aiData.professional_info?.certifications ||
          aiData.certifications ||
          [],
      },
      education: aiData.education || [],
      bio: aiData.bio || "",
      confidence_score: aiData.confidence_score || 0.8,
    };

    return validated;
  }

  static parseSkills(skillsField) {
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
  }

  static calculateMatchScore(project, freelancerSkills, freelancerExperience) {
    try {
      let score = 0;

      const projectSkills = this.parseSkills(project.skills || []);

      if (projectSkills.length > 0 && freelancerSkills.length > 0) {
        const matchedSkills = projectSkills.filter((skill) =>
          freelancerSkills.some(
            (fs) =>
              fs.toLowerCase().includes(skill.toLowerCase()) ||
              skill.toLowerCase().includes(fs.toLowerCase()),
          ),
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
      console.error("❌ [SCORE] Error calculating match score:", error);
      return 0;
    }
  }

  static getCategoriesFromSkills(skills) {
    const categoryMap = {
      flutter: "Mobile Development",
      react: "Web Development",
      node: "Backend Development",
      python: "Backend Development",
      ui: "UI/UX Design",
      ux: "UI/UX Design",
      design: "Graphic Design",
      content: "Content Writing",
      seo: "Digital Marketing",
      marketing: "Digital Marketing",
      wordpress: "Web Development",
      php: "Backend Development",
      java: "Mobile Development",
      swift: "Mobile Development",
      kotlin: "Mobile Development",
      django: "Backend Development",
      mongodb: "Database",
      sql: "Database",
      aws: "DevOps",
      docker: "DevOps",
      git: "Development Tools",
    };

    const categories = new Set();

    skills.forEach((skill) => {
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
    const lines = text.split("\n").filter((line) => line.trim().length > 0);
    console.log(`   Total lines: ${lines.length}`);
    console.log("   First 3 lines:");
    lines.slice(0, 3).forEach((line, i) => {
      if (line.trim().length > 3) {
        console.log(`   ${i + 1}. ${line.trim().substring(0, 100)}`);
      }
    });
  }

  static logAIResults(analysis) {
    console.log("📊 [AI RESULTS]");
    console.log(`   👤 Name: ${analysis.personal_info?.full_name || "N/A"}`);
    console.log(`   📧 Email: ${analysis.personal_info?.email || "Not found"}`);
    console.log(`   🎯 Title: ${analysis.professional_info?.title || "N/A"}`);
    console.log(
      `   ⏳ Experience: ${analysis.professional_info?.years_experience || 0} years`,
    );
    console.log(
      `   🔧 Skills: ${(analysis.professional_info?.skills || []).length} found`,
    );
    console.log(
      `   ✅ Confidence: ${(analysis.confidence_score * 100).toFixed(0)}%`,
    );
  }

  static async analyzeProject(projectData) {
    try {
      console.log("🤖 [AI] Analyzing project for smart pricing...");

      const title = projectData.title || "";
      const description = projectData.description || "";
      const category = projectData.category || "general";
      const skills = projectData.skills || [];

      let projectType = "general";
      if (
        title.toLowerCase().includes("ecommerce") ||
        description.toLowerCase().includes("ecommerce") ||
        title.toLowerCase().includes("shop") ||
        description.toLowerCase().includes("shop")
      ) {
        projectType = "ecommerce";
      } else if (
        title.toLowerCase().includes("mobile") ||
        description.toLowerCase().includes("flutter") ||
        title.toLowerCase().includes("android") ||
        title.toLowerCase().includes("ios")
      ) {
        projectType = "mobile";
      } else if (
        title.toLowerCase().includes("web") ||
        description.toLowerCase().includes("react") ||
        title.toLowerCase().includes("website")
      ) {
        projectType = "web";
      } else if (
        title.toLowerCase().includes("design") ||
        description.toLowerCase().includes("ui/ux")
      ) {
        projectType = "design";
      } else if (
        title.toLowerCase().includes("backend") ||
        description.toLowerCase().includes("api")
      ) {
        projectType = "backend";
      }

      const prompt = `
You are an expert freelancer platform analyst. Analyze this project and provide detailed information.

**Project Details:**
Title: ${title}
Description: ${description}
Category: ${category}
Skills Required: ${skills.join(", ") || "Not specified"}
Project Type: ${projectType}

**Provide ONLY valid JSON with this structure (no other text):**
{
  "difficulty_level": "beginner|intermediate|expert|enterprise",
  "estimated_duration_days": number (between 5-90),
  "price_range": {
    "min": number,
    "max": number,
    "recommended": number,
    "currency": "USD"
  },
  "complexity_factors": ["factor1", "factor2"],
  "market_comparison": {
    "lowest": number,
    "average": number,
    "highest": number
  },
  "suggested_milestones": [
    {"title": "Milestone 1 name", "description": "Detailed description", "percentage": 20},
    {"title": "Milestone 2 name", "description": "Detailed description", "percentage": 40},
    {"title": "Milestone 3 name", "description": "Detailed description", "percentage": 40}
  ],
  "risks": ["risk1", "risk2"],
  "tips": ["tip1", "tip2"]
}

Important: 
- The percentages in suggested_milestones must add up to 100%
- For ${projectType} projects, use appropriate milestone names
- Make milestones realistic and specific to this project

For E-commerce projects, use milestones like: Project Setup, Product Management, Shopping Cart & Payment, Testing & Deployment
For Mobile projects, use: UI/UX Design, Core Development, API Integration, Testing & Store Submission
For Web projects, use: Frontend Development, Backend Development, Database Setup, Testing & Deployment
For Design projects, use: Research & Wireframes, High-Fidelity Design, Prototyping, Final Revisions
`;

      const completion = await groqClient.chat.completions.create({
        model: "llama-3.3-70b-versatile",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.4,
        max_tokens: 1500,
      });

      const responseText = completion.choices[0].message.content;
      console.log("🤖 AI Response:", responseText);

      const analysis = this.extractJSONFromResponse(responseText);
      if (
        !analysis ||
        !analysis.suggested_milestones ||
        analysis.suggested_milestones.length === 0
      ) {
        console.log("⚠️ No milestones from AI, using default");
        const defaultAnalysis = this.getDefaultProjectAnalysis(projectData);
        analysis.suggested_milestones = defaultAnalysis.suggested_milestones;
        analysis.difficulty_level = defaultAnalysis.difficulty_level;
        analysis.estimated_duration_days =
          defaultAnalysis.estimated_duration_days;
        analysis.price_range = defaultAnalysis.price_range;
        analysis.complexity_factors = defaultAnalysis.complexity_factors;
        analysis.risks = defaultAnalysis.risks;
        analysis.tips = defaultAnalysis.tips;
      }

      if (
        !analysis ||
        !analysis.suggested_milestones ||
        analysis.suggested_milestones.length === 0
      ) {
        console.log("⚠️ No milestones from AI, using default");
        return this.getDefaultProjectAnalysis(projectData);
      }

      const totalPercentage = analysis.suggested_milestones.reduce(
        (sum, m) => sum + (m.percentage || 0),
        0,
      );
      if (totalPercentage !== 100 && totalPercentage > 0) {
        const factor = 100 / totalPercentage;
        analysis.suggested_milestones = analysis.suggested_milestones.map(
          (m) => ({
            ...m,
            percentage: Math.round(m.percentage * factor),
          }),
        );
      }

      console.log(
        "✅ [AI] Project analysis complete with",
        analysis.suggested_milestones.length,
        "milestones",
      );
      return analysis;
    } catch (error) {
      console.error("❌ [AI] Error analyzing project:", error);
      return this.getDefaultProjectAnalysis(projectData);
    }
  }

  static getDefaultProjectAnalysis(projectData) {
    const title = projectData.title?.toLowerCase() || "";
    const description = projectData.description?.toLowerCase() || "";
    const basePrice = projectData.budget || 1000;
    const duration = projectData.duration || 21;

    console.log("🔧 Generating default milestones for:", title);

    let suggestedMilestones = [];

    if (
      (title.includes("ecommerce") || description.includes("ecommerce")) &&
      description.includes("flutter") &&
      (description.includes("spring") || description.includes("node"))
    ) {
      suggestedMilestones = [
        {
          title: "Project Setup & Database Design",
          description:
            "Setup Flutter project, Spring Boot backend, PostgreSQL database, authentication system",
          percentage: 15,
        },
        {
          title: "Backend API Development",
          description:
            "RESTful APIs for products, categories, users, orders using Spring Boot",
          percentage: 25,
        },
        {
          title: "Flutter Frontend Development",
          description:
            "UI screens, state management (Provider/Bloc), API integration",
          percentage: 25,
        },
        {
          title: "Employee Management System",
          description:
            "Employee profiles, roles, permissions, work scheduling, task assignment",
          percentage: 15,
        },
        {
          title: "Shopping Cart & Payment",
          description:
            "Cart functionality, Stripe integration, order processing, invoices",
          percentage: 10,
        },
        {
          title: "Testing & Deployment",
          description:
            "Unit tests, integration tests, bug fixes, deployment to production",
          percentage: 10,
        },
      ];
    } else if (
      title.includes("ecommerce") ||
      description.includes("ecommerce")
    ) {
      suggestedMilestones = [
        {
          title: "Project Setup & Database Design",
          description: "Setup project structure, database schema",
          percentage: 20,
        },
        {
          title: "Product Management",
          description: "Product catalog, categories, inventory",
          percentage: 30,
        },
        {
          title: "Shopping Cart & Checkout",
          description: "Cart functionality, payment integration",
          percentage: 30,
        },
        {
          title: "Testing & Deployment",
          description: "QA testing, bug fixes, deployment",
          percentage: 20,
        },
      ];
    } else if (title.includes("flutter") || description.includes("flutter")) {
      suggestedMilestones = [
        {
          title: "UI/UX Design & Setup",
          description: "App design, project setup",
          percentage: 20,
        },
        {
          title: "Core Features Development",
          description: "Main functionality implementation",
          percentage: 40,
        },
        {
          title: "API Integration & Testing",
          description: "Backend integration, testing",
          percentage: 25,
        },
        {
          title: "Store Submission & Final",
          description: "App store submission",
          percentage: 15,
        },
      ];
    } else if (
      title.includes("web") ||
      description.includes("react") ||
      description.includes("website")
    ) {
      suggestedMilestones = [
        {
          title: "Frontend Development",
          description: "UI components, responsive design",
          percentage: 35,
        },
        {
          title: "Backend Development",
          description: "API development, database integration",
          percentage: 35,
        },
        {
          title: "Testing & Deployment",
          description: "QA testing, performance optimization",
          percentage: 30,
        },
      ];
    } else {
      suggestedMilestones = [
        {
          title: "Project Setup & Planning",
          description: "Initial setup and requirements",
          percentage: 20,
        },
        {
          title: "Core Development",
          description: "Main features implementation",
          percentage: 50,
        },
        {
          title: "Testing & Final Delivery",
          description: "QA and final delivery",
          percentage: 30,
        },
      ];
    }

    console.log(`✅ Generated ${suggestedMilestones.length} milestones`);

    return {
      difficulty_level: "expert",
      estimated_duration_days: duration,
      price_range: {
        min: Math.round(basePrice * 0.8),
        max: Math.round(basePrice * 1.2),
        recommended: basePrice,
        currency: "USD",
      },
      complexity_factors: [
        "Full Stack Development",
        "E-commerce Features",
        "Employee Management",
      ],
      market_comparison: {
        lowest: Math.round(basePrice * 0.7),
        average: basePrice,
        highest: Math.round(basePrice * 1.3),
      },
      suggested_milestones: suggestedMilestones,
      risks: ["Timeline management", "Integration complexity", "Scope creep"],
      tips: [
        "Define clear API specs",
        "Use version control",
        "Regular communication",
      ],
    };
  }

  static getDifficultyLevel(description) {
    const desc = description.toLowerCase();
    if (
      desc.includes("full stack") ||
      desc.includes("complex") ||
      desc.includes("enterprise")
    ) {
      return "expert";
    }
    if (
      desc.includes("multiple") ||
      desc.includes("integration") ||
      desc.includes("advanced")
    ) {
      return "intermediate";
    }
    if (desc.includes("simple") || desc.includes("basic")) {
      return "beginner";
    }
    return "intermediate";
  }

  static extractComplexityFactors(projectData) {
    const factors = [];
    const desc = projectData.description?.toLowerCase() || "";

    if (desc.includes("payment") || desc.includes("stripe"))
      factors.push("Payment Integration");
    if (desc.includes("user auth") || desc.includes("login"))
      factors.push("User Authentication");
    if (desc.includes("admin") || desc.includes("dashboard"))
      factors.push("Admin Panel");
    if (desc.includes("real time") || desc.includes("live"))
      factors.push("Real-time Features");
    if (desc.includes("api") || desc.includes("integration"))
      factors.push("API Integration");
    if (desc.includes("mobile") && desc.includes("web"))
      factors.push("Cross-platform Development");

    if (factors.length === 0) factors.push("Standard Development");
    return factors;
  }

  static getRisks(projectData) {
    const risks = [];
    const desc = projectData.description?.toLowerCase() || "";

    if (desc.includes("complex") || desc.includes("advanced")) {
      risks.push("Complex requirements may extend timeline");
    }
    risks.push("Timeline management with multiple features");

    if (desc.includes("integration") || desc.includes("api")) {
      risks.push("Third-party API integration challenges");
    }

    if (risks.length === 1)
      risks.push("Clear communication needed for requirements");
    return risks.slice(0, 3);
  }

  static getTips(projectData) {
    const tips = [];
    const desc = projectData.description?.toLowerCase() || "";

    tips.push("Define clear specifications before starting");
    tips.push("Use Git for version control");
    tips.push("Schedule regular progress meetings");

    if (desc.includes("payment")) {
      tips.push("Test payment flow thoroughly with test cards");
    }
    if (desc.includes("api")) {
      tips.push("Document API endpoints for future reference");
    }

    return tips.slice(0, 4);
  }

  static async getSmartPricing(freelancerId, projectId) {
    try {
      const [freelancer, project] = await Promise.all([
        FreelancerProfile.findOne({ where: { UserId: freelancerId } }),
        Project.findByPk(projectId, {
          include: [{ model: User, as: "client" }],
        }),
      ]);

      if (!freelancer || !project) return null;

      const freelancerSkills = this.parseSkills(freelancer.skills);
      const projectSkills = this.parseSkills(project.skills);
      const matchScore = this.calculateMatchScore(
        project,
        freelancerSkills,
        freelancer.experience_years,
      );

      const prompt = `
Calculate optimal pricing for this freelancer on this project:

**Freelancer:**
- Experience: ${freelancer.experience_years} years
- Rating: ${freelancer.rating || 0}
- Skills: ${freelancerSkills.join(", ")}
- Hourly Rate: ${freelancer.hourly_rate || "Not set"}

**Project:**
- Title: ${project.title}
- Budget Range: ${project.budget}
- Skills: ${projectSkills.join(", ")}
- Match Score: ${matchScore}%

**Provide JSON:**
{
  "recommended_price": number (total project price),
  "recommended_hourly_rate": number,
  "estimated_hours": number,
  "confidence_score": number (0-100),
  "pricing_breakdown": {
    "base_rate": number,
    "complexity_multiplier": number,
    "experience_multiplier": number,
    "market_adjustment": number
  },
  "justification": "Brief explanation"
}
    `;

      const completion = await groqClient.chat.completions.create({
        model: "llama-3.3-70b-versatile",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3,
      });

      const pricing = this.extractJSONFromResponse(
        completion.choices[0].message.content,
      );
      return pricing;
    } catch (error) {
      console.error("❌ Smart pricing error:", error);
      return null;
    }
  }
}

export default AIService;

// services/aiService.js
import {
  Project,
  Proposal,
  FreelancerProfile,
  User,
  Contract,
} from "../models/index.js";
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

  static async getMarketInsights(projectData) {
    try {
      console.log("📊 Getting market insights for:", projectData.category);

      const { category, budget, duration, skills } = projectData;

      const similarProjects = await Project.findAll({
        where: {
          category: category,
          status: "completed",
          budget: {
            [Op.between]: [budget * 0.5, budget * 1.5],
          },
        },
        limit: 20,
        include: [
          {
            model: Contract,
            required: true,
            where: { status: "completed" },
          },
        ],
      });

      if (similarProjects.length === 0) {
        return {
          market_average_duration: duration || 21,
          market_average_cost: budget,
          similar_projects_count: 0,
          success_rate: 85,
          confidence_score: 40,
          message: "Not enough data, using industry standards",
        };
      }

      let totalDuration = 0;
      let totalActualCost = 0;
      let totalBudget = 0;

      for (const project of similarProjects) {
        totalDuration += project.duration || duration;
        totalBudget += project.budget || budget;
        if (project.Contract) {
          totalActualCost +=
            parseFloat(project.Contract.agreed_amount) || project.budget;
        }
      }

      const avgDuration = totalDuration / similarProjects.length;
      const avgBudget = totalBudget / similarProjects.length;
      const avgActualCost = totalActualCost / similarProjects.length;

      const completedCount = similarProjects.filter(
        (p) => p.status === "completed",
      ).length;
      const successRate = (completedCount / similarProjects.length) * 100;

      return {
        market_average_duration: Math.round(avgDuration),
        market_average_cost: Math.round(avgBudget),
        market_actual_cost: Math.round(avgActualCost),
        similar_projects_count: similarProjects.length,
        success_rate: Math.round(successRate),
        confidence_score: Math.min(100, similarProjects.length * 5),
        recommendations: this.generateRecommendations(
          projectData,
          avgBudget,
          avgDuration,
        ),
      };
    } catch (error) {
      console.error("❌ Market insights error:", error);
      return null;
    }
  }

  static generateRecommendations(
    projectData,
    marketAvgBudget,
    marketAvgDuration,
  ) {
    const recommendations = [];

    if (projectData.budget > marketAvgBudget * 1.2) {
      recommendations.push({
        type: "budget",
        message: `Your budget is ${Math.round((projectData.budget / marketAvgBudget - 1) * 100)}% above market average. Consider adjusting for better responses.`,
        suggested_action: "reduce_budget",
      });
    } else if (projectData.budget < marketAvgBudget * 0.8) {
      recommendations.push({
        type: "budget",
        message: `Your budget is below market average. You may receive fewer quality proposals.`,
        suggested_action: "increase_budget",
      });
    }

    if (
      projectData.duration &&
      projectData.duration < marketAvgDuration * 0.7
    ) {
      recommendations.push({
        type: "timeline",
        message: `Your timeline is very aggressive. Similar projects take ${marketAvgDuration} days on average.`,
        suggested_action: "extend_timeline",
      });
    }

    return recommendations;
  }

  static async analyzeProjectWithMarket(projectData) {
    try {
      console.log("🤖 Starting comprehensive project analysis...");

      const baseAnalysis = await this.analyzeProject(projectData);

      const marketInsights = await this.getMarketInsights(projectData);

      const combinedAnalysis = {
        ...baseAnalysis,
        market_insights: marketInsights,
        confidence_score: marketInsights?.confidence_score || 70,
        final_recommendations: this.mergeRecommendations(
          baseAnalysis,
          marketInsights,
        ),
      };

      console.log("✅ Analysis complete with market insights");
      return combinedAnalysis;
    } catch (error) {
      console.error("❌ Analysis error:", error);
      return this.getDefaultProjectAnalysis(projectData);
    }
  }

  static mergeRecommendations(analysis, marketInsights) {
    const recommendations = [];

    if (analysis.tips && analysis.tips.length) {
      recommendations.push(
        ...analysis.tips.map((tip) => ({
          type: "tip",
          message: tip,
          priority: "medium",
        })),
      );
    }

    if (marketInsights?.recommendations) {
      recommendations.push(...marketInsights.recommendations);
    }

    if (analysis.risks && analysis.risks.length) {
      recommendations.push({
        type: "risk",
        message: `Key risks identified: ${analysis.risks.slice(0, 2).join(", ")}`,
        priority: "high",
      });
    }

    return recommendations;
  }

  static async analyzeProposalDraft(proposalData, projectData) {
    const fallback = this.getProposalDraftFallback(proposalData, projectData);

    try {
      if (!process.env.GROQ_API_KEY) {
        return fallback;
      }

      const prompt = `
Evaluate this freelancer proposal quality.

Project:
- Title: ${projectData.title}
- Budget: ${projectData.budget}
- Duration: ${projectData.duration}
- Skills: ${(projectData.skills || []).join(", ")}
- Description: ${projectData.description}

Proposal:
- Price: ${proposalData.price}
- Delivery time: ${proposalData.delivery_time}
- Cover letter: ${proposalData.proposal_text}

Return ONLY valid JSON:
{
  "score": 0-100,
  "strengths": ["..."],
  "improvements": ["..."],
  "risk_level": "low|medium|high",
  "summary": "short paragraph"
}
`;

      const completion = await groqClient.chat.completions.create({
        model: "llama-3.3-70b-versatile",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.2,
      });

      const parsed = this.extractJSONFromResponse(
        completion.choices[0].message.content,
      );

      if (!parsed || typeof parsed !== "object") {
        return fallback;
      }

      return {
        score: Math.max(
          0,
          Math.min(100, Number(parsed.score || fallback.score)),
        ),
        strengths: Array.isArray(parsed.strengths)
          ? parsed.strengths.slice(0, 4)
          : fallback.strengths,
        improvements: Array.isArray(parsed.improvements)
          ? parsed.improvements.slice(0, 5)
          : fallback.improvements,
        risk_level: ["low", "medium", "high"].includes(parsed.risk_level)
          ? parsed.risk_level
          : fallback.risk_level,
        summary: parsed.summary?.toString().trim() || fallback.summary,
      };
    } catch (error) {
      console.error("❌ Proposal draft AI analysis failed:", error.message);
      return fallback;
    }
  }

  static getProposalDraftFallback(proposalData, projectData) {
    const text = (proposalData.proposal_text || "").trim();
    const textLen = text.length;
    const price = Number(proposalData.price || 0);
    const delivery = Number(proposalData.delivery_time || 0);
    const budget = Number(projectData.budget || 0);
    const duration = Number(projectData.duration || 0);

    let score = 50;
    const strengths = [];
    const improvements = [];

    if (textLen >= 120) {
      score += 18;
      strengths.push("Cover letter has enough detail.");
    } else {
      improvements.push("Add more project-specific details in cover letter.");
    }

    if (budget > 0 && price > 0 && price <= budget * 1.1) {
      score += 14;
      strengths.push("Proposed price is aligned with project budget.");
    } else {
      improvements.push("Adjust pricing or justify why it exceeds budget.");
    }

    if (duration > 0 && delivery > 0 && delivery <= duration * 1.2) {
      score += 12;
      strengths.push("Delivery timeline is realistic for the project.");
    } else {
      improvements.push("Revisit delivery estimate to match project scope.");
    }

    if (/experience|deliver|similar|portfolio|solution|approach/i.test(text)) {
      score += 10;
      strengths.push("Proposal mentions relevant expertise/approach.");
    } else {
      improvements.push(
        "Mention related past work and implementation approach.",
      );
    }

    score = Math.max(20, Math.min(95, score));
    const risk_level = score >= 75 ? "low" : score >= 55 ? "medium" : "high";

    return {
      score,
      strengths: strengths.length
        ? strengths
        : ["Basic proposal information provided."],
      improvements: improvements.length
        ? improvements
        : ["Add a short implementation plan to increase trust."],
      risk_level,
      summary:
        "Quality score is generated using pricing, timeline, and cover-letter relevance checks.",
    };
  }

  static async generateProfessionalSOW(
    projectData,
    freelancerData,
    milestones,
    additionalTerms = "",
  ) {
    try {
      console.log("📄 Generating professional SOW...");

      const date = new Date();
      const sowNumber = `SOW-${date.getFullYear()}${(date.getMonth() + 1).toString().padStart(2, "0")}${date.getDate().toString().padStart(2, "0")}-${Math.floor(Math.random() * 1000)}`;

      const totalAmount = milestones.reduce(
        (sum, m) => sum + (m.amount || 0),
        0,
      );

      const analysis = await this.analyzeProjectWithMarket(projectData);

      const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Statement of Work - ${projectData.title}</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: 'Segoe UI', 'Roboto', Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      background: #f5f5f5;
    }
    
    .sow-container {
      max-width: 1100px;
      margin: 40px auto;
      background: white;
      box-shadow: 0 20px 40px rgba(0,0,0,0.1);
      border-radius: 16px;
      overflow: hidden;
    }
    
    /* Header Section */
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 40px;
      text-align: center;
    }
    
    .ai-badge {
      display: inline-block;
      background: rgba(255,255,255,0.2);
      padding: 6px 16px;
      border-radius: 30px;
      font-size: 12px;
      margin-bottom: 20px;
    }
    
    .sow-number {
      font-size: 12px;
      opacity: 0.8;
      margin-top: 8px;
    }
    
    /* Content Sections */
    .content {
      padding: 40px;
    }
    
    .section {
      margin-bottom: 32px;
    }
    
    .section-title {
      font-size: 20px;
      font-weight: 700;
      color: #667eea;
      border-left: 4px solid #667eea;
      padding-left: 16px;
      margin-bottom: 20px;
    }
    
    /* Info Grid */
    .info-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 20px;
      margin-bottom: 20px;
    }
    
    .info-card {
      background: #f8f9fa;
      padding: 16px;
      border-radius: 12px;
    }
    
    .info-label {
      font-size: 11px;
      text-transform: uppercase;
      color: #888;
      letter-spacing: 1px;
    }
    
    .info-value {
      font-size: 18px;
      font-weight: 600;
      margin-top: 4px;
    }
    
    /* Milestones */
    .milestone-card {
      background: #f8f9fa;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 16px;
      border-left: 4px solid #10b981;
    }
    
    .milestone-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
    }
    
    .milestone-title {
      font-size: 18px;
      font-weight: 700;
    }
    
    .milestone-amount {
      font-size: 20px;
      font-weight: 700;
      color: #10b981;
    }
    
    .milestone-desc {
      color: #666;
      margin-bottom: 12px;
    }
    
    .milestone-meta {
      display: flex;
      gap: 20px;
      font-size: 13px;
      color: #888;
    }
    
    /* Total Amount */
    .total-section {
      background: linear-gradient(135deg, #10b981 0%, #059669 100%);
      color: white;
      padding: 20px;
      border-radius: 12px;
      margin: 24px 0;
      text-align: center;
    }
    
    .total-amount {
      font-size: 36px;
      font-weight: 800;
    }
    
    /* AI Analysis */
    .ai-analysis {
      background: linear-gradient(135deg, #f3e8ff 0%, #e9d5ff 100%);
      padding: 24px;
      border-radius: 12px;
      margin: 24px 0;
    }
    
    /* Signature Section */
    .signature-section {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 40px;
      margin-top: 40px;
      padding-top: 40px;
      border-top: 2px dashed #ddd;
    }
    
    .signature-box {
      text-align: center;
    }
    
    .signature-line {
      margin-top: 40px;
      padding-top: 8px;
      border-top: 1px solid #ddd;
      width: 80%;
      margin-left: auto;
      margin-right: auto;
    }
    
    /* Footer */
    .footer {
      background: #f8f9fa;
      padding: 24px;
      text-align: center;
      font-size: 11px;
      color: #888;
    }
    
    @media print {
      body {
        background: white;
        padding: 0;
        margin: 0;
      }
      .sow-container {
        margin: 0;
        box-shadow: none;
      }
      .header {
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }
    }
  </style>
</head>
<body>
  <div class="sow-container">
    <div class="header">
      <div class="ai-badge">
        🤖 AI-Generated Document
      </div>
      <h1 style="font-size: 32px; margin-bottom: 8px;">Statement of Work</h1>
      <div class="sow-number">Document ID: ${sowNumber}</div>
      <div>Date: ${date.toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}</div>
    </div>
    
    <div class="content">
      <!-- Parties Information -->
      <div class="section">
        <h2 class="section-title">Parties Involved</h2>
        <div class="info-grid">
          <div class="info-card">
            <div class="info-label">Client</div>
            <div class="info-value">${this.escapeHtml(projectData.clientName || "Client")}</div>
            <div style="font-size: 13px; color: #666;">${projectData.clientEmail || ""}</div>
          </div>
          <div class="info-card">
            <div class="info-label">Freelancer / Service Provider</div>
            <div class="info-value">${this.escapeHtml(freelancerData.name || "Freelancer")}</div>
            <div style="font-size: 13px; color: #666;">${freelancerData.email || ""}</div>
          </div>
        </div>
      </div>
      
      <!-- Project Overview -->
      <div class="section">
        <h2 class="section-title">Project Overview</h2>
        <div class="info-grid">
          <div class="info-card">
            <div class="info-label">Project Title</div>
            <div class="info-value">${this.escapeHtml(projectData.title)}</div>
          </div>
          <div class="info-card">
            <div class="info-label">Category</div>
            <div class="info-value">${projectData.category || "General"}</div>
          </div>
        </div>
        <div class="info-card" style="margin-top: 12px;">
          <div class="info-label">Description</div>
          <div class="info-value" style="font-size: 14px; font-weight: normal;">${this.escapeHtml(projectData.description)}</div>
        </div>
      </div>
      
      <!-- Required Skills -->
      ${
        projectData.skills && projectData.skills.length
          ? `
      <div class="section">
        <h2 class="section-title">Required Skills & Technologies</h2>
        <div style="display: flex; flex-wrap: wrap; gap: 8px;">
          ${projectData.skills.map((skill) => `<span style="background: #e0e7ff; color: #4f46e5; padding: 6px 12px; border-radius: 20px; font-size: 13px;">${this.escapeHtml(skill)}</span>`).join("")}
        </div>
      </div>
      `
          : ""
      }
      
      <!-- AI Market Analysis -->
      <div class="ai-analysis">
        <h3 style="display: flex; align-items: center; gap: 8px; margin-bottom: 16px;">
          <span>🧠</span> AI Market Analysis
        </h3>
        <div class="info-grid" style="grid-template-columns: repeat(3, 1fr);">
          <div>
            <div class="info-label">Difficulty Level</div>
            <div class="info-value" style="font-size: 16px;">${analysis.difficulty_level || "Intermediate"}</div>
          </div>
          <div>
            <div class="info-label">Est. Duration</div>
            <div class="info-value" style="font-size: 16px;">${analysis.estimated_duration_days || "21"} days</div>
          </div>
          <div>
            <div class="info-label">Confidence Score</div>
            <div class="info-value" style="font-size: 16px;">${analysis.confidence_score || "85"}%</div>
          </div>
        </div>
        ${
          analysis.market_insights
            ? `
        <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid rgba(0,0,0,0.1);">
          <div class="info-label">Market Insights</div>
          <div style="font-size: 14px; margin-top: 8px;">
            Based on ${analysis.market_insights.similar_projects_count || 0} similar projects:
            • Average market price: $${analysis.market_insights.market_average_cost || 0}
            • Average duration: ${analysis.market_insights.market_average_duration || 0} days
            • Success rate: ${analysis.market_insights.success_rate || 0}%
          </div>
        </div>
        `
            : ""
        }
      </div>
      
      <!-- Scope of Work -->
      <div class="section">
        <h2 class="section-title">Scope of Work</h2>
        <p>The Service Provider agrees to deliver the following scope of work:</p>
        <ul style="margin-top: 12px; margin-left: 20px;">
          <li>Complete all deliverables as described in the project requirements</li>
          <li>Provide weekly progress updates</li>
          <li>Deliver source code and documentation upon completion</li>
          <li>Provide ${analysis.estimated_duration_days || 30} days of post-completion support</li>
        </ul>
      </div>
      
      <!-- Milestones & Payment Schedule -->
      <div class="section">
        <h2 class="section-title">Milestones & Payment Schedule</h2>
        ${milestones
          .map(
            (milestone, index) => `
          <div class="milestone-card">
            <div class="milestone-header">
              <span class="milestone-title">Milestone ${index + 1}: ${this.escapeHtml(milestone.title)}</span>
              <span class="milestone-amount">$${milestone.amount?.toLocaleString() || 0}</span>
            </div>
            <div class="milestone-desc">${this.escapeHtml(milestone.description || "No description provided")}</div>
            <div class="milestone-meta">
              <span>📅 Due: ${milestone.due_date ? new Date(milestone.due_date).toLocaleDateString() : "To be determined"}</span>
              <span>📊 ${milestone.percentage || 0}% of total</span>
            </div>
          </div>
        `,
          )
          .join("")}
        
        <div class="total-section">
          <div>Total Contract Value</div>
          <div class="total-amount">$${totalAmount.toLocaleString()}</div>
          <div style="font-size: 13px; margin-top: 8px;">Payment will be held in escrow and released upon milestone approval</div>
        </div>
      </div>
      
      <!-- Terms & Conditions -->
      <div class="section">
        <h2 class="section-title">Terms & Conditions</h2>
        
        <div style="margin-bottom: 20px;">
          <h3 style="font-size: 16px; margin-bottom: 8px;">1. Intellectual Property</h3>
          <p>Upon full payment, all intellectual property rights, including source code, designs, and documentation, shall transfer to the Client. The Service Provider retains the right to include the work in their portfolio.</p>
        </div>
        
        <div style="margin-bottom: 20px;">
          <h3 style="font-size: 16px; margin-bottom: 8px;">2. Confidentiality</h3>
          <p>Both parties agree to keep all project-related information confidential. The Service Provider shall not disclose any proprietary information to third parties without written consent.</p>
        </div>
        
        <div style="margin-bottom: 20px;">
          <h3 style="font-size: 16px; margin-bottom: 8px;">3. Payment Terms</h3>
          <p>All payments are processed through the platform's secure escrow system. Milestone payments are released only after client approval of deliverables.</p>
        </div>
        
        <div style="margin-bottom: 20px;">
          <h3 style="font-size: 16px; margin-bottom: 8px;">4. Timeline & Delivery</h3>
          <p>The Service Provider agrees to deliver milestones according to the schedule above. Any delays must be communicated 48 hours in advance.</p>
        </div>
        
        <div style="margin-bottom: 20px;">
          <h3 style="font-size: 16px; margin-bottom: 8px;">5. Quality Assurance</h3>
          <p>All deliverables must meet industry standards and the specifications outlined in this document. The Client has 7 days after each milestone to request revisions.</p>
        </div>
        
        <div style="margin-bottom: 20px;">
          <h3 style="font-size: 16px; margin-bottom: 8px;">6. Termination</h3>
          <p>Either party may terminate this agreement with 7 days written notice. In case of termination, payment will be made for completed work.</p>
        </div>
        
        ${
          additionalTerms
            ? `
        <div style="margin-bottom: 20px;">
          <h3 style="font-size: 16px; margin-bottom: 8px;">7. Additional Terms</h3>
          <p>${this.escapeHtml(additionalTerms)}</p>
        </div>
        `
            : ""
        }
        
        <div style="margin-bottom: 20px;">
          <h3 style="font-size: 16px; margin-bottom: 8px;">8. Dispute Resolution</h3>
          <p>Any disputes arising from this agreement shall be resolved through the platform's dispute resolution process. Both parties agree to cooperate in good faith.</p>
        </div>
      </div>
      
      <!-- Risk Analysis -->
      ${
        analysis.risks && analysis.risks.length
          ? `
      <div class="section">
        <h2 class="section-title">Risk Analysis & Mitigation</h2>
        <ul style="margin-left: 20px;">
          ${analysis.risks.map((risk) => `<li style="margin-bottom: 8px;">⚠️ ${this.escapeHtml(risk)}</li>`).join("")}
        </ul>
      </div>
      `
          : ""
      }
      
      <!-- Signatures -->
      <div class="signature-section">
        <div class="signature-box">
          <div class="signature-line"></div>
          <div><strong>Client Signature</strong></div>
          <div style="font-size: 12px; color: #888; margin-top: 8px;">Date: _____________</div>
        </div>
        <div class="signature-box">
          <div class="signature-line"></div>
          <div><strong>Service Provider Signature</strong></div>
          <div style="font-size: 12px; color: #888; margin-top: 8px;">Date: _____________</div>
        </div>
      </div>
    </div>
    
    <div class="footer">
      <p>This Statement of Work is generated by AI and is legally binding.</p>
      <p>© ${new Date().getFullYear()} Freelancer Platform - All rights reserved.</p>
      <p>Document ID: ${sowNumber} | Generated: ${date.toISOString()}</p>
    </div>
  </div>
</body>
</html>
      `;

      console.log("✅ SOW generated successfully");
      return { html, sowNumber, analysis };
    } catch (error) {
      console.error("❌ SOW generation error:", error);
      throw error;
    }
  }

  static escapeHtml(text) {
    if (!text) return "";
    return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  static async analyzeProjectEnhanced(projectData) {
    try {
      console.log("🚀 [ENHANCED] Starting enhanced project analysis...");

      const aiResult = await this.analyzeProject(projectData);

      const marketInsights = await this.getMarketInsights(projectData);

      let confidenceScore = 85;

      if (marketInsights && marketInsights.similar_projects_count > 0) {
        confidenceScore = Math.min(
          95,
          70 + marketInsights.similar_projects_count,
        );
      }

      return {
        ...aiResult,
        confidence_score: confidenceScore,
        market_insights: marketInsights,
        analyzed_at: new Date().toISOString(),
        ai_provider: "groq-llama-3.3-70b",
      };
    } catch (error) {
      console.error("❌ Enhanced analysis failed:", error);
      return this.getDefaultProjectAnalysis(projectData);
    }
  }

  static async analyzeProjectQuick(projectData) {
    try {
      console.log("⚡ [QUICK] Quick project analysis...");

      const prompt = `
Quickly analyze this project and return JSON (keep it brief):

Title: ${projectData.title || "Untitled"}
Category: ${projectData.category || "general"}

Return ONLY:
{
  "difficulty": "beginner|intermediate|expert",
  "duration_days": number (5-60),
  "price_min": number,
  "price_max": number,
  "key_skill": "main skill needed"
}`;

      const completion = await groqClient.chat.completions.create({
        model: "llama-3.3-70b-versatile",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3,
        max_tokens: 200,
      });

      const quickResult = this.extractJSONFromResponse(
        completion.choices[0].message.content,
      );

      return {
        difficulty_level: quickResult.difficulty || "intermediate",
        estimated_duration_days: quickResult.duration_days || 14,
        price_range: {
          min: quickResult.price_min || 500,
          max: quickResult.price_max || 1500,
          recommended:
            (quickResult.price_min + quickResult.price_max) / 2 || 1000,
          currency: "USD",
        },
        key_skill: quickResult.key_skill || "General",
        quick_analysis: true,
      };
    } catch (error) {
      console.error("Quick analysis failed:", error);
      return null;
    }
  }

  static ensureValidMilestones(milestones, title, description) {
    if (milestones && Array.isArray(milestones) && milestones.length > 0) {
      const validMilestones = milestones.filter(
        (m) => m.title && typeof m.percentage === "number" && m.percentage > 0,
      );

      if (validMilestones.length > 0) {
        const total = validMilestones.reduce((sum, m) => sum + m.percentage, 0);
        if (total !== 100 && total > 0) {
          const factor = 100 / total;
          validMilestones.forEach((m) => {
            m.percentage = Math.round(m.percentage * factor);
          });
        }
        return validMilestones;
      }
    }

    const text = `${title} ${description}`.toLowerCase();

    if (text.includes("ecommerce") || text.includes("shop")) {
      return [
        {
          title: "Project Setup",
          description: "Initial setup",
          percentage: 20,
        },
        {
          title: "Product Management",
          description: "Products & categories",
          percentage: 30,
        },
        {
          title: "Cart & Payment",
          description: "Shopping cart & payment",
          percentage: 30,
        },
        {
          title: "Testing & Deployment",
          description: "QA & deployment",
          percentage: 20,
        },
      ];
    }

    return [
      { title: "Setup", description: "Initial setup", percentage: 20 },
      { title: "Development", description: "Core features", percentage: 50 },
      { title: "Delivery", description: "Testing & delivery", percentage: 30 },
    ];
  }
}

export default AIService;

// backend/src/controllers/aiChatController.js

import AIService from "../services/aiService.js";
import {
  User,
  Project,
  FreelancerProfile,
  Contract,
  Proposal,
} from "../models/index.js";

class AIChatController {
  static async getUserContext(userId, role, context) {
    try {
      console.log("📊 Getting user context for:", { userId, role });

      const user = await User.findByPk(userId);
      const contextData = {
        name: user?.name?.split(" ")[0] || "User",
        skills: [],
        projectCount: 0,
        additionalContext: "",
      };

      if (role === "freelancer") {
        const profile = await FreelancerProfile.findOne({
          where: { UserId: userId },
        });
        const proposals = await Proposal.count({ where: { UserId: userId } });
        const contracts = await Contract.count({
          where: { FreelancerId: userId, status: "active" },
        });

        contextData.skills = AIService.parseSkills(profile?.skills);
        contextData.additionalContext = `Proposals submitted: ${proposals}\nActive contracts: ${contracts}`;

        if (context?.projectId) {
          const project = await Project.findByPk(context.projectId);
          if (project) {
            contextData.additionalContext += `\nCurrently viewing project: "${project.title}" - Budget: $${project.budget}`;
          }
        }
      } else if (role === "client") {
        const projects = await Project.count({ where: { UserId: userId } });
        const contracts = await Contract.count({
          where: { ClientId: userId, status: "active" },
        });

        contextData.projectCount = projects;
        contextData.additionalContext = `Total projects posted: ${projects}\nActive contracts: ${contracts}`;

        if (context?.projectId) {
          const project = await Project.findByPk(context.projectId);
          if (project) {
            contextData.additionalContext += `\nProject: "${project.title}" - ${project.proposals_count || 0} proposals received`;
          }
        }
      }

      console.log("✅ User context loaded:", contextData);
      return contextData;
    } catch (error) {
      console.error("❌ Error getting user context:", error);
      return {
        name: "User",
        skills: [],
        projectCount: 0,
        additionalContext: "",
      };
    }
  }

  static getFallbackResponse(message, role) {
    const msg = message.toLowerCase();

    if (msg.includes("proposal") || msg.includes("propose")) {
      return "To write a good proposal:\n\n1. Start with a personalized greeting\n2. Show you understand the project requirements\n3. Highlight your relevant experience\n4. Provide a clear timeline\n5. Ask clarifying questions\n\nWould you like help with a specific proposal?";
    }

    if (
      msg.includes("price") ||
      msg.includes("budget") ||
      msg.includes("cost")
    ) {
      if (role === "freelancer") {
        return "For pricing your work:\n\n- Research market rates for your skills\n- Consider project complexity\n- Factor in your experience level\n- Use our Smart Pricing feature for AI recommendations\n\nWhat type of project are you pricing?";
      } else {
        return "For setting a project budget:\n\n- Research average rates for required skills\n- Consider project scope and timeline\n- Use our AI analysis for budget suggestions\n- Start with a reasonable range to attract quality freelancers";
      }
    }

    if (msg.includes("profile")) {
      return "To improve your profile:\n\n1. Add a professional photo\n2. Write a compelling bio\n3. List your key skills\n4. Showcase portfolio items\n5. Get verified\n6. Add your work experience\n\nNeed help with any specific section?";
    }

    if (msg.includes("project") || msg.includes("find work")) {
      if (role === "freelancer") {
        return "To find great projects:\n\n1. Browse the 'Find Work' tab\n2. Use filters to match your skills\n3. Check AI recommendations\n4. Apply to projects that fit your expertise\n\nWant me to help you search for something specific?";
      } else {
        return "To post a successful project:\n\n1. Write a clear title\n2. Provide detailed description\n3. Set realistic budget\n4. Define required skills\n5. Use AI analysis for optimization\n\nReady to create a new project?";
      }
    }

    return "I'm your AI assistant! I can help you with:\n\n📝 Writing proposals\n💰 Pricing your work\n📊 Finding projects\n👤 Improving your profile\n📄 Understanding contracts\n\nWhat would you like help with?";
  }

  static async chat(req, res) {
    try {
      const { message, context } = req.body;
      const userId = req.user.id;
      const userRole = req.user.role;

      console.log("🤖 AI Chat request:", {
        message: message?.substring(0, 50),
        userId,
        userRole,
      });

      const userContext = await AIChatController.getUserContext(
        userId,
        userRole,
        context,
      );

      const responseText = AIChatController.getFallbackResponse(
        message,
        userRole,
      );
      const suggestedActions = [
        { label: "Browse Projects", action: "navigate", screen: "projects" },
        { label: "View Profile", action: "navigate", screen: "profile" },
      ];

      res.json({
        success: true,
        reply: responseText,
        suggestedActions: suggestedActions,
        timestamp: new Date(),
      });
    } catch (error) {
      console.error("❌ AI Chat error:", error);
      res.json({
        success: true,
        reply:
          "I'm here to help! What would you like to know about the platform?",
        suggestedActions: [
          { label: "Browse Projects", action: "navigate", screen: "projects" },
          { label: "Contact Support", action: "open", url: "/support" },
        ],
      });
    }
  }

  static async getChatHistory(req, res) {
    try {
      res.json({ success: true, history: [] });
    } catch (error) {
      console.error("Error getting chat history:", error);
      res.json({ success: true, history: [] });
    }
  }

  static async clearChatHistory(req, res) {
    try {
      res.json({ success: true, message: "Chat history cleared" });
    } catch (error) {
      console.error("Error clearing chat history:", error);
      res.json({ success: true, message: "Chat history cleared" });
    }
  }
}

export default AIChatController;

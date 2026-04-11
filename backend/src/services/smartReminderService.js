// backend/src/services/smartReminderService.js
import cron from "node-cron";
import { Op } from "sequelize";
import { InterviewInvitation, User, Project } from "../models/index.js";
import NotificationService from "./notificationService.js";
import { emitToUser } from "./websocketService.js";
import { sendInterviewReminderEmail } from "./emailService.js";

class SmartReminderService {
  static isInitialized = false;

  static init() {
    if (this.isInitialized) {
      console.log("⚠️ Smart Reminder Service already initialized");
      return;
    }

    cron.schedule("0 * * * *", async () => {
      console.log("⏰ Running smart reminder check...");
      await this.checkAndSendReminders();
    });

    cron.schedule("0 0 * * *", async () => {
      console.log("🧹 Cleaning expired interviews...");
      await this.cleanExpiredInterviews();
    });

    this.isInitialized = true;
    console.log("✅ Smart Reminder Service initialized");
  }

  static async checkAndSendReminders() {
    try {
      const now = new Date();
      const interviews = await InterviewInvitation.findAll({
        where: {
          status: "accepted",
          selected_time: { [Op.gt]: now },
        },
        include: [
          { model: User, as: "client" },
          { model: User, as: "freelancer" },
          { model: Project },
        ],
      });

      console.log(`📋 Checking ${interviews.length} upcoming interviews`);

      for (const interview of interviews) {
        const timeDiff = new Date(interview.selected_time) - now;
        const hoursDiff = timeDiff / (1000 * 60 * 60);

        if (hoursDiff <= 24 && hoursDiff > 23 && !interview.reminder_sent_24h) {
          await this.send24HourReminder(interview);
          await interview.update({ reminder_sent_24h: true });
          console.log(`📧 Sent 24h reminder for interview ${interview.id}`);
        }

        if (hoursDiff <= 1 && hoursDiff > 0.9 && !interview.reminder_sent_1h) {
          await this.send1HourReminder(interview);
          await interview.update({ reminder_sent_1h: true });
          console.log(`🚨 Sent 1h reminder for interview ${interview.id}`);
        }

        if (
          hoursDiff <= 2 &&
          hoursDiff > 1.9 &&
          !interview.preparation_checklist_sent
        ) {
          await this.sendPreparationChecklist(interview);
          await interview.update({ preparation_checklist_sent: true });
          console.log(
            `📋 Sent preparation checklist for interview ${interview.id}`,
          );
        }
      }
    } catch (error) {
      console.error("Error in checkAndSendReminders:", error);
    }
  }

  static async send24HourReminder(interview) {
    const checklist = [
      "📋 Review project requirements",
      "💻 Test your microphone and camera",
      "🌐 Ensure stable internet connection",
      "📝 Prepare your portfolio/examples",
      "❓ Prepare questions to ask",
      "⏰ Set a personal alarm",
    ];

    await NotificationService.createNotification({
      userId: interview.freelancer_id,
      type: "interview_reminder_24h",
      title: "⏰ Interview Tomorrow!",
      body: `Your interview for "${interview.Project.title}" is tomorrow. Here's your preparation checklist:\n${checklist.join("\n")}`,
      data: {
        invitationId: interview.id,
        checklist: checklist,
        screen: "interview",
      },
    });

    await NotificationService.createNotification({
      userId: interview.client_id,
      type: "interview_reminder_24h",
      title: "⏰ Interview Tomorrow!",
      body: `Your interview with ${interview.freelancer.name} for "${interview.Project.title}" is tomorrow.`,
      data: {
        invitationId: interview.id,
        screen: "interview",
      },
    });

    emitToUser(interview.freelancer_id, "interview_reminder", {
      invitationId: interview.id,
      hoursBefore: 24,
      checklist: checklist,
      projectTitle: interview.Project.title,
    });

    emitToUser(interview.client_id, "interview_reminder", {
      invitationId: interview.id,
      hoursBefore: 24,
      projectTitle: interview.Project.title,
      freelancerName: interview.freelancer.name,
    });

    try {
      await sendInterviewReminderEmail(
        interview,
        interview.client,
        interview.freelancer,
        interview.Project,
        24,
      );
    } catch (emailError) {
      console.error("Failed to send reminder email:", emailError);
    }
  }

  static async send1HourReminder(interview) {
    const urgentChecklist = [
      "🎥 Join the meeting now",
      "🎤 Test audio/video one more time",
      "📂 Have your portfolio ready",
      "📝 Take notes during the call",
    ];

    await NotificationService.createNotification({
      userId: interview.freelancer_id,
      type: "interview_reminder_1h",
      title: "🔔 Interview in 1 Hour!",
      body: `Your interview for "${interview.Project.title}" starts in 1 hour. Join here: ${interview.meeting_link}\n\n${urgentChecklist.join("\n")}`,
      data: {
        invitationId: interview.id,
        meetingLink: interview.meeting_link,
        screen: "interview",
      },
    });

    await NotificationService.createNotification({
      userId: interview.client_id,
      type: "interview_reminder_1h",
      title: "🔔 Interview in 1 Hour!",
      body: `Your interview with ${interview.freelancer.name} for "${interview.Project.title}" starts in 1 hour. Join here: ${interview.meeting_link}`,
      data: {
        invitationId: interview.id,
        meetingLink: interview.meeting_link,
        screen: "interview",
      },
    });

    emitToUser(interview.freelancer_id, "interview_urgent", {
      invitationId: interview.id,
      meetingLink: interview.meeting_link,
      projectTitle: interview.Project.title,
    });

    emitToUser(interview.client_id, "interview_urgent", {
      invitationId: interview.id,
      meetingLink: interview.meeting_link,
      projectTitle: interview.Project.title,
      freelancerName: interview.freelancer.name,
    });

    try {
      await sendInterviewReminderEmail(
        interview,
        interview.client,
        interview.freelancer,
        interview.Project,
        1,
      );
    } catch (emailError) {
      console.error("Failed to send urgent reminder email:", emailError);
    }
  }

  static async sendPreparationChecklist(interview) {
    const checklist = [
      {
        title: "Technical Setup",
        items: [
          "Test microphone and camera",
          "Check internet speed (minimum 5 Mbps)",
          "Close unnecessary applications",
          "Charge your device",
        ],
      },
      {
        title: "Content Preparation",
        items: [
          "Review project requirements",
          "Prepare 3 questions for the client",
          "Have portfolio/examples ready",
          "Note your key strengths",
        ],
      },
      {
        title: "Professional Setup",
        items: [
          "Choose quiet, well-lit location",
          "Professional background",
          "Dress appropriately",
          "Have notepad and pen ready",
        ],
      },
    ];

    await NotificationService.createNotification({
      userId: interview.freelancer_id,
      type: "preparation_checklist",
      title: "📋 Interview Preparation Checklist",
      body: `Get ready for your interview with "${interview.Project.title}"\n\nUse this checklist to prepare:`,
      data: {
        invitationId: interview.id,
        checklist: checklist,
        screen: "preparation",
      },
    });

    emitToUser(interview.freelancer_id, "preparation_checklist", {
      invitationId: interview.id,
      checklist: checklist,
      projectTitle: interview.Project.title,
    });
  }

  static async cleanExpiredInterviews() {
    try {
      const [updatedCount] = await InterviewInvitation.update(
        { status: "expired" },
        {
          where: {
            status: "pending",
            expires_at: { [Op.lt]: new Date() },
          },
        },
      );

      if (updatedCount > 0) {
        console.log(`🧹 Cleaned up ${updatedCount} expired interviews`);
      }
    } catch (error) {
      console.error("Error cleaning expired interviews:", error);
    }
  }
}

export default SmartReminderService;

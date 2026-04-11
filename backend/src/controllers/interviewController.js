import {
  InterviewInvitation,
  Proposal,
  Project,
  User,
  Notification,
} from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "../services/notificationService.js";
import SmartSchedulingService from "../services/smartSchedulingService.js";
import {
  sendInterviewInvitationEmail,
  sendInterviewConfirmationEmail,
} from "../services/emailService.js";
import SmartReminderService from "../services/smartReminderService.js";

const generateMeetingLink = () => {
  const meetingId = Math.random().toString(36).substring(2, 12);
  return `https://meet.google.com/${meetingId}`;
};

const sendInterviewReminder = async (invitation) => {
  if (invitation.selected_time) {
    const reminderTime = new Date(invitation.selected_time);
    reminderTime.setHours(reminderTime.getHours() - 1);

    const now = new Date();
    const delay = reminderTime - now;

    if (delay > 0) {
      setTimeout(async () => {
        await NotificationService.createNotification({
          userId: invitation.freelancer_id,
          type: "interview_reminder",
          title: "Interview Reminder ⏰",
          body: `Your interview for project is in 1 hour!`,
          data: {
            invitationId: invitation.id,
            screen: "interview",
          },
        });

        await NotificationService.createNotification({
          userId: invitation.client_id,
          type: "interview_reminder",
          title: "Interview Reminder ⏰",
          body: `Your interview with the freelancer is in 1 hour!`,
          data: {
            invitationId: invitation.id,
            screen: "interview",
          },
        });
      }, delay);
    }
  }
};

export const createInterviewInvitation = async (req, res) => {
  try {
    const { proposal_id, suggested_times, message, duration_minutes } =
      req.body;
    const clientId = req.user.id;

    if (!suggested_times || suggested_times.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Please provide at least one suggested time",
      });
    }

    console.log("📧 Creating interview invitation for proposal:", proposal_id);

    const proposal = await Proposal.findByPk(proposal_id, {
      include: [
        { model: Project, include: [{ model: User, as: "client" }] },
        { model: User, as: "freelancer" },
      ],
    });

    if (!proposal) {
      return res
        .status(404)
        .json({ success: false, message: "Proposal not found" });
    }

    if (proposal.Project.UserId !== clientId) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    if (proposal.status !== "pending" && proposal.status !== "negotiating") {
      return res.status(400).json({
        success: false,
        message: `Cannot invite for interview at this stage (current status: ${proposal.status})`,
      });
    }

    await proposal.update({ status: "interviewing" });

    const existingInvitation = await InterviewInvitation.findOne({
      where: { proposal_id, status: { [Op.in]: ["pending", "accepted"] } },
    });

    if (existingInvitation) {
      return res.status(400).json({
        success: false,
        message: "An active invitation already exists for this proposal",
      });
    }

    const invitation = await InterviewInvitation.create({
      proposal_id,
      client_id: clientId,
      freelancer_id: proposal.UserId,
      project_id: proposal.ProjectId,
      suggested_times: suggested_times || [],
      message,
      duration_minutes: duration_minutes || 30,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      status: "pending",
    });

    await NotificationService.createNotification({
      userId: proposal.UserId,
      type: "interview_invitation",
      title: "🎯 Interview Invitation",
      body: `${req.user.name} wants to interview you for "${proposal.Project.title}"`,
      data: {
        invitationId: invitation.id,
        proposalId: proposal.id,
        projectId: proposal.ProjectId,
        screen: "interview",
      },
    });

    const freelancer = await User.findByPk(proposal.UserId);

    console.log("✅ Interview invitation created:", invitation.id);

    res.json({
      success: true,
      message: "Interview invitation sent successfully",
      invitation,
    });
  } catch (error) {
    console.error("❌ Error creating interview invitation:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
};

export const getUserInterviews = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const { status } = req.query;

    const where = {};
    if (userRole === "client") {
      where.client_id = userId;
    } else {
      where.freelancer_id = userId;
    }

    if (status && status !== "all") {
      where.status = status;
    }

    const invitations = await InterviewInvitation.findAll({
      where,
      include: [
        {
          model: Proposal,
          include: [
            {
              model: Project,
              include: [
                {
                  model: User,
                  as: "client",
                  attributes: ["id", "name", "avatar"],
                },
              ],
            },
          ],
        },
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar", "email"],
        },
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name", "avatar", "email"],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    const stats = {
      pending: invitations.filter((i) => i.status === "pending").length,
      accepted: invitations.filter((i) => i.status === "accepted").length,
      completed: invitations.filter((i) => i.status === "completed").length,
      total: invitations.length,
    };

    res.json({ success: true, invitations, stats });
  } catch (error) {
    console.error("❌ Error getting interviews:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
};

export const getInterviewById = async (req, res) => {
  try {
    const { invitationId } = req.params;
    const userId = req.user.id;

    const invitation = await InterviewInvitation.findByPk(invitationId, {
      include: [
        {
          model: Proposal,
          include: [
            {
              model: Project,
              include: [
                {
                  model: User,
                  as: "client",
                  attributes: ["id", "name", "avatar"],
                },
              ],
            },
          ],
        },
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar", "email"],
        },
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name", "avatar", "email"],
        },
      ],
    });

    if (!invitation) {
      return res
        .status(404)
        .json({ success: false, message: "Invitation not found" });
    }

    if (
      invitation.client_id !== userId &&
      invitation.freelancer_id !== userId
    ) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    res.json({ success: true, invitation });
  } catch (error) {
    console.error("❌ Error getting interview:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
};

export const respondToInterview = async (req, res) => {
  try {
    const { invitationId } = req.params;
    const { status, selected_time, response_message } = req.body;
    const userId = req.user.id;

    console.log(
      `📝 Responding to interview ${invitationId} with status: ${status}`,
    );

    const invitation = await InterviewInvitation.findByPk(invitationId, {
      include: [
        {
          model: Proposal,
          include: [{ model: Project }],
        },
        { model: User, as: "client" },
        { model: User, as: "freelancer" },
      ],
    });

    if (!invitation) {
      return res
        .status(404)
        .json({ success: false, message: "Invitation not found" });
    }

    if (invitation.freelancer_id !== userId) {
      return res
        .status(403)
        .json({ success: false, message: "Only the freelancer can respond" });
    }

    if (invitation.status !== "pending") {
      return res
        .status(400)
        .json({ success: false, message: "Invitation already responded to" });
    }

    if (new Date() > new Date(invitation.expires_at)) {
      await invitation.update({ status: "expired" });
      return res
        .status(400)
        .json({ success: false, message: "Invitation has expired" });
    }

    if (status === "accepted") {
      if (!selected_time) {
        return res.status(400).json({
          success: false,
          message: "No time selected",
        });
      }

      const selectedDateTime = new Date(selected_time);

      const suggestedTimes = Array.isArray(invitation.suggested_times)
        ? invitation.suggested_times
        : [];

      const isValidTime = suggestedTimes.some(
        (time) => new Date(time).getTime() === selectedDateTime.getTime(),
      );

      if (!isValidTime) {
        return res.status(400).json({
          success: false,
          message: "Invalid time selected",
        });
      }
    }

    const updateData = {
      status,
      response_message,
      responded_at: new Date(),
    };

    if (status === "accepted" && selected_time) {
      updateData.selected_time = new Date(selected_time);
      updateData.meeting_link = generateMeetingLink();
    }

    await invitation.update(updateData);

    const client = invitation.client;
    const freelancer = invitation.freelancer;
    const project = invitation.Proposal?.Project;

    await NotificationService.createNotification({
      userId: invitation.client_id,
      type: "interview_response",
      title:
        status === "accepted"
          ? "✅ Interview Accepted"
          : "❌ Interview Declined",
      body:
        status === "accepted"
          ? `${req.user.name} has accepted your interview invitation`
          : `${req.user.name} has declined your interview invitation`,
      data: {
        invitationId: invitation.id,
        proposalId: invitation.proposal_id,
        screen: "interview",
      },
    });

    if (status === "accepted" && updateData.selected_time) {
      await sendInterviewReminder(invitation);

      await NotificationService.createNotification({
        userId: invitation.freelancer_id,
        type: "interview_accepted",
        title: "🎥 Interview Scheduled",
        body: `Your interview is scheduled for ${new Date(updateData.selected_time).toLocaleString()}. Join here: ${updateData.meeting_link}`,
        data: {
          invitationId: invitation.id,
          meetingLink: updateData.meeting_link,
          screen: "interview",
        },
      });

      await NotificationService.createNotification({
        userId: invitation.client_id,
        type: "interview_accepted",
        title: "🎥 Interview Scheduled",
        body: `The interview is scheduled for ${new Date(updateData.selected_time).toLocaleString()}. Join here: ${updateData.meeting_link}`,
        data: {
          invitationId: invitation.id,
          meetingLink: updateData.meeting_link,
          screen: "interview",
        },
      });

      try {
        if (client && freelancer && project) {
          await sendInterviewConfirmationEmail(
            invitation,
            client,
            freelancer,
            project,
          );
          console.log("✅ Confirmation email sent successfully");
        } else {
          console.warn("⚠️ Missing data for email:", {
            hasClient: !!client,
            hasFreelancer: !!freelancer,
            hasProject: !!project,
          });
        }
      } catch (emailError) {
        console.error("❌ Failed to send confirmation email:", emailError);
      }
    }

    console.log(`✅ Interview ${invitationId} responded: ${status}`);

    res.json({
      success: true,
      message:
        status === "accepted" ? "Interview accepted" : "Interview declined",
      invitation,
    });
  } catch (error) {
    console.error("❌ Error responding to interview:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
};

export const rescheduleInterview = async (req, res) => {
  try {
    const { invitationId } = req.params;
    const { new_time, reason } = req.body;
    const userId = req.user.id;

    const invitation = await InterviewInvitation.findByPk(invitationId);

    if (!invitation) {
      return res
        .status(404)
        .json({ success: false, message: "Invitation not found" });
    }

    if (
      invitation.client_id !== userId &&
      invitation.freelancer_id !== userId
    ) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    if (invitation.status !== "accepted") {
      return res.status(400).json({
        success: false,
        message: "Can only reschedule accepted interviews",
      });
    }

    await invitation.update({
      status: "rescheduled",
      selected_time: new Date(new_time),
      reschedule_reason: reason,
      meeting_link: generateMeetingLink(),
    });

    const otherPartyId =
      userId === invitation.client_id
        ? invitation.freelancer_id
        : invitation.client_id;

    await NotificationService.createNotification({
      userId: otherPartyId,
      type: "interview_rescheduled",
      title: "🔄 Interview Rescheduled",
      body: `The interview has been rescheduled to ${new Date(new_time).toLocaleString()}`,
      data: {
        invitationId: invitation.id,
        newTime: new_time,
        screen: "interview",
      },
    });

    res.json({
      success: true,
      message: "Interview rescheduled successfully",
      invitation,
    });
  } catch (error) {
    console.error("❌ Error rescheduling interview:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
};

export const addInterviewNotes = async (req, res) => {
  try {
    const { invitationId } = req.params;
    const { meeting_notes, feedback } = req.body;
    const userId = req.user.id;

    const invitation = await InterviewInvitation.findByPk(invitationId);

    if (!invitation) {
      return res
        .status(404)
        .json({ success: false, message: "Invitation not found" });
    }

    if (
      invitation.client_id !== userId &&
      invitation.freelancer_id !== userId
    ) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    await invitation.update({
      meeting_notes,
      feedback,
      status: "completed",
    });

    const otherPartyId =
      userId === invitation.client_id
        ? invitation.freelancer_id
        : invitation.client_id;

    await NotificationService.createNotification({
      userId: otherPartyId,
      type: "interview_completed",
      title: "📝 Interview Completed",
      body: "The interview has been completed and notes have been added.",
      data: {
        invitationId: invitation.id,
        screen: "interview",
      },
    });

    res.json({
      success: true,
      message: "Interview notes added successfully",
      invitation,
    });
  } catch (error) {
    console.error("❌ Error adding interview notes:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
};

export const cancelInterview = async (req, res) => {
  try {
    const { invitationId } = req.params;
    const { reason } = req.body;
    const userId = req.user.id;

    const invitation = await InterviewInvitation.findByPk(invitationId);

    if (!invitation) {
      return res
        .status(404)
        .json({ success: false, message: "Invitation not found" });
    }

    if (
      invitation.client_id !== userId &&
      invitation.freelancer_id !== userId
    ) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    await invitation.update({
      status: "declined",
      response_message: reason || "Interview cancelled",
      responded_at: new Date(),
    });

    const otherPartyId =
      userId === invitation.client_id
        ? invitation.freelancer_id
        : invitation.client_id;

    await NotificationService.createNotification({
      userId: otherPartyId,
      type: "interview_cancelled",
      title: "❌ Interview Cancelled",
      body: `The interview has been cancelled. Reason: ${reason || "Not specified"}`,
      data: {
        invitationId: invitation.id,
        screen: "interview",
      },
    });

    res.json({
      success: true,
      message: "Interview cancelled successfully",
      invitation,
    });
  } catch (error) {
    console.error("❌ Error cancelling interview:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
};

export const getInterviewStats = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    const where = {};
    if (userRole === "client") {
      where.client_id = userId;
    } else {
      where.freelancer_id = userId;
    }

    const stats = {
      total: await InterviewInvitation.count({ where }),
      pending: await InterviewInvitation.count({
        where: { ...where, status: "pending" },
      }),
      accepted: await InterviewInvitation.count({
        where: { ...where, status: "accepted" },
      }),
      completed: await InterviewInvitation.count({
        where: { ...where, status: "completed" },
      }),
      declined: await InterviewInvitation.count({
        where: { ...where, status: "declined" },
      }),
      expired: await InterviewInvitation.count({
        where: { ...where, status: "expired" },
      }),
    };

    res.json({ success: true, stats });
  } catch (error) {
    console.error("❌ Error getting interview stats:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
};

export const createSmartInterviewInvitation = async (req, res) => {
  try {
    const { proposal_id, message, duration_minutes } = req.body;
    const clientId = req.user.id;

    console.log(
      "🤖 Creating SMART interview invitation for proposal:",
      proposal_id,
    );

    const proposal = await Proposal.findByPk(proposal_id, {
      include: [
        { model: Project, include: [{ model: User, as: "client" }] },
        { model: User, as: "freelancer" },
      ],
    });

    if (!proposal) {
      return res
        .status(404)
        .json({ success: false, message: "Proposal not found" });
    }

    if (proposal.Project.UserId !== clientId) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    if (proposal.status !== "pending" && proposal.status !== "negotiating") {
      return res.status(400).json({
        success: false,
        message: `Cannot invite for interview at this stage (current status: ${proposal.status})`,
      });
    }

    let suggestedTimes = await SmartSchedulingService.suggestSmartTimes(
      proposal_id,
      clientId,
      proposal.UserId,
    );

    if (!suggestedTimes || !Array.isArray(suggestedTimes)) {
      console.warn("⚠️ Smart scheduling returned invalid data, using fallback");
      suggestedTimes = SmartSchedulingService.getFallbackSuggestions();
    }

    if (suggestedTimes.length === 0) {
      console.warn("⚠️ No smart times generated, using fallback");
      suggestedTimes = SmartSchedulingService.getFallbackSuggestions();
    }

    const suggestedTimesStrings = suggestedTimes.map((time) => {
      if (time instanceof Date) {
        return time.toISOString();
      }
      return time;
    });

    await proposal.update({ status: "interviewing" });

    const existingInvitation = await InterviewInvitation.findOne({
      where: { proposal_id, status: { [Op.in]: ["pending", "accepted"] } },
    });

    if (existingInvitation) {
      return res.status(400).json({
        success: false,
        message: "An active invitation already exists for this proposal",
      });
    }

    const invitation = await InterviewInvitation.create({
      proposal_id,
      client_id: clientId,
      freelancer_id: proposal.UserId,
      project_id: proposal.ProjectId,
      suggested_times: suggestedTimesStrings,
      message:
        message ||
        "AI-suggested interview times based on availability analysis.",
      duration_minutes: duration_minutes || 30,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      status: "pending",
    });

    await NotificationService.createNotification({
      userId: proposal.UserId,
      type: "interview_invitation",
      title: "🎯 Smart Interview Invitation",
      body: `${req.user.name} wants to interview you for "${proposal.Project.title}". AI has suggested optimal times!`,
      data: {
        invitationId: invitation.id,
        proposalId: proposal.id,
        projectId: proposal.ProjectId,
        screen: "interview",
      },
    });

    try {
      const freelancer = await User.findByPk(proposal.UserId);
      const client = await User.findByPk(clientId);

      if (freelancer && freelancer.email) {
        await sendInterviewInvitationEmail(
          freelancer,
          client,
          proposal.Project,
          invitation,
        );
        console.log("✅ Email sent to freelancer:", freelancer.email);
      } else {
        console.warn("⚠️ Cannot send email: freelancer not found or no email");
      }
    } catch (emailError) {
      console.error(
        "❌ Failed to send email, but invitation was created:",
        emailError,
      );
    }

    console.log("✅ Smart interview invitation created:", invitation.id);

    res.json({
      success: true,
      message: "Smart interview invitation sent successfully to freelancer",
      invitation: {
        ...invitation.toJSON(),
        suggested_times: suggestedTimesStrings,
      },
      suggestedTimes: suggestedTimesStrings,
    });
  } catch (error) {
    console.error("❌ Error creating smart interview:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
      stack: process.env.NODE_ENV === "development" ? error.stack : undefined,
    });
  }
};

export const getSmartAnalytics = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    const analytics = await SmartSchedulingService.analyzeOptimalTimes(
      userId,
      userRole,
    );

    res.json({
      success: true,
      analytics,
    });
  } catch (error) {
    console.error("❌ Error getting smart analytics:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
};

export const getTimeSuggestions = async (req, res) => {
  try {
    const { proposalId, freelancerId } = req.query;
    const clientId = req.user.id;

    const suggestions = await SmartSchedulingService.suggestSmartTimes(
      parseInt(proposalId),
      clientId,
      parseInt(freelancerId),
    );

    res.json({
      success: true,
      suggestions,
    });
  } catch (error) {
    console.error("❌ Error getting time suggestions:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
};

export const createGroupInterviewInvitation = async (req, res) => {
  try {
    const {
      proposal_id,
      freelancer_ids,
      suggested_times,
      message,
      duration_minutes,
    } = req.body;
    const clientId = req.user.id;

    const proposal = await Proposal.findByPk(proposal_id, {
      include: [{ model: Project }],
    });

    if (!proposal || proposal.Project.UserId !== clientId) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    const invitations = [];
    for (const freelancerId of freelancer_ids) {
      const invitation = await InterviewInvitation.create({
        proposal_id,
        client_id: clientId,
        freelancer_id: freelancerId,
        project_id: proposal.ProjectId,
        suggested_times: suggested_times || [],
        message: message || "Group interview invitation",
        duration_minutes: duration_minutes || 30,
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        status: "pending",
        group_interview: true,
        participant_ids: freelancer_ids,
      });

      invitations.push(invitation);

      await NotificationService.createNotification({
        userId: freelancerId,
        type: "group_interview_invitation",
        title: "👥 Group Interview Invitation",
        body: `You have been invited to a group interview for "${proposal.Project.title}"`,
        data: {
          invitationId: invitation.id,
          groupSize: freelancer_ids.length,
          screen: "interview",
        },
      });
    }

    res.json({
      success: true,
      message: `Group interview invitations sent to ${freelancer_ids.length} freelancers`,
      invitations,
    });
  } catch (error) {
    console.error("Error creating group interview:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const addToCalendar = async (req, res) => {
  try {
    const { invitationId, calendarType } = req.body;
    const userId = req.user.id;

    const invitation = await InterviewInvitation.findByPk(invitationId, {
      include: [
        { model: User, as: "client" },
        { model: User, as: "freelancer" },
        { model: Project },
      ],
    });

    if (
      !invitation ||
      (invitation.client_id !== userId && invitation.freelancer_id !== userId)
    ) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    let result;
    if (calendarType === "google") {
      const user = await User.findByPk(userId);
      if (!user.google_access_token) {
        return res.status(400).json({
          success: false,
          message: "Please connect your Google Calendar first",
        });
      }
      result = await CalendarService.addToGoogleCalendar(
        user.google_access_token,
        invitation,
        invitation.Project,
      );
    } else if (calendarType === "ics") {
      const filePath = CalendarService.generateICSFile(
        invitation,
        invitation.Project,
      );
      res.download(filePath);
      return;
    }

    res.json({
      success: true,
      message: `Added to ${calendarType} calendar successfully`,
      event: result,
    });
  } catch (error) {
    console.error("Error adding to calendar:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const sendManualReminder = async (req, res) => {
  try {
    const { invitationId } = req.params;
    const userId = req.user.id;

    const invitation = await InterviewInvitation.findByPk(invitationId, {
      include: [
        { model: User, as: "client" },
        { model: User, as: "freelancer" },
        { model: Project },
      ],
    });

    if (
      !invitation ||
      (invitation.client_id !== userId && invitation.freelancer_id !== userId)
    ) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    await SmartReminderService.send1HourReminder(invitation);

    res.json({
      success: true,
      message: "Reminder sent successfully",
    });
  } catch (error) {
    console.error("Error sending reminder:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const addPostInterviewFeedback = async (req, res) => {
  try {
    const { invitationId } = req.params;
    const { rating, comment, improvements, wouldHireAgain } = req.body;
    const userId = req.user.id;

    const invitation = await InterviewInvitation.findByPk(invitationId);

    if (
      !invitation ||
      (invitation.client_id !== userId && invitation.freelancer_id !== userId)
    ) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    await invitation.update({
      feedback_rating: rating,
      feedback_comment: comment,
      feedback_improvements: improvements,
      feedback_would_hire_again: wouldHireAgain,
    });

    const otherPartyId =
      userId === invitation.client_id
        ? invitation.freelancer_id
        : invitation.client_id;

    const { Rating } = await import("../models/index.js");
    const ratings = await Rating.findAll({
      where: { toUserId: otherPartyId },
      attributes: ["rating"],
    });

    if (ratings.length > 0) {
      const total = ratings.reduce((sum, r) => sum + r.rating, 0);
      const average = total / ratings.length;

      await User.update({ rating: average }, { where: { id: otherPartyId } });

      console.log(`✅ Updated rating for user ${otherPartyId} to ${average}`);
    }

    res.json({
      success: true,
      message: "Feedback submitted successfully",
    });
  } catch (error) {
    console.error("Error submitting feedback:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const exportInterviewStats = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    const where =
      userRole === "client" ? { client_id: userId } : { freelancer_id: userId };

    const interviews = await InterviewInvitation.findAll({
      where,
      include: [
        { model: Project, attributes: ["title"] },
        { model: User, as: "freelancer", attributes: ["name", "email"] },
        { model: User, as: "client", attributes: ["name", "email"] },
      ],
      order: [["createdAt", "DESC"]],
    });

    const csvHeaders = [
      "ID",
      "Project",
      "Status",
      "Created At",
      "Responded At",
      "Selected Time",
      "Duration",
      "Meeting Link",
      "Client Name",
      "Client Email",
      "Freelancer Name",
      "Freelancer Email",
      "Rating",
      "Feedback",
      "Improvements",
    ];

    const csvRows = interviews.map((i) => [
      i.id,
      i.Project?.title || "",
      i.status,
      i.createdAt,
      i.respondedAt || "",
      i.selected_time || "",
      i.duration_minutes,
      i.meeting_link || "",
      i.client?.name || "",
      i.client?.email || "",
      i.freelancer?.name || "",
      i.freelancer?.email || "",
      i.feedback_rating || "",
      i.feedback_comment || "",
      i.feedback_improvements || "",
    ]);

    const csvContent = [csvHeaders, ...csvRows]
      .map((row) =>
        row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(","),
      )
      .join("\n");

    res.setHeader("Content-Type", "text/csv");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename=interview_stats_${Date.now()}.csv`,
    );
    res.send(csvContent);
  } catch (error) {
    console.error("Error exporting stats:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const compareFreelancers = async (req, res) => {
  try {
    const { freelancerIds, projectId } = req.body;

    const comparisons = await Promise.all(
      freelancerIds.map(async (id) => {
        const user = await User.findByPk(id, {
          include: [{ model: UserProfile, as: "profile" }],
        });

        const interviews = await InterviewInvitation.findAll({
          where: { freelancer_id: id, status: "completed" },
          include: [{ model: Project }],
        });

        const averageRating =
          interviews.reduce((sum, i) => sum + (i.feedback_rating || 0), 0) /
          (interviews.length || 1);
        const completionRate =
          interviews.filter((i) => i.status === "completed").length /
          (interviews.length || 1);

        return {
          id: user.id,
          name: user.name,
          avatar: user.avatar,
          skills: user.profile?.skills || [],
          experience: user.profile?.experience_years || 0,
          rating: averageRating,
          completionRate: completionRate * 100,
          totalInterviews: interviews.length,
          projectsCompleted: user.profile?.completed_projects || 0,
        };
      }),
    );

    res.json({
      success: true,
      comparisons,
    });
  } catch (error) {
    console.error("Error comparing freelancers:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getQuestionLibrary = async (req, res) => {
  const questions = {
    technical: [
      {
        id: 1,
        question: "What is your experience with similar projects?",
        category: "Experience",
        difficulty: "Easy",
      },
      {
        id: 2,
        question: "How do you handle project requirements that are unclear?",
        category: "Problem Solving",
        difficulty: "Medium",
      },
      {
        id: 3,
        question: "Describe a technical challenge you overcame recently.",
        category: "Technical",
        difficulty: "Medium",
      },
      {
        id: 4,
        question: "What tools and technologies do you prefer and why?",
        category: "Technical",
        difficulty: "Easy",
      },
      {
        id: 5,
        question: "How do you ensure code quality and maintainability?",
        category: "Best Practices",
        difficulty: "Hard",
      },
    ],
    portfolio: [
      {
        id: 6,
        question: "Can you walk me through your most successful project?",
        category: "Portfolio",
        difficulty: "Medium",
      },
      {
        id: 7,
        question: "What was your specific role in the project?",
        category: "Portfolio",
        difficulty: "Easy",
      },
      {
        id: 8,
        question: "How did you handle conflicts or disagreements?",
        category: "Teamwork",
        difficulty: "Medium",
      },
    ],
    softSkills: [
      {
        id: 9,
        question: "How do you handle tight deadlines?",
        category: "Time Management",
        difficulty: "Medium",
      },
      {
        id: 10,
        question: "Describe a time you had to learn a new skill quickly.",
        category: "Adaptability",
        difficulty: "Medium",
      },
      {
        id: 11,
        question: "How do you communicate progress to clients?",
        category: "Communication",
        difficulty: "Easy",
      },
      {
        id: 12,
        question: "What's your approach to receiving feedback?",
        category: "Professionalism",
        difficulty: "Easy",
      },
    ],
    cultural: [
      {
        id: 13,
        question: "What's your preferred working style?",
        category: "Work Style",
        difficulty: "Easy",
      },
      {
        id: 14,
        question: "How do you stay motivated during long projects?",
        category: "Motivation",
        difficulty: "Medium",
      },
    ],
  };

  res.json({
    success: true,
    questions,
  });
};

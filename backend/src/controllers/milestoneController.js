// controllers/milestoneController.js
import { Contract, Project } from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "../services/notificationService.js";

export const updateMilestoneProgress = async (req, res) => {
  try {
    const { contractId, milestoneIndex, progress, status } = req.body;
    const userId = req.user.id;

    const contract = await Contract.findOne({
      where: { 
        id: contractId,
        FreelancerId: userId
      }
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const milestones = contract.milestones;
    if (!milestones[milestoneIndex]) {
      return res.status(400).json({ message: "Milestone not found" });
    }

    milestones[milestoneIndex].progress = progress || 0;
    if (status) {
      milestones[milestoneIndex].status = status;
    }
    if (status === 'completed') {
      milestones[milestoneIndex].completed_at = new Date();
    }

    const totalProgress = milestones.reduce((sum, m) => sum + (m.progress || 0), 0) / milestones.length;

    await contract.update({
      milestones: JSON.stringify(milestones),
      milestone_progress: JSON.stringify({
        ...contract.milestone_progress,
        [`milestone_${milestoneIndex}`]: {
          progress,
          status,
          updatedAt: new Date()
        }
      })
    });

    res.json({
      message: "✅ Milestone updated",
      milestone: milestones[milestoneIndex],
      totalProgress
    });

  } catch (err) {
    console.error("Error updating milestone:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};


export const addReminder = async (req, res) => {
  try {
    const { contractId, title, dueDate, description } = req.body;
    const userId = req.user.id;

    const contract = await Contract.findOne({
      where: {
        id: contractId,
        [Op.or]: [
          { FreelancerId: userId },
          { ClientId: userId }
        ]
      }
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const reminders = contract.reminders;
    const newReminder = {
      id: Date.now().toString(),
      title,
      description,
      dueDate,
      createdAt: new Date(),
      createdBy: userId,
      completed: false
    };

    reminders.push(newReminder);

    await contract.update({
      reminders: JSON.stringify(reminders)
    });

    const user = await User.findByPk(userId);
    await NotificationService.createNotification({
      userId: userId,
      type: 'reminder',
      title: 'Reminder Set 📅',
      body: `Reminder "${title}" set for ${new Date(dueDate).toLocaleDateString()}`,
      data: {
        contractId: contract.id,
        reminderId: newReminder.id,
        screen: 'calendar',
      },
    });

    res.json({
      message: "✅ Reminder added",
      reminder: newReminder
    });

  } catch (err) {
    console.error("Error adding reminder:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const completeReminder = async (req, res) => {
  try {
    const { contractId, reminderId } = req.params;

    const contract = await Contract.findByPk(contractId);
    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const reminders = contract.reminders;
    const reminderIndex = reminders.findIndex(r => r.id === reminderId);

    if (reminderIndex === -1) {
      return res.status(404).json({ message: "Reminder not found" });
    }

    reminders[reminderIndex].completed = true;
    reminders[reminderIndex].completedAt = new Date();

    await contract.update({
      reminders: JSON.stringify(reminders)
    });

    res.json({ message: "✅ Reminder completed" });

  } catch (err) {
    console.error("Error completing reminder:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getCalendar = async (req, res) => {
  try {
    const { year, month } = req.query;
    const userId = req.user.id;
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);

    const contracts = await Contract.findAll({
      where: {
        [Op.or]: [
          { FreelancerId: userId },
          { ClientId: userId }
        ],
        status: {
          [Op.in]: ['active', 'pending_client', 'pending_freelancer']
        }
      },
      include: [Project]
    });

    const events = [];

    contracts.forEach(contract => {
  let milestones = contract.milestones;
  if (typeof milestones === 'string') {
    milestones = JSON.parse(milestones);
  }

  let reminders = contract.reminders;
  if (typeof reminders === 'string') {
    reminders = JSON.parse(reminders);
  }

  if (Array.isArray(milestones)) {
    milestones.forEach((milestone, index) => {
      const dueDate = new Date(milestone.due_date);
      if (dueDate >= startDate && dueDate <= endDate) {
        events.push({
          id: `milestone-${contract.id}-${index}`,
          title: milestone.title,
          date: dueDate,
          type: 'milestone',
          contractId: contract.id,
          projectTitle: contract.Project?.title,
          status: milestone.status,
          progress: milestone.progress
        });
      }
    });
  }

  if (Array.isArray(reminders)) {
    reminders.forEach(reminder => {
      const dueDate = new Date(reminder.dueDate);
      if (dueDate >= startDate && dueDate <= endDate) {
        events.push({
          id: `reminder-${contract.id}-${reminder.id}`,
          title: reminder.title,
          date: dueDate,
          type: 'reminder',
          contractId: contract.id,
          completed: reminder.completed
        });
      }
    });
  }
});

    res.json(events);

  } catch (err) {
    console.error("Error getting calendar:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getUpcomingEvents = async (req, res) => {
  try {
    const { days } = req.query;
    const userId = req.user.id;
    const now = new Date();
    const future = new Date(now.getTime() + (days || 30) * 24 * 60 * 60 * 1000);

    const contracts = await Contract.findAll({
      where: {
        [Op.or]: [
          { FreelancerId: userId },
          { ClientId: userId }
        ],
        status: ['active', 'pending_client', 'pending_freelancer']
      },
      include: [Project]
    });

    const events = [];

    contracts.forEach(contract => {
      const milestones = contract.milestones;
      milestones.forEach((milestone, index) => {
        const dueDate = new Date(milestone.due_date);
        if (dueDate >= now && dueDate <= future) {
          const daysLeft = Math.ceil((dueDate - now) / (1000 * 60 * 60 * 24));
          
          if (daysLeft <= 3 && daysLeft > 0 && milestone.status !== 'completed') {
            NotificationService.createNotification({
              userId: contract.FreelancerId,
              type: 'milestone_due',
              title: 'Milestone Due Soon! ⏰',
              body: `"${milestone.title}" is due in ${daysLeft} day${daysLeft > 1 ? 's' : ''}`,
              data: {
                contractId: contract.id,
                milestoneIndex: index,
                screen: 'contract',
              },
            });
          }
          
          events.push({
            id: `milestone-${contract.id}-${index}`,
            title: milestone.title,
            date: dueDate,
            type: 'milestone',
            contractId: contract.id,
            projectTitle: contract.Project?.title,
            daysLeft: daysLeft
          });
        }
      });
    });

    res.json(events);
  } catch (err) {
    console.error("Error in getUpcomingEvents:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const completeMilestone = async (req, res) => {
  try {
    const { contractId, milestoneIndex } = req.params;
    const userId = req.user.id;

    const contract = await Contract.findOne({
      where: { id: contractId, FreelancerId: userId }
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const milestones = contract.milestones;
    const milestone = milestones[milestoneIndex];

    if (!milestone) {
      return res.status(404).json({ message: "Milestone not found" });
    }

    if (milestone.status === 'completed') {
      return res.status(400).json({ message: "Milestone already completed" });
    }

    milestone.status = 'completed';
    milestone.completed_at = new Date();
    milestones[milestoneIndex] = milestone;

    await contract.update({ milestones: JSON.stringify(milestones) });

    await NotificationService.createNotification({
      userId: contract.ClientId,
      type: 'milestone_completed',
      title: 'Milestone Completed',
      body: `"${milestone.title}" has been marked as completed. Please review.`,
      data: { contractId: contract.id, milestoneIndex, screen: 'contract' },
    });

    res.json({
      message: "✅ Milestone completed",
      milestone,
    });
  } catch (err) {
    console.error("Error completing milestone:", err);
    res.status(500).json({ message: "Server error" });
  }
};
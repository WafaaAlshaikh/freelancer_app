import { Op } from "sequelize";
import { InterviewInvitation, User, Contract } from "../models/index.js";

class SmartSchedulingService {
  static async analyzeOptimalTimes(userId, userRole) {
    try {
      const where = {};
      if (userRole === "client") {
        where.client_id = userId;
      } else {
        where.freelancer_id = userId;
      }

      const pastInterviews = await InterviewInvitation.findAll({
        where: {
          ...where,
          status: { [Op.in]: ["accepted", "completed"] },
          selected_time: { [Op.not]: null },
        },
      });

      const hourStats = Array(24).fill(0);
      const dayStats = Array(7).fill(0);

      for (const interview of pastInterviews) {
        const hour = new Date(interview.selected_time).getHours();
        const day = new Date(interview.selected_time).getDay();
        hourStats[hour]++;
        dayStats[day]++;
      }

      const bestHours = hourStats
        .map((count, hour) => ({ hour, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 3)
        .map((h) => h.hour);

      const bestDays = dayStats
        .map((count, day) => ({ day, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 3)
        .map((d) => d.day);

      return {
        bestHours,
        bestDays,
        averageResponseTime: await this.calculateAverageResponseTime(userId),
        preferredDuration: await this.getPreferredDuration(userId),
      };
    } catch (error) {
      console.error("Error analyzing optimal times:", error);
      return {
        bestHours: [10, 14, 16],
        bestDays: [1, 2, 3],
        averageResponseTime: 24,
        preferredDuration: 30,
      };
    }
  }

  static async suggestSmartTimes(proposalId, clientId, freelancerId) {
    try {
      const [clientPreferences, freelancerPreferences] = await Promise.all([
        this.analyzeOptimalTimes(clientId, "client"),
        this.analyzeOptimalTimes(freelancerId, "freelancer"),
      ]);

      const existingInterviews = await InterviewInvitation.findAll({
        where: {
          [Op.or]: [{ client_id: clientId }, { freelancer_id: freelancerId }],
          status: { [Op.in]: ["pending", "accepted"] },
          selected_time: { [Op.not]: null },
        },
      });

      const busyTimes = existingInterviews.map(
        (i) => new Date(i.selected_time),
      );

      const suggestions = [];
      const now = new Date();
      const startDate = new Date(now);
      startDate.setDate(startDate.getDate() + 2);

      for (
        let dayOffset = 0;
        dayOffset < 14 && suggestions.length < 5;
        dayOffset++
      ) {
        const date = new Date(startDate);
        date.setDate(startDate.getDate() + dayOffset);
        const dayOfWeek = date.getDay();

        const isGoodDay =
          clientPreferences.bestDays.includes(dayOfWeek) ||
          freelancerPreferences.bestDays.includes(dayOfWeek);

        if (!isGoodDay) continue;

        const hoursToTry = [
          ...clientPreferences.bestHours,
          ...freelancerPreferences.bestHours,
        ]
          .sort((a, b) => a - b)
          .filter((v, i, a) => a.indexOf(v) === i);

        for (const hour of hoursToTry) {
          const timeSlot = new Date(date);
          timeSlot.setHours(hour, 0, 0, 0);

          const isBusy = busyTimes.some(
            (busy) =>
              Math.abs(busy.getTime() - timeSlot.getTime()) < 60 * 60 * 1000,
          );

          if (!isBusy && timeSlot > now) {
            suggestions.push(timeSlot);
            if (suggestions.length >= 5) break;
          }
        }
      }

      return suggestions;
    } catch (error) {
      console.error("Error suggesting smart times:", error);
      return this.getFallbackSuggestions();
    }
  }

  static async calculateAverageResponseTime(userId) {
    try {
      const invitations = await InterviewInvitation.findAll({
        where: {
          [Op.or]: [{ client_id: userId }, { freelancer_id: userId }],
          responded_at: { [Op.not]: null },
        },
      });

      if (invitations.length === 0) return 24;

      const totalHours = invitations.reduce((sum, inv) => {
        const diff = inv.responded_at.difference(inv.createdAt).inHours;
        return sum + diff;
      }, 0);

      return Math.round(totalHours / invitations.length);
    } catch (error) {
      return 24;
    }
  }

  static async getPreferredDuration(userId) {
    try {
      const user = await User.findByPk(userId);
      return 30;
    } catch (error) {
      return 30;
    }
  }

  static getFallbackSuggestions() {
    const suggestions = [];
    const now = new Date();

    for (let i = 2; i <= 7; i++) {
      const date = new Date(now);
      date.setDate(now.getDate() + i);

      const morningSlot = new Date(date);
      morningSlot.setHours(10, 0, 0, 0);
      suggestions.push(morningSlot.toISOString());

      if (suggestions.length < 5) {
        const afternoonSlot = new Date(date);
        afternoonSlot.setHours(14, 0, 0, 0);
        suggestions.push(afternoonSlot.toISOString());
      }

      if (suggestions.length >= 5) break;
    }

    return suggestions;
  }

  static async optimizeForTimeZone(userId, suggestedTime) {
    try {
      const user = await User.findByPk(userId);
      const userTimeZone = user.timezone || "UTC";

      const userTime = new Date(suggestedTime);

      const hour = userTime.getHours();
      if (hour < 9 || hour > 18) {
        const adjustedTime = new Date(userTime);
        if (hour < 9) adjustedTime.setHours(9, 0, 0, 0);
        if (hour > 18) adjustedTime.setHours(17, 0, 0, 0);
        return adjustedTime;
      }

      return suggestedTime;
    } catch (error) {
      return suggestedTime;
    }
  }
}

export default SmartSchedulingService;

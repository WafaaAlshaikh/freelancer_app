// backend/src/services/calendarService.js
import { google } from "googleapis";
import ical from "ical-generator";
import fs from "fs";
import path from "path";

class CalendarService {
  static async addToGoogleCalendar(accessToken, invitation, project) {
    try {
      const auth = new google.auth.OAuth2();
      auth.setCredentials({ access_token: accessToken });

      const calendar = google.calendar({ version: "v3", auth });

      const event = {
        summary: `Interview: ${project.title}`,
        description: `
          ${invitation.message || "Interview discussion"}
          
          Participants:
          - Client: ${invitation.client?.name}
          - Freelancer: ${invitation.freelancer?.name}
          
          ${invitation.meeting_notes ? `Notes: ${invitation.meeting_notes}` : ""}
        `,
        start: {
          dateTime: invitation.selected_time,
          timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        },
        end: {
          dateTime: new Date(
            new Date(invitation.selected_time).getTime() +
              (invitation.duration_minutes || 30) * 60000,
          ),
          timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        },
        conferenceData: {
          createRequest: {
            requestId: invitation.id.toString(),
            conferenceSolutionKey: { type: "hangoutsMeet" },
          },
        },
        attendees: [
          { email: invitation.client.email, responseStatus: "needsAction" },
          { email: invitation.freelancer.email, responseStatus: "needsAction" },
        ],
        reminders: {
          useDefault: false,
          overrides: [
            { method: "email", minutes: 24 * 60 },
            { method: "popup", minutes: 60 },
            { method: "popup", minutes: 10 },
          ],
        },
      };

      const response = await calendar.events.insert({
        calendarId: "primary",
        resource: event,
        conferenceDataVersion: 1,
        sendUpdates: "all",
      });

      return response.data;
    } catch (error) {
      console.error("Error adding to Google Calendar:", error);
      return null;
    }
  }

  static generateICSFile(invitation, project) {
    const cal = ical({ name: "Interview Schedule" });

    cal.createEvent({
      start: new Date(invitation.selected_time),
      end: new Date(
        new Date(invitation.selected_time).getTime() +
          (invitation.duration_minutes || 30) * 60000,
      ),
      summary: `Interview: ${project.title}`,
      description: invitation.message || "Interview discussion",
      location: invitation.meeting_link,
      url: invitation.meeting_link,
      organizer: {
        name: "Freelance Platform",
        email: process.env.SMTP_FROM,
      },
      attendees: [
        { name: invitation.client.name, email: invitation.client.email },
        {
          name: invitation.freelancer.name,
          email: invitation.freelancer.email,
        },
      ],
    });

    const filePath = path.join(
      __dirname,
      `../temp/interview_${invitation.id}.ics`,
    );
    fs.writeFileSync(filePath, cal.toString());
    return filePath;
  }
}

export default CalendarService;

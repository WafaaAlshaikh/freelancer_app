// controllers/notificationController.js
import NotificationService from "../services/notificationService.js";

export const getNotifications = async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    const result = await NotificationService.getUserNotifications(
      req.user.id,
      parseInt(limit),
      parseInt(offset)
    );
    
    res.json(result);
  } catch (error) {
    console.error('Error in getNotifications:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const success = await NotificationService.markAsRead(id, req.user.id);
    
    if (success) {
      res.json({ message: 'Notification marked as read' });
    } else {
      res.status(404).json({ message: 'Notification not found' });
    }
  } catch (error) {
    console.error('Error in markAsRead:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};


export const markAllAsRead = async (req, res) => {
  try {
    await NotificationService.markAllAsRead(req.user.id);
    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Error in markAllAsRead:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const success = await NotificationService.deleteNotification(id, req.user.id);
    
    if (success) {
      res.json({ message: 'Notification deleted' });
    } else {
      res.status(404).json({ message: 'Notification not found' });
    }
  } catch (error) {
    console.error('Error in deleteNotification:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getUnreadCount = async (req, res) => {
  try {
    const result = await NotificationService.getUserNotifications(req.user.id, 1, 0);
    res.json({ unreadCount: result.unreadCount });
  } catch (error) {
    console.error('Error in getUnreadCount:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
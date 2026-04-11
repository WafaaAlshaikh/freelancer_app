// lib/services/websocket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/token_storage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class WebSocketService {
  static IO.Socket? _socket;
  static final List<Function> _listeners = [];
  static bool _isConnected = false;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  static Future<void> init() async {
    try {
      final token = await TokenStorage.getToken();
      final userId = await TokenStorage.getUserId();

      if (userId == null) {
        print('⚠️ WebSocket: No user ID found, skipping initialization');
        return;
      }

      final options = IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(10000)
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .setAuth({'userId': userId.toString(), 'token': token})
          .build();

      final serverUrl = 'http://localhost:5001';
      print('🔌 WebSocket connecting to: $serverUrl');

      _socket = IO.io(serverUrl, options);

      _socket!.onConnect((_) {
        print('✅ WebSocket connected successfully');
        _isConnected = true;
        _reconnectAttempts = 0;

        _socket!.emit('user_connected', {
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });

      _socket!.onConnectError((error) {
        print('❌ WebSocket connection error: $error');
        _isConnected = false;

        if (_reconnectAttempts >= _maxReconnectAttempts) {
          Fluttertoast.showToast(
            msg:
                'Unable to connect to notification service. Please refresh the app.',
            backgroundColor: Colors.orange,
            timeInSecForIosWeb: 3,
          );
        }
      });

      _socket!.onDisconnect((reason) {
        print('🔌 WebSocket disconnected: $reason');
        _isConnected = false;

        if (reason != 'io client disconnect') {
          Future.delayed(const Duration(seconds: 3), () {
            if (_socket != null && !_isConnected) {
              print('🔄 Attempting to reconnect...');
              _socket!.connect();
            }
          });
        }
      });

      _socket!.onReconnectAttempt((attempt) {
        _reconnectAttempts = attempt;
        print('🔄 WebSocket reconnect attempt $attempt/$_maxReconnectAttempts');
      });

      _socket!.onReconnect((attempt) {
        print('✅ WebSocket reconnected after $attempt attempts');
        _isConnected = true;
      });

      _socket!.on('interview_reminder', (data) {
        print('📢 Received interview_reminder: $data');
        _showNotification(
          title: '⏰ Interview Reminder',
          body: data['hoursBefore'] == 24
              ? 'Your interview is tomorrow!'
              : 'Your interview is in ${data['hoursBefore']} hours!',
          data: data,
        );
      });

      _socket!.on('interview_urgent', (data) {
        print('🚨 Received interview_urgent: $data');
        _showUrgentNotification(data);
      });

      _socket!.on('interview_accepted', (data) {
        print('✅ Received interview_accepted: $data');
        _showNotification(
          title: '✅ Interview Accepted',
          body: 'Your interview has been accepted!',
          data: data,
        );
      });

      _socket!.on('new_interview', (data) {
        print('🎯 Received new_interview: $data');
        _showNotification(
          title: '🎯 New Interview Invitation',
          body: 'You have received a new interview invitation',
          data: data,
        );
      });

      _socket!.on('preparation_checklist', (data) {
        print('📋 Received preparation_checklist: $data');
        _showPreparationChecklist(data);
      });

      _socket!.on('connected', (data) {
        print('🔌 Server acknowledged connection: $data');
      });

      _socket!.on('error', (error) {
        print('❌ WebSocket error event: $error');
      });

      _socket!.connect();
    } catch (e) {
      print('❌ Error initializing WebSocket: $e');
      _isConnected = false;
    }
  }

  static void _showNotification({
    required String title,
    required String body,
    required dynamic data,
  }) {
    Fluttertoast.showToast(
      msg: '$title\n$body',
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.purple,
      textColor: Colors.white,
      gravity: ToastGravity.TOP,
    );
  }

  static void _showUrgentNotification(dynamic data) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('URGENT: Interview Starting Soon!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your interview for "${data['projectTitle'] ?? 'project'}" starts in 1 hour!',
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _launchMeetingLink(data['meetingLink']);
                },
                icon: const Icon(Icons.video_call),
                label: const Text('Join Now'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Remind me later'),
            ),
          ],
        ),
      );
    } else {
      Fluttertoast.showToast(
        msg: 'URGENT: Interview in 1 hour! Join now!',
        timeInSecForIosWeb: 10,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );
    }
  }

  static void _showPreparationChecklist(dynamic data) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final checklist = data['checklist'] as List?;
      if (checklist != null && checklist.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.checklist, color: Colors.blue),
                SizedBox(width: 8),
                Text('Interview Preparation Checklist'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get ready for your interview with "${data['projectTitle'] ?? 'project'}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...checklist.map(
                    (section) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...(section['items'] as List).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    }
  }

  static Future<void> _launchMeetingLink(String? link) async {
    if (link == null || link.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Meeting link not available',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      final Uri url = Uri.parse(link);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(
          msg: 'Could not launch meeting link',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print('Error launching meeting link: $e');
      Fluttertoast.showToast(
        msg: 'Error opening meeting link',
        backgroundColor: Colors.red,
      );
    }
  }

  static void addListener(Function callback) {
    _listeners.add(callback);
  }

  static void removeListener(Function callback) {
    _listeners.remove(callback);
  }

  static void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
      print('📤 Emitted $event: $data');
    } else {
      print('⚠️ WebSocket not connected, cannot emit $event');
    }
  }

  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
  }

  static void reconnect() {
    if (_socket != null && !_isConnected) {
      print('🔄 Manual reconnect requested');
      _socket!.connect();
    }
  }

  static bool get isConnected => _isConnected;
}

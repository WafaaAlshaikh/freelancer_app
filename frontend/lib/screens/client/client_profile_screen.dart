// lib/screens/client/client_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  Map<String, dynamic> _profile = {};
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _bioController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _avatarUrl;

  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _primaryLight = Color(0xFFEEF2FF);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _gray = Color(0xFF6B7280);
  static const Color _lightGray = Color(0xFFF9FAFB);
  static const Color _dark = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getClientProfile();
      setState(() {
        _profile = response;
        _nameController.text = response['name'] ?? '';
        _emailController.text = response['email'] ?? '';
        _phoneController.text = response['phone'] ?? '';
        _companyController.text = response['company'] ?? '';
        _bioController.text = response['bio'] ?? '';
        _avatarUrl = response['avatar'];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Error loading profile');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      Map<String, dynamic> data = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'company': _companyController.text,
        'bio': _bioController.text,
      };
      
      final response = await ApiService.updateProfile(data);
      
      if (response['message'] != null) {
        Fluttertoast.showToast(msg: '✅ Profile updated successfully');
        setState(() => _isEditing = false);
        await _loadProfile();
      } else {
        Fluttertoast.showToast(msg: 'Error updating profile');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        await _uploadAvatar();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _uploadAvatar() async {
    if (_selectedImage == null) return;
    
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final fileName = _selectedImage!.path.split('/').last;
      
      final response = await ApiService.uploadAvatar(bytes, fileName);
      
      if (response['avatar'] != null) {
        Fluttertoast.showToast(msg: '✅ Avatar updated successfully');
        await _loadProfile();
        setState(() {
          _selectedImage = null;
        });
      } else {
        Fluttertoast.showToast(msg: 'Error uploading avatar');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Widget _buildAvatarImage() {
    if (_selectedImage != null) {
      if (kIsWeb) {
        return Image.network(
          _selectedImage!.path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
        );
      } else {
        return Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
        );
      }
    }
    
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      final imageUrl = _avatarUrl!.startsWith('http')
          ? _avatarUrl!
          : 'http://localhost:5000$_avatarUrl';
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildAvatarPlaceholder(),
        errorWidget: (_, __, ___) => _buildAvatarPlaceholder(),
      );
    }
    
    return _buildAvatarPlaceholder();
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: _primary,
      child: Center(
        child: Text(
          _profile['name']?[0].toUpperCase() ?? 'C',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  BoxDecoration _modernCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primary, _primaryDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildAvatarImage(),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            label: 'Full Name',
                            controller: _nameController,
                            icon: Icons.person_outline,
                            enabled: _isEditing,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            label: 'Email',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            enabled: false,
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            label: 'Company',
                            controller: _companyController,
                            icon: Icons.business_outlined,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            label: 'Bio',
                            controller: _bioController,
                            icon: Icons.description_outlined,
                            enabled: _isEditing,
                            maxLines: 3,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          if (_isEditing)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() => _isEditing = false);
                                      _loadProfile();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _gray,
                                      side: BorderSide(color: _gray.withOpacity(0.3)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: 32),
                          
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: _modernCard(),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.bar_chart, size: 20, color: Color(0xFF6366F1)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Account Stats',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        label: 'Projects',
                                        value: '${_profile['totalProjects'] ?? 0}',
                                        icon: Icons.folder_open,
                                        color: _primary,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        label: 'Contracts',
                                        value: '${_profile['totalContracts'] ?? 0}',
                                        icon: Icons.description,
                                        color: _success,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        label: 'Spent',
                                        value: '\$${_profile['totalSpent'] ?? 0}',
                                        icon: Icons.payments,
                                        color: _warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 32),
                            child: OutlinedButton.icon(
                              onPressed: () => _showLogoutDialog(),
                              icon: const Icon(Icons.logout, size: 20),
                              label: const Text(
                                'Logout',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _danger,
                                side: BorderSide(color: _danger.withOpacity(0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: _modernCard(),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _dark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: _gray,
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await ApiService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}
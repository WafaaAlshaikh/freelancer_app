import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/profile_api_service.dart';
import '../../services/api_service.dart';

class EditClientProfileScreen extends StatefulWidget {
  const EditClientProfileScreen({super.key});

  @override
  State<EditClientProfileScreen> createState() =>
      _EditClientProfileScreenState();
}

class _EditClientProfileScreenState extends State<EditClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _user = {};

  final _companyNameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _bioController = TextEditingController();
  final _companyWebsiteController = TextEditingController();
  final _industryController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companySizeController = TextEditingController();
  final _foundedYearController = TextEditingController();

  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _secondary = Color(0xFF10B981);
  static const Color _accent = Color(0xFFF59E0B);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dark = Color(0xFF1F2937);
  static const Color _gray = Color(0xFF6B7280);
  static const Color _light = Color(0xFFF9FAFB);
  static const Color _white = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _taglineController.dispose();
    _bioController.dispose();
    _companyWebsiteController.dispose();
    _industryController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _companySizeController.dispose();
    _foundedYearController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _loading = true);

      final profileData = await ProfileApiService.getMyClientProfile();
      final userData = await ApiService.getProfile();

      setState(() {
        _profile = profileData['profile'] ?? {};
        _user = profileData['user'] ?? userData;

        _companyNameController.text = _profile['company_name'] ?? '';
        _taglineController.text = _profile['tagline'] ?? _user['tagline'] ?? '';
        _bioController.text = _profile['bio'] ?? _user['bio'] ?? '';
        _companyWebsiteController.text = _profile['company_website'] ?? '';
        _industryController.text = _profile['industry'] ?? '';
        _locationController.text =
            _user['location'] ?? _profile['location'] ?? '';
        _phoneController.text = _user['phone'] ?? _profile['phone'] ?? '';
        _companySizeController.text = _profile['company_size'] ?? '';
        _foundedYearController.text =
            _profile['founded_year']?.toString() ?? '';
        _loading = false;
      });
    } catch (error) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $error'),
          backgroundColor: _danger,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final profileData = {
        'company_name': _companyNameController.text.trim(),
        'tagline': _taglineController.text.trim(),
        'bio': _bioController.text.trim(),
        'company_website': _companyWebsiteController.text.trim(),
        'industry': _industryController.text.trim(),
        'location': _locationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'company_size': _companySizeController.text.trim(),
        'founded_year': _foundedYearController.text.trim().isNotEmpty
            ? int.tryParse(_foundedYearController.text)
            : null,
      };

      await ProfileApiService.updateClientProfile(profileData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: _success,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $error'),
          backgroundColor: _danger,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(bool isCover) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isCover ? 'Cover' : 'Profile'} image selected'),
          backgroundColor: _success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _light,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: _dark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveProfile,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_primary),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard('Profile Images', Icons.photo_camera, [
                      _buildImageUploadSection(),
                    ]),
                    const SizedBox(height: 16),

                    _buildSectionCard('Company Information', Icons.business, [
                      _buildTextField(
                        'Company Name',
                        _companyNameController,
                        'Enter your company name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Company name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Tagline',
                        _taglineController,
                        'Brief description of your company',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Company Description',
                        _bioController,
                        'Describe your company and what you do',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Company Website',
                        _companyWebsiteController,
                        'https://yourcompany.com',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Industry',
                        _industryController,
                        'e.g., Technology, Healthcare, Finance',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Company Size',
                              _companySizeController,
                              'Select company size',
                              isDropdown: true,
                              dropdownItems: [
                                '1',
                                '2-10',
                                '11-50',
                                '51-200',
                                '201-1000',
                                '1000+',
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              'Founded Year',
                              _foundedYearController,
                              'e.g., 2020',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 16),

                    _buildSectionCard(
                      'Contact Information',
                      Icons.contact_phone,
                      [
                        _buildTextField(
                          'Location',
                          _locationController,
                          'City, Country',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Phone',
                          _phoneController,
                          '+1 (555) 123-4567',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: _white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(_white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_primary, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: _white, width: 3),
                  ),
                  child: ClipOval(
                    child:
                        _user['avatar'] != null &&
                            _user['avatar'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ProfileApiService.fullImageUrl(
                              _user['avatar'],
                            ),
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(Icons.person, size: 32, color: _white),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: _white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 12,
                        color: _white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cover Image',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _gray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      gradient:
                          _user['cover_image'] != null &&
                              _user['cover_image'].toString().isNotEmpty
                          ? null
                          : LinearGradient(
                              colors: [
                                _primary.withOpacity(0.1),
                                _primaryDark.withOpacity(0.1),
                              ],
                            ),
                    ),
                    child:
                        _user['cover_image'] != null &&
                            _user['cover_image'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: ProfileApiService.fullImageUrl(
                                _user['cover_image'],
                              ),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 32, color: _gray),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Cover Image',
                                  style: TextStyle(fontSize: 12, color: _gray),
                                ),
                              ],
                            ),
                          ),
                  ),
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit, size: 14, color: _white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hintText, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    bool isDropdown = false,
    List<String>? dropdownItems,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _dark,
          ),
        ),
        const SizedBox(height: 8),
        if (isDropdown)
          DropdownButtonFormField<String>(
            value: controller.text.isNotEmpty ? controller.text : null,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 20, color: _gray)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 2),
              ),
              filled: true,
              fillColor: _light,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: dropdownItems?.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              controller.text = newValue ?? '';
            },
          )
        else
          TextFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 20, color: _gray)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 2),
              ),
              filled: true,
              fillColor: _light,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
      ],
    );
  }
}

// screens/freelancer/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/freelancer_model.dart';
import '../../services/api_service.dart';
import '../../widgets/skill_chip.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class AppColors {
  static const sidebarBg = Color(0xFF2D2B55);
  static const sidebarText = Color(0xFFC8C6E8);
  static const sidebarActive = Color(0xFF5B58E2);
  static const accent = Color(0xFF6C63FF);
  static const accentLight = Color(0xFFA78BFA);
  static const green = Color(0xFF14A800);
  static const pageBg = Color(0xFFF5F6F8);
  static const cardBg = Colors.white;
}

class EditProfileScreen extends StatefulWidget {
  final FreelancerProfile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController titleController;
  late TextEditingController bioController;
  late TextEditingController locationController;
  late TextEditingController experienceController;
  late TextEditingController hourlyRateController;

  late TextEditingController websiteController;
  late TextEditingController githubController;
  late TextEditingController linkedinController;
  late TextEditingController behanceController;

  List<String> skills = [];
  List<String> languages = [];
  List<Map<String, dynamic>> education = [];
  List<Map<String, dynamic>> certifications = [];

  bool loading = false;
  bool isUploadingCV = false;
  bool isUploadingAvatar = false;

  String? cvUrl;
  String? avatarUrl;

  bool showAIAnalysis = false;
  Map<String, dynamic>? aiAnalysis;

  LatLng? selectedLocation;

  final TextEditingController skillController = TextEditingController();
  final TextEditingController languageController = TextEditingController();

  final TextEditingController degreeController = TextEditingController();
  final TextEditingController institutionController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  final TextEditingController certNameController = TextEditingController();
  final TextEditingController certIssuerController = TextEditingController();
  final TextEditingController certYearController = TextEditingController();

  static const String _googleMapsApiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  @override
  void initState() {
    super.initState();
    initializeControllers();
  }

  @override
  void dispose() {
    nameController.dispose();
    titleController.dispose();
    bioController.dispose();
    locationController.dispose();
    experienceController.dispose();
    hourlyRateController.dispose();
    skillController.dispose();
    languageController.dispose();
    websiteController.dispose();
    githubController.dispose();
    linkedinController.dispose();
    behanceController.dispose();
    degreeController.dispose();
    institutionController.dispose();
    yearController.dispose();
    certNameController.dispose();
    certIssuerController.dispose();
    certYearController.dispose();
    super.dispose();
  }

  void initializeControllers() {
    nameController = TextEditingController(text: widget.profile.name ?? '');
    titleController = TextEditingController(text: widget.profile.title ?? '');
    bioController = TextEditingController(text: widget.profile.bio ?? '');
    locationController = TextEditingController(
      text: widget.profile.location ?? '',
    );
    experienceController = TextEditingController(
      text: widget.profile.experienceYears?.toString() ?? '',
    );
    hourlyRateController = TextEditingController(
      text: widget.profile.hourlyRate?.toString() ?? '',
    );

    websiteController = TextEditingController(
      text: widget.profile.website ?? '',
    );
    githubController = TextEditingController(text: widget.profile.github ?? '');
    linkedinController = TextEditingController(
      text: widget.profile.linkedin ?? '',
    );
    behanceController = TextEditingController(
      text: widget.profile.behance ?? '',
    );

    skills = List.from(widget.profile.skills ?? []);
    languages = List.from(widget.profile.languages ?? []);
    education = List.from(widget.profile.education ?? []);
    certifications = List.from(widget.profile.certifications ?? []);
    cvUrl = widget.profile.cvUrl;
    avatarUrl = widget.profile.avatar;

    if (widget.profile.locationCoordinates != null) {
      final coords = widget.profile.locationCoordinates!.split(',');
      if (coords.length == 2) {
        selectedLocation = LatLng(
          double.parse(coords[0]),
          double.parse(coords[1]),
        );
      }
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => isUploadingAvatar = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;
        final response = await ApiService.uploadAvatar(bytes, fileName);

        if (response['avatar'] != null) {
          setState(() {
            avatarUrl = response['avatar'];
          });
          Fluttertoast.showToast(msg: "Avatar uploaded successfully");
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Error uploading avatar");
      } finally {
        setState(() => isUploadingAvatar = false);
      }
    }
  }

  Future<void> pickCV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        isUploadingCV = true;
        showAIAnalysis = false;
        aiAnalysis = null;
      });

      try {
        final bytes = result.files.single.bytes;
        final fileName = result.files.single.name;

        if (bytes != null) {
          print('Uploading CV: $fileName');
          final response = await ApiService.uploadCV(bytes, fileName);
          print('Upload response: $response');

          if (response['profile'] != null) {
            final profileData = response['profile'];
            final analysis = profileData['aiAnalysis'];

            setState(() {
              cvUrl = profileData['cv_url'];

              if (analysis != null) {
                aiAnalysis = analysis;
                showAIAnalysis = true;

                if (analysis['title'] != null && analysis['title'].isNotEmpty) {
                  titleController.text = analysis['title'];
                }

                if (analysis['bio'] != null && analysis['bio'].isNotEmpty) {
                  bioController.text = analysis['bio'];
                }

                if (analysis['skills'] != null) {
                  final extractedSkills = analysis['skills'];
                  if (extractedSkills is List) {
                    skills = List<String>.from(extractedSkills);
                  } else if (extractedSkills is String) {
                    skills = extractedSkills
                        .split(',')
                        .map((s) => s.trim())
                        .toList();
                  }
                }

                if (analysis['languages'] != null &&
                    analysis['languages'].isNotEmpty) {
                  languages = List<String>.from(analysis['languages']);
                }

                if (analysis['education'] != null &&
                    analysis['education'].isNotEmpty) {
                  education = List<Map<String, dynamic>>.from(
                    analysis['education'],
                  );
                }

                if (analysis['certifications'] != null &&
                    analysis['certifications'].isNotEmpty) {
                  certifications = List<Map<String, dynamic>>.from(
                    analysis['certifications'].map((c) => {'name': c}),
                  );
                }

                if (analysis['social_links'] != null) {
                  final social = analysis['social_links'];
                  if (social['github'] != null && social['github'].isNotEmpty) {
                    githubController.text = social['github'];
                  }
                  if (social['linkedin'] != null &&
                      social['linkedin'].isNotEmpty) {
                    linkedinController.text = social['linkedin'];
                  }
                  if (social['website'] != null &&
                      social['website'].isNotEmpty) {
                    websiteController.text = social['website'];
                  }
                }
              }
            });

            Fluttertoast.showToast(
              msg: "✅ CV analyzed! ${skills.length} skills found",
              timeInSecForIosWeb: 3,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          } else {
            Fluttertoast.showToast(
              msg: response['message'] ?? "Error uploading CV",
            );
          }
        }
      } catch (e) {
        print('Error in pickCV: $e');
        Fluttertoast.showToast(msg: "Error uploading CV: $e");
      } finally {
        setState(() => isUploadingCV = false);
      }
    }
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Location services are disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permissions are denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg: "Location permissions are permanently denied",
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.locality ?? ''}, ${place.country ?? ''}';
        if (address.trim() == ',') {
          address = '${position.latitude}, ${position.longitude}';
        }

        setState(() {
          locationController.text = address;
          selectedLocation = LatLng(position.latitude, position.longitude);
        });

        await ApiService.updateLocation(
          lat: position.latitude,
          lng: position.longitude,
          address: address,
        );

        Fluttertoast.showToast(msg: "Location updated successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error getting location: $e");
    }
  }

  void addSkill() {
    if (skillController.text.isNotEmpty) {
      setState(() {
        skills.add(skillController.text.trim());
        skillController.clear();
      });
    }
  }

  void removeSkill(int index) {
    setState(() {
      skills.removeAt(index);
    });
  }

  void addLanguage() {
    if (languageController.text.isNotEmpty) {
      setState(() {
        languages.add(languageController.text.trim());
        languageController.clear();
      });
    }
  }

  void removeLanguage(int index) {
    setState(() {
      languages.removeAt(index);
    });
  }

  void addEducation() {
    if (degreeController.text.isNotEmpty &&
        institutionController.text.isNotEmpty) {
      setState(() {
        education.add({
          'degree': degreeController.text.trim(),
          'institution': institutionController.text.trim(),
          'year': yearController.text.trim(),
        });
        degreeController.clear();
        institutionController.clear();
        yearController.clear();
      });
    }
  }

  void removeEducation(int index) {
    setState(() {
      education.removeAt(index);
    });
  }

  void addCertification() {
    if (certNameController.text.isNotEmpty) {
      setState(() {
        certifications.add({
          'name': certNameController.text.trim(),
          'issuer': certIssuerController.text.trim(),
          'year': certYearController.text.trim(),
        });
        certNameController.clear();
        certIssuerController.clear();
        certYearController.clear();
      });
    }
  }

  void removeCertification(int index) {
    setState(() {
      certifications.removeAt(index);
    });
  }

  Future<void> saveProfile() async {
    setState(() => loading = true);

    try {
      final data = {
        'name': nameController.text.trim(),
        'title': titleController.text.trim(),
        'bio': bioController.text.trim(),
        'location': locationController.text.trim(),
        'location_coordinates': selectedLocation != null
            ? '${selectedLocation!.latitude},${selectedLocation!.longitude}'
            : null,
        'experience_years': int.tryParse(experienceController.text) ?? 0,
        'hourly_rate': double.tryParse(hourlyRateController.text),
        'skills': skills,
        'languages': languages,
        'education': education,
        'certifications': certifications,
        'social_links': {
          'website': websiteController.text.trim().isEmpty
              ? null
              : websiteController.text.trim(),
          'github': githubController.text.trim().isEmpty
              ? null
              : githubController.text.trim(),
          'linkedin': linkedinController.text.trim().isEmpty
              ? null
              : linkedinController.text.trim(),
          'behance': behanceController.text.trim().isEmpty
              ? null
              : behanceController.text.trim(),
        },
      };

      final response = await ApiService.updateProfile(data);

      if (response['message'] != null) {
        Fluttertoast.showToast(msg: response['message']);
        Navigator.pop(context, true);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving profile");
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _buildSocialField({
    required IconData icon,
    required String label,
    required String placeholder,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        prefixIcon: Icon(icon, color: AppColors.accent),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2B55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  Widget _buildAITag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2B55),
          ),
        ),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoCard(
              Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.accentLight.withOpacity(0.3),
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(
                                avatarUrl!.startsWith('http')
                                    ? avatarUrl!
                                    : 'http://localhost:5000$avatarUrl',
                              )
                            : null,
                        child: avatarUrl == null
                            ? Text(
                                nameController.text.isNotEmpty
                                    ? nameController.text[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: isUploadingAvatar
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: pickCV,
                      icon: isUploadingCV
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file, size: 18),
                      label: Text(cvUrl != null ? "Update CV" : "Upload CV"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (showAIAnalysis && aiAnalysis != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.green.withOpacity(0.1),
                      AppColors.accent.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: AppColors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "AI Analysis Complete!",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.green,
                                ),
                              ),
                              Text(
                                "Extracted from your CV",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (aiAnalysis!['title'] != null)
                          _buildAITag(Icons.work, aiAnalysis!['title']),
                        if (skills.isNotEmpty)
                          _buildAITag(Icons.code, "${skills.length} skills"),
                        if (languages.isNotEmpty)
                          _buildAITag(
                            Icons.language,
                            "${languages.length} languages",
                          ),
                        if (education.isNotEmpty)
                          _buildAITag(
                            Icons.school,
                            "${education.length} education",
                          ),
                        if (aiAnalysis!['confidence'] != null)
                          _buildAITag(
                            Icons.analytics,
                            "Confidence: ${(aiAnalysis!['confidence'] * 100).toInt()}%",
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            _buildInfoCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    "Basic Information",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: AppColors.accent,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Professional Title",
                      hintText: "e.g., Senior Flutter Developer",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.work,
                        color: AppColors.accent,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: bioController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: "Bio",
                      hintText: "Tell us about yourself...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),

            _buildInfoCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    "Location",
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: "Address",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: AppColors.accent,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.my_location,
                          color: AppColors.accent,
                        ),
                        onPressed: getCurrentLocation,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  if (selectedLocation != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?center=${selectedLocation!.latitude},${selectedLocation!.longitude}&zoom=15&size=600x160&maptype=roadmap&markers=color:red%7C${selectedLocation!.latitude},${selectedLocation!.longitude}&key=$_googleMapsApiKey',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: Text("Map preview unavailable"),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            _buildInfoCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Skills", icon: Icons.code_outlined),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: skillController,
                          decoration: InputDecoration(
                            hintText: "Add a skill",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.accent,
                                width: 2,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onSubmitted: (_) => addSkill(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: addSkill,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.asMap().entries.map((entry) {
                      return SkillChip(
                        label: entry.value,
                        onDeleted: () => removeSkill(entry.key),
                      );
                    }).toList(),
                  ),
                  if (skills.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          "No skills added yet",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            _buildInfoCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    "Languages",
                    icon: Icons.language_outlined,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: languageController,
                          decoration: InputDecoration(
                            hintText: "Add a language",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.accent,
                                width: 2,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onSubmitted: (_) => addLanguage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: addLanguage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: languages.asMap().entries.map((entry) {
                      return Chip(
                        label: Text(entry.value),
                        onDeleted: () => removeLanguage(entry.key),
                        deleteIconColor: Colors.red,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                  if (languages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          "No languages added yet",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            _buildInfoCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Education", icon: Icons.school_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: degreeController,
                          decoration: InputDecoration(
                            hintText: "Degree",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: institutionController,
                          decoration: InputDecoration(
                            hintText: "Institution",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: yearController,
                          decoration: InputDecoration(
                            hintText: "Year",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: addEducation,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...education.asMap().entries.map((entry) {
                    final edu = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 16,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  edu['degree'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  edu['institution'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (edu['year'] != null &&
                                    edu['year'].isNotEmpty)
                                  Text(
                                    edu['year'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => removeEducation(entry.key),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (education.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          "No education added yet",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            _buildInfoCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    "Certifications",
                    icon: Icons.verified_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: certNameController,
                          decoration: InputDecoration(
                            hintText: "Certification name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: certIssuerController,
                          decoration: InputDecoration(
                            hintText: "Issuer",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: certYearController,
                          decoration: InputDecoration(
                            hintText: "Year",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: addCertification,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...certifications.asMap().entries.map((entry) {
                    final cert = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cert['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (cert['issuer'] != null &&
                                    cert['issuer'].isNotEmpty)
                                  Text(
                                    cert['issuer'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                if (cert['year'] != null &&
                                    cert['year'].isNotEmpty)
                                  Text(
                                    cert['year'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => removeCertification(entry.key),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (certifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          "No certifications added yet",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            _buildInfoCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    "Social & Professional Links",
                    icon: Icons.link_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildSocialField(
                    icon: Icons.link,
                    label: "Portfolio Website",
                    placeholder: "https://yourportfolio.com",
                    controller: websiteController,
                  ),
                  const SizedBox(height: 14),
                  _buildSocialField(
                    icon: Icons.code,
                    label: "GitHub",
                    placeholder: "https://github.com/username",
                    controller: githubController,
                  ),
                  const SizedBox(height: 14),
                  _buildSocialField(
                    icon: Icons.work,
                    label: "LinkedIn",
                    placeholder: "https://linkedin.com/in/username",
                    controller: linkedinController,
                  ),
                  const SizedBox(height: 14),
                  _buildSocialField(
                    icon: Icons.brush,
                    label: "Behance / Dribbble",
                    placeholder: "https://behance.net/username",
                    controller: behanceController,
                  ),
                ],
              ),
            ),

            _buildInfoCard(
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: experienceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Years of Experience",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                        suffixText: "years",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: hourlyRateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Hourly Rate",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                        prefixText: "\$ ",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

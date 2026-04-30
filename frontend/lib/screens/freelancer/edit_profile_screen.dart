// screens/freelancer/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../models/freelancer_model.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/skill_chip.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final FreelancerProfile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController taglineController;
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
  late TextEditingController weeklyHoursController;
  String _availability = 'full_time';

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
    taglineController.dispose();
    titleController.dispose();
    bioController.dispose();
    locationController.dispose();
    experienceController.dispose();
    hourlyRateController.dispose();
    skillController.dispose();
    languageController.dispose();
    weeklyHoursController.dispose();
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
    taglineController = TextEditingController(
      text: widget.profile.tagline ?? '',
    );
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

    const allowedAvail = {
      'full_time',
      'part_time',
      'as_needed',
      'not_available',
    };
    final av = widget.profile.availability ?? 'full_time';
    _availability = allowedAvail.contains(av) ? av : 'full_time';
    weeklyHoursController = TextEditingController(
      text: (widget.profile.weeklyHours ?? 40).toString(),
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
    final t = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => isUploadingAvatar = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;
        final response = await ApiService.uploadAvatar(bytes, fileName);

        if (response['avatar'] != null) {
          setState(() => avatarUrl = response['avatar']);
          Fluttertoast.showToast(msg: t.avatarUploaded);
        }
      } catch (e) {
        Fluttertoast.showToast(msg: t.errorUploadingAvatar);
      } finally {
        setState(() => isUploadingAvatar = false);
      }
    }
  }

  Future<void> pickCV() async {
    final t = AppLocalizations.of(context)!;
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
          final response = await ApiService.uploadCV(bytes, fileName);

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
              msg: t.cvAnalyzed(skills.length),
              timeInSecForIosWeb: 3,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: AppColors.success,
              textColor: Colors.white,
            );
          } else {
            Fluttertoast.showToast(
              msg: response['message'] ?? t.errorUploadingCV,
            );
          }
        }
      } catch (e) {
        Fluttertoast.showToast(msg: '${t.errorUploadingCV}: $e');
      } finally {
        setState(() => isUploadingCV = false);
      }
    }
  }

  Future<void> getCurrentLocation() async {
    final t = AppLocalizations.of(context)!;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: t.locationServicesDisabled);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: t.locationPermissionsDenied);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(msg: t.locationPermissionsDeniedForever);
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
        Fluttertoast.showToast(msg: t.locationUpdated);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.errorGettingLocation}: $e');
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

  void removeSkill(int index) => setState(() => skills.removeAt(index));
  void addLanguage() {
    if (languageController.text.isNotEmpty) {
      setState(() {
        languages.add(languageController.text.trim());
        languageController.clear();
      });
    }
  }

  void removeLanguage(int index) => setState(() => languages.removeAt(index));

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

  void removeEducation(int index) => setState(() => education.removeAt(index));

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

  void removeCertification(int index) =>
      setState(() => certifications.removeAt(index));

  Future<void> saveProfile() async {
    final t = AppLocalizations.of(context)!;
    setState(() => loading = true);

    try {
      final data = {
        'name': nameController.text.trim(),
        'tagline': taglineController.text.trim(),
        'title': titleController.text.trim(),
        'bio': bioController.text.trim(),
        'location': locationController.text.trim(),
        'location_coordinates': selectedLocation != null
            ? '${selectedLocation!.latitude},${selectedLocation!.longitude}'
            : null,
        'experience_years': int.tryParse(experienceController.text) ?? 0,
        'hourly_rate': double.tryParse(hourlyRateController.text),
        'availability': _availability,
        'weekly_hours': int.tryParse(weeklyHoursController.text) ?? 40,
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
      Fluttertoast.showToast(msg: t.errorSavingProfile);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
      ),
      style: TextStyle(color: theme.colorScheme.onSurface),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Widget child) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  Widget _buildAITag(IconData icon, String label) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.editProfile,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
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
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.3,
                        ),
                        backgroundImage:
                            (avatarUrl != null && avatarUrl!.isNotEmpty)
                            ? NetworkImage(apiMediaUrl(avatarUrl))
                            : null,
                        child: avatarUrl == null
                            ? Text(
                                nameController.text.isNotEmpty
                                    ? nameController.text[0].toUpperCase()
                                    : "?",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
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
                              color: theme.colorScheme.primary,
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
                      label: Text(cvUrl != null ? t.updateCV : t.uploadCV),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
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
                      AppColors.secondary.withOpacity(0.1),
                      theme.colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.aiAnalysisComplete,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Text(
                                t.extractedFromCV,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
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
                          _buildAITag(
                            Icons.code,
                            "${skills.length} ${t.skillsCount}",
                          ),
                        if (languages.isNotEmpty)
                          _buildAITag(
                            Icons.language,
                            "${languages.length} ${t.languagesCount}",
                          ),
                        if (education.isNotEmpty)
                          _buildAITag(
                            Icons.school,
                            "${education.length} ${t.educationCount}",
                          ),
                        if (aiAnalysis!['confidence'] != null)
                          _buildAITag(
                            Icons.analytics,
                            "${t.confidence}: ${(aiAnalysis!['confidence'] * 100).toInt()}%",
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
                    t.basicInformation,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: t.fullName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: theme.colorScheme.primary,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: taglineController,
                    decoration: InputDecoration(
                      labelText: t.tagline,
                      hintText: t.taglineHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.short_text,
                        color: theme.colorScheme.primary,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: t.professionalTitle,
                      hintText: t.professionalTitleHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.work,
                        color: theme.colorScheme.primary,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: bioController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: t.bio,
                      hintText: t.bioHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),

            _buildInfoCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    t.location,
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: t.address,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.my_location,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: getCurrentLocation,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  if (selectedLocation != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?center=${selectedLocation!.latitude},${selectedLocation!.longitude}&zoom=15&size=600x160&maptype=roadmap&markers=color:red%7C${selectedLocation!.latitude},${selectedLocation!.longitude}&key=$_googleMapsApiKey',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.grey.shade100,
                              child: Center(
                                child: Text(t.mapPreviewUnavailable),
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
                  _buildSectionHeader(t.skills, icon: Icons.code_outlined),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: skillController,
                          decoration: InputDecoration(
                            hintText: t.addSkill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade50,
                          ),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          onSubmitted: (_) => addSkill(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
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
                          t.noSkillsAdded,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
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
                    t.languages,
                    icon: Icons.language_outlined,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: languageController,
                          decoration: InputDecoration(
                            hintText: t.addLanguage,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade50,
                          ),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          onSubmitted: (_) => addLanguage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
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
                        label: Text(
                          entry.value,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        onDeleted: () => removeLanguage(entry.key),
                        deleteIconColor: AppColors.danger,
                        backgroundColor: isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade100,
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
                          t.noLanguagesAdded,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
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
                  _buildSectionHeader(t.education, icon: Icons.school_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: degreeController,
                          decoration: InputDecoration(
                            hintText: t.degree,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade50,
                          ),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: institutionController,
                          decoration: InputDecoration(
                            hintText: t.institution,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade50,
                          ),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: yearController,
                          decoration: InputDecoration(
                            hintText: t.year,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade50,
                          ),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
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
                        color: isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.school,
                              size: 16,
                              color: theme.colorScheme.primary,
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
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (edu['year'] != null &&
                                    edu['year'].isNotEmpty)
                                  Text(
                                    edu['year'],
                                    style: theme.textTheme.bodySmall,
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
                          t.noEducationAdded,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
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
                    t.certifications,
                    icon: Icons.verified_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: certNameController,
                          decoration: InputDecoration(
                            hintText: t.certificationName,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade50,
                          ),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: certIssuerController,
                          decoration: InputDecoration(
                            hintText: t.issuer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade50,
                          ),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: certYearController,
                          decoration: InputDecoration(
                            hintText: t.year,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade50,
                          ),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
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
                        color: isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.secondary,
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
                                    style: theme.textTheme.bodySmall,
                                  ),
                                if (cert['year'] != null &&
                                    cert['year'].isNotEmpty)
                                  Text(
                                    cert['year'],
                                    style: theme.textTheme.bodySmall,
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
                          t.noCertificationsAdded,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
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
                  _buildSectionHeader(t.socialLinks, icon: Icons.link_outlined),
                  const SizedBox(height: 8),
                  _buildSocialField(
                    icon: Icons.link,
                    label: t.portfolioWebsite,
                    placeholder: "https://yourportfolio.com",
                    controller: websiteController,
                  ),
                  const SizedBox(height: 14),
                  _buildSocialField(
                    icon: Icons.code,
                    label: t.github,
                    placeholder: "https://github.com/username",
                    controller: githubController,
                  ),
                  const SizedBox(height: 14),
                  _buildSocialField(
                    icon: Icons.work,
                    label: t.linkedin,
                    placeholder: "https://linkedin.com/in/username",
                    controller: linkedinController,
                  ),
                  const SizedBox(height: 14),
                  _buildSocialField(
                    icon: Icons.brush,
                    label: t.behance,
                    placeholder: "https://behance.net/username",
                    controller: behanceController,
                  ),
                ],
              ),
            ),

            _buildInfoCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    t.availability,
                    icon: Icons.schedule_outlined,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _availability,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                    ),
                    dropdownColor: theme.cardColor,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    items: [
                      DropdownMenuItem(
                        value: 'full_time',
                        child: Text(t.fullTime),
                      ),
                      DropdownMenuItem(
                        value: 'part_time',
                        child: Text(t.partTime),
                      ),
                      DropdownMenuItem(
                        value: 'as_needed',
                        child: Text(t.asNeeded),
                      ),
                      DropdownMenuItem(
                        value: 'not_available',
                        child: Text(t.notAvailable),
                      ),
                    ],
                    onChanged: (v) => setState(() => _availability = v!),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: weeklyHoursController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t.weeklyHours,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
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
                        labelText: t.yearsOfExperience,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        suffixText: t.years,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade50,
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: hourlyRateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t.hourlyRate,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        prefixText: "\$ ",
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade50,
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
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
                  backgroundColor: theme.colorScheme.primary,
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
                    : Text(
                        t.saveChanges,
                        style: const TextStyle(
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

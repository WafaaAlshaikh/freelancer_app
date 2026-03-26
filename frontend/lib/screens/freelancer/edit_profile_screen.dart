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
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: saveProfile,
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Save"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
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
                            color: Colors.white,
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
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xff14A800),
                        shape: BoxShape.circle,
                      ),
                      child: isUploadingAvatar
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: pickCV,
                icon: isUploadingCV
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(cvUrl != null ? "Update CV" : "Upload CV"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            if (showAIAnalysis && aiAnalysis != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "AI Analysis Complete!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Extracted from your CV:",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
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

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Basic Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Professional Title",
                        hintText: "e.g., Senior Flutter Developer",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Bio",
                        hintText: "Tell us about yourself...",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: "Address",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: getCurrentLocation,
                        ),
                      ),
                    ),

                    if (selectedLocation != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://maps.googleapis.com/maps/api/staticmap?center=${selectedLocation!.latitude},${selectedLocation!.longitude}&zoom=15&size=600x150&maptype=roadmap&markers=color:red%7C${selectedLocation!.latitude},${selectedLocation!.longitude}&key=$_googleMapsApiKey',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
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
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Skills",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: skillController,
                            decoration: const InputDecoration(
                              hintText: "Add a skill",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => addSkill(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xff14A800),
                          ),
                          onPressed: addSkill,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

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
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "No skills added yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Languages",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: languageController,
                            decoration: const InputDecoration(
                              hintText: "Add a language",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => addLanguage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xff14A800),
                          ),
                          onPressed: addLanguage,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: languages.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(entry.value),
                          onDeleted: () => removeLanguage(entry.key),
                          deleteIconColor: Colors.red,
                        );
                      }).toList(),
                    ),

                    if (languages.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "No languages added yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Education",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: degreeController,
                            decoration: const InputDecoration(
                              hintText: "Degree",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: institutionController,
                            decoration: const InputDecoration(
                              hintText: "Institution",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: yearController,
                            decoration: const InputDecoration(
                              hintText: "Year",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xff14A800),
                          ),
                          onPressed: addEducation,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ...education.asMap().entries.map((entry) {
                      final edu = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    edu['degree'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
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
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "No education added yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Certifications",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: certNameController,
                            decoration: const InputDecoration(
                              hintText: "Certification name",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: certIssuerController,
                            decoration: const InputDecoration(
                              hintText: "Issuer",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: certYearController,
                            decoration: const InputDecoration(
                              hintText: "Year",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xff14A800),
                          ),
                          onPressed: addCertification,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ...certifications.asMap().entries.map((entry) {
                      final cert = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 8),
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
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  if (cert['year'] != null &&
                                      cert['year'].isNotEmpty)
                                    Text(
                                      cert['year'],
                                      style: TextStyle(
                                        fontSize: 10,
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
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "No certifications added yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Social & Professional Links",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildSocialField(
                      icon: Icons.link,
                      label: "Portfolio Website",
                      placeholder: "https://yourportfolio.com",
                      controller: websiteController,
                    ),
                    const SizedBox(height: 12),

                    _buildSocialField(
                      icon: Icons.code,
                      label: "GitHub",
                      placeholder: "https://github.com/username",
                      controller: githubController,
                    ),
                    const SizedBox(height: 12),

                    _buildSocialField(
                      icon: Icons.work,
                      label: "LinkedIn",
                      placeholder: "https://linkedin.com/in/username",
                      controller: linkedinController,
                    ),
                    const SizedBox(height: 12),

                    _buildSocialField(
                      icon: Icons.brush,
                      label: "Behance / Dribbble",
                      placeholder: "https://behance.net/username",
                      controller: behanceController,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: experienceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Years of Experience",
                          border: OutlineInputBorder(),
                          suffixText: "years",
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: hourlyRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Hourly Rate",
                          border: OutlineInputBorder(),
                          prefixText: "\$ ",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff14A800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAITag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

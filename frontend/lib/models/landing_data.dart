// lib/models/landing_data.dart
import 'dart:convert';

class LandingData {
  final HeroSection? hero;
  final Section? features;
  final Section? howItWorks;
  final VideoSection? video;
  final List<Testimonial> testimonials;
  final StatsData stats;
  final Section? cta;
  final FooterData? footer;

  LandingData({
    this.hero,
    this.features,
    this.howItWorks,
    this.video,
    required this.testimonials,
    required this.stats,
    this.cta,
    this.footer,
  });

  String? get videoUrl => video?.mediaUrl;

  factory LandingData.fromJson(Map<String, dynamic> json) {
    return LandingData(
      hero: json['sections']?['hero'] != null
          ? HeroSection.fromJson(json['sections']['hero'])
          : null,
      features: json['sections']?['features'] != null
          ? Section.fromJson(json['sections']['features'])
          : null,
      howItWorks: json['sections']?['how_it_works'] != null
          ? Section.fromJson(json['sections']['how_it_works'])
          : null,
      video: json['sections']?['video'] != null
          ? VideoSection.fromJson(json['sections']['video'])
          : null,
      testimonials:
          (json['testimonials'] as List?)
              ?.map((t) => Testimonial.fromJson(t))
              .toList() ??
          [],
      stats: StatsData.fromJson(json['stats'] ?? {}),
      cta: json['sections']?['cta'] != null
          ? Section.fromJson(json['sections']['cta'])
          : null,
    );
  }

  factory LandingData.empty() {
    return LandingData(
      testimonials: [],
      stats: StatsData(users: 0, projects: 0, contracts: 0, earnings: 0),
    );
  }
}

class HeroSection {
  final String? title;
  final String? subtitle;
  final String? mediaUrl;

  HeroSection({this.title, this.subtitle, this.mediaUrl});

  factory HeroSection.fromJson(Map<String, dynamic> json) {
    return HeroSection(
      title: json['title'],
      subtitle: json['subtitle'],
      mediaUrl: json['mediaUrl'],
    );
  }
}

class Section {
  final String? title;
  final String? subtitle;
  final dynamic content;
  final String? mediaUrl;
  final Map<String, dynamic>? settings;

  Section({
    this.title,
    this.subtitle,
    this.content,
    this.mediaUrl,
    this.settings,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      title: json['title'],
      subtitle: json['subtitle'],
      content: json['content'],
      mediaUrl: json['mediaUrl'],
      settings: json['settings'] is String
          ? jsonDecode(json['settings'])
          : json['settings'],
    );
  }
}

class VideoSection {
  final String? title;
  final String? subtitle;
  final String? mediaUrl;

  VideoSection({this.title, this.subtitle, this.mediaUrl});

  factory VideoSection.fromJson(Map<String, dynamic> json) {
    return VideoSection(
      title: json['title'],
      subtitle: json['subtitle'],
      mediaUrl: json['mediaUrl'],
    );
  }
}

class Testimonial {
  final int id;
  final String name;
  final String? role;
  final String? avatar;
  final String content;
  final int rating;
  final int? order;
  final bool? isActive;

  Testimonial({
    required this.id,
    required this.name,
    this.role,
    this.avatar,
    required this.content,
    required this.rating,
    this.order,
    this.isActive,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    return Testimonial(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      avatar: json['avatar'],
      content: json['content'],
      rating: json['rating'] ?? 5,
      order: json['order'],
      isActive: json['isActive'],
    );
  }
}

class StatsData {
  final int users;
  final int projects;
  final int contracts;
  final double earnings;
  final Map<String, dynamic>? staticStats;

  StatsData({
    required this.users,
    required this.projects,
    required this.contracts,
    required this.earnings,
    this.staticStats,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    return StatsData(
      users: json['users'] ?? 0,
      projects: json['projects'] ?? 0,
      contracts: json['contracts'] ?? 0,
      earnings: (json['earnings'] ?? 0).toDouble(),
      staticStats: json['staticStats'],
    );
  }
}

class FooterData {
  final Map<String, dynamic>? links;
  final Map<String, dynamic>? social;

  FooterData({this.links, this.social});
}

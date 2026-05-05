import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_service.dart';

class AdBanner extends StatefulWidget {
  final String placement;
  final double height;
  final EdgeInsets margin;
  final BorderRadius borderRadius;

  const AdBanner({
    super.key,
    required this.placement,
    this.height = 120,
    this.margin = const EdgeInsets.all(8),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  List<Map<String, dynamic>> _ads = [];
  bool _loading = true;
  int _currentIndex = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _loadAds();
    _startRotation();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAds() async {
    try {
      final ads = await AdService.getActiveAds(placement: widget.placement);
      setState(() {
        _ads = ads;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _startRotation() {
    _rotationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_ads.length > 1 && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _ads.length;
        });
      }
    });
  }

  Future<void> _onAdTap(Map<String, dynamic> ad) async {
    try {
      final url = await AdService.trackClick(ad['id']);
      if (url != null && mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Error tracking ad click: $e');
    }
  }

  Widget _buildFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.campaign,
          size: 40,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_ads.isEmpty) return const SizedBox.shrink();

    final ad = _ads[_currentIndex];
    final isVideo = ad['ad_type'] == 'video';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        key: ValueKey(ad['id']),
        onTap: () => _onAdTap(ad),
        child: Container(
          margin: widget.margin,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ad['image_url'] != null &&
                    ad['image_url'].toString().isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: ad['image_url'],
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => _buildFallback(),
                    placeholder: (context, url) =>
                        Container(color: Colors.grey.shade100),
                  )
                else
                  _buildFallback(),
                if (isVideo)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ad['title'] != null)
                              Text(
                                ad['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            if (ad['description'] != null)
                              Text(
                                ad['description'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ad['cta_text'] ?? 'Learn More',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Ad · ${_currentIndex + 1}/${_ads.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

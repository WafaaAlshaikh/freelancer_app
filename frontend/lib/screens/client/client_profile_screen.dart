import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/profile_api_service.dart';
import '../../services/api_service.dart';

class ClientProfileScreen extends StatefulWidget {
  final int? targetUserId;
  const ClientProfileScreen({super.key, this.targetUserId});
  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _isOwnProfile = false;
  late TabController _tabController;

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _card = Colors.white;
  static const Color _primary = Color(0xFF0A66C2);
  static const Color _green = Color(0xFF14A800);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMid = Color(0xFF4A5568);
  static const Color _textLight = Color(0xFF8FA3BF);
  static const Color _border = Color(0xFFE8EDF5);
  static const Color _gold = Color(0xFFFFB800);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ownIdStr = await _getOwnUserId();
    final uid = widget.targetUserId;
    _isOwnProfile = uid == null || uid.toString() == ownIdStr;

    final data = _isOwnProfile
        ? await ProfileApiService.getMyClientProfile()
        : await ProfileApiService.getClientPublicProfile(uid!);

    if (mounted)
      setState(() {
        _data = data;
        _loading = false;
      });
  }

  Future<String?> _getOwnUserId() async {
    try {
      return (await ApiService.getProfile())['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  String _img(String? p) => ProfileApiService.fullImageUrl(p);

  String _initials(String n) {
    final p = n.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : n.isNotEmpty
        ? n[0].toUpperCase()
        : '?';
  }

  String _memberSince(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Widget _avatar(String? url, String name, double size, {Color bg = _primary}) {
    final imgUrl = _img(url);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: imgUrl.isEmpty ? bg : null,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: imgUrl.isEmpty
            ? Center(
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: imgUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Center(
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      fontSize: size * 0.32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: _primary)),
      );

    final user = Map<String, dynamic>.from(_data['user'] ?? {});
    final profile = Map<String, dynamic>.from(_data['profile'] ?? {});
    final stats = Map<String, dynamic>.from(_data['stats'] ?? {});
    final projects = List<Map<String, dynamic>>.from(
      (_data['recent_projects'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );

    final name = user['name'] ?? 'Client';
    final companyName = profile['company_name'] ?? '';
    final displayTitle = companyName.isNotEmpty ? companyName : name;
    final industry = profile['industry'] ?? '';
    final bio =
        profile['bio'] ?? profile['company_description'] ?? user['bio'] ?? '';
    final location = user['location'] ?? profile['location'] ?? '';
    final memberSince = _memberSince(user['member_since']?.toString());
    final strength = (profile['profile_strength'] ?? 0) as num;
    final paymentVerified = profile['payment_verified'] ?? false;
    final preferredSkills = List<String>.from(
      profile['preferred_skills'] ?? [],
    );
    final hiringFor = List<String>.from(profile['hiring_for'] ?? []);
    final logo = profile['company_logo'];

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isOwnProfile)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditClientProfileScreen(),
                    ),
                  ).then((_) => _load()),
                )
              else
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: () {},
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  user['cover_image'] != null &&
                          user['cover_image'].toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _img(user['cover_image']),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0A3D6B),
                                Color(0xFF0A66C2),
                                Color(0xFF1DA1F2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                  Container(color: Colors.black.withOpacity(0.2)),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Transform.translate(
                                        offset: const Offset(0, -30),
                                        child: Stack(
                                          children: [
                                            logo != null &&
                                                    logo.toString().isNotEmpty
                                                ? Container(
                                                    width: 88,
                                                    height: 88,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 3,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                          blurRadius: 8,
                                                        ),
                                                      ],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      child: CachedNetworkImage(
                                                        imageUrl: _img(logo),
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                  )
                                                : _avatar(
                                                    user['avatar'],
                                                    name,
                                                    88,
                                                    bg: _primary,
                                                  ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      displayTitle,
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: _textDark,
                                                      ),
                                                    ),
                                                  ),
                                                  if (paymentVerified)
                                                    _badge(
                                                      'Payment Verified',
                                                      const Color(0xFF36B37E),
                                                      Icons.verified,
                                                    ),
                                                ],
                                              ),
                                              if (companyName.isNotEmpty &&
                                                  companyName != name)
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: _textLight,
                                                  ),
                                                ),
                                              if (industry.isNotEmpty)
                                                Text(
                                                  industry,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: _textMid,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  _clientStatsRow(stats),
                                  const SizedBox(height: 14),

                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 6,
                                    children: [
                                      if (location.isNotEmpty)
                                        _meta(
                                          Icons.location_on_outlined,
                                          location,
                                        ),
                                      if (memberSince.isNotEmpty)
                                        _meta(
                                          Icons.calendar_today_outlined,
                                          'Member since $memberSince',
                                        ),
                                      if (profile['company_size'] != null)
                                        _meta(
                                          Icons.people_outline,
                                          '${profile['company_size']} employees',
                                        ),
                                      if (profile['founded_year'] != null)
                                        _meta(
                                          Icons.business_outlined,
                                          'Founded ${profile['founded_year']}',
                                        ),
                                    ],
                                  ),

                                  if (bio.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    _ExpandableText(text: bio),
                                  ],

                                  if (hiringFor.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Hiring for',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _textMid,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: hiringFor
                                          .map((s) => _hiringChip(s))
                                          .toList(),
                                    ),
                                  ],

                                  if (preferredSkills.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Looking for skills',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _textMid,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: preferredSkills
                                          .take(8)
                                          .map((s) => _skillChip(s))
                                          .toList(),
                                    ),
                                  ],

                                  _clientSocialRow(profile, user),

                                  if (!_isOwnProfile) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _actionBtn(
                                            'View Projects',
                                            Icons.folder_open_outlined,
                                            _primary,
                                            Colors.white,
                                            () {},
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _actionBtn(
                                            'Message',
                                            Icons.chat_bubble_outline,
                                            Colors.transparent,
                                            _primary,
                                            () {},
                                            border: Border.all(
                                              color: _primary,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  if (_isOwnProfile) ...[
                                    const SizedBox(height: 16),
                                    _profileStrengthBar(strength.toInt()),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: _primary,
                            unselectedLabelColor: _textLight,
                            indicatorColor: _primary,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            tabs: const [
                              Tab(text: 'Projects'),
                              Tab(text: 'About'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          height: 600,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _projectsTab(projects),
                              _aboutTab(profile, stats),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientStatsRow(Map stats) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(
            '${stats['total_projects'] ?? 0}',
            'Projects',
            icon: Icons.folder_open,
          ),
          _divider(),
          _statItem(
            '${stats['completed_contracts'] ?? 0}',
            'Hired',
            icon: Icons.check_circle_outline,
          ),
          _divider(),
          _statItem(
            '\$${_formatMoney(stats['total_spent'])}',
            'Spent',
            icon: Icons.payments_outlined,
          ),
          _divider(),
          _statItem(
            '${stats['active_projects'] ?? 0}',
            'Active',
            icon: Icons.work_outline,
          ),
        ],
      ),
    );
  }

  String _formatMoney(dynamic v) {
    final n = (v ?? 0) as num;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  Widget _statItem(
    String value,
    String label, {
    IconData? icon,
    Color iconColor = _textMid,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) Icon(icon, size: 14, color: iconColor),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: _textDark,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 10, color: _textLight)),
    ],
  );

  Widget _divider() => Container(width: 1, height: 30, color: _border);

  Widget _meta(IconData icon, String text, {Color color = _textMid}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 12, color: color)),
    ],
  );

  Widget _badge(String t, Color c, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 3),
        Text(
          t,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
        ),
      ],
    ),
  );

  Widget _skillChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5FF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFBBDEFB)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: _primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _hiringChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFE082)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFFFF8F00),
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _clientSocialRow(Map profile, Map user) {
    final links = <MapEntry<String, String>>[];
    if ((profile['company_website'] ?? user['website'] ?? '')
        .toString()
        .isNotEmpty)
      links.add(
        MapEntry('website', profile['company_website'] ?? user['website']),
      );
    if ((profile['linkedin'] ?? user['linkedin'] ?? '').toString().isNotEmpty)
      links.add(MapEntry('linkedin', profile['linkedin'] ?? user['linkedin']));
    if ((profile['twitter'] ?? user['twitter'] ?? '').toString().isNotEmpty)
      links.add(MapEntry('twitter', profile['twitter'] ?? user['twitter']));
    if (links.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          const Text(
            'Links ',
            style: TextStyle(fontSize: 12, color: _textLight),
          ),
          const SizedBox(width: 8),
          ...links.map(
            (e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(
                    e.value.startsWith('http') ? e.value : 'https://${e.value}',
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icon(e.key), size: 13, color: _primary),
                      const SizedBox(width: 4),
                      Text(
                        _label(e.key),
                        style: const TextStyle(
                          fontSize: 11,
                          color: _primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(String k) =>
      {
        'linkedin': Icons.work,
        'twitter': Icons.chat,
        'website': Icons.public,
      }[k] ??
      Icons.link;
  String _label(String k) =>
      {'linkedin': 'LinkedIn', 'twitter': 'Twitter', 'website': 'Website'}[k] ??
      k;

  Widget _actionBtn(
    String label,
    IconData icon,
    Color bg,
    Color fg,
    VoidCallback onTap, {
    Border? border,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: border,
        boxShadow: bg != Colors.transparent
            ? [
                BoxShadow(
                  color: _primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _profileStrengthBar(int s) {
    final color = s < 40
        ? Colors.red
        : s < 70
        ? Colors.orange
        : _green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile Strength',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              '$s%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: s / 100,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        if (s < 100)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Add ${_tip(s)}',
              style: const TextStyle(fontSize: 11, color: _textLight),
            ),
          ),
      ],
    );
  }

  String _tip(int s) {
    if (s < 30) return 'company name, bio and industry';
    if (s < 60) return 'company logo and location';
    return 'preferred skills and social links';
  }

  Widget _projectsTab(List<Map<String, dynamic>> projects) {
    if (projects.isEmpty)
      return _emptyState(
        Icons.folder_open,
        'No projects yet',
        'Projects posted will appear here',
      );
    return Column(
      children: projects
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _projectCard(p),
            ),
          )
          .toList(),
    );
  }

  Widget _projectCard(Map p) {
    final status = p['status'] ?? '';
    Color statusColor = status == 'open'
        ? _green
        : status == 'in_progress'
        ? const Color(0xFFFF8F00)
        : _textLight;
    String statusText =
        {
          'open': 'Open',
          'in_progress': 'In Progress',
          'completed': 'Completed',
          'cancelled': 'Cancelled',
        }[status] ??
        status;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work_outline, size: 20, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['title'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (p['category'] != null)
                      Text(
                        p['category'],
                        style: const TextStyle(fontSize: 11, color: _textLight),
                      ),
                    if (p['category'] != null && p['budget'] != null)
                      const Text(' · ', style: TextStyle(color: _textLight)),
                    if (p['budget'] != null)
                      Text(
                        '\$${p['budget']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutTab(Map profile, Map stats) {
    return Column(
      children: [
        if (profile['company_description'] != null &&
            profile['company_description'].toString().isNotEmpty)
          _infoCard('About the Company', Icons.business, [
            _ExpandableText(text: profile['company_description']),
          ]),
        const SizedBox(height: 12),
        _infoCard('Hiring Details', Icons.work, [
          if (profile['preferred_contract_type'] != null)
            _infoRow(
              Icons.handshake_outlined,
              'Prefers',
              _formatContractType(profile['preferred_contract_type']),
            ),
          if (profile['budget_range_min'] != null ||
              profile['budget_range_max'] != null)
            _infoRow(
              Icons.attach_money,
              'Budget Range',
              '\$${profile['budget_range_min'] ?? 0} - \$${profile['budget_range_max'] ?? '∞'}',
            ),
          if (profile['timezone'] != null)
            _infoRow(Icons.schedule, 'Timezone', profile['timezone']),
          _infoRow(
            Icons.check_circle_outline,
            'Total Hired',
            '${stats['completed_contracts'] ?? 0} freelancers',
          ),
          _infoRow(Icons.repeat, 'Hire Rate', '${profile['hire_rate'] ?? 0}%'),
        ]),
      ],
    );
  }

  Widget _infoCard(String title, IconData icon, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: _primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 15, color: _textLight),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: _textLight),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ),
      ],
    ),
  );

  String _formatContractType(String t) =>
      {
        'hourly': 'Hourly contracts',
        'fixed': 'Fixed-price projects',
        'both': 'Both hourly & fixed',
      }[t] ??
      t;

  Widget _emptyState(IconData icon, String t, String s) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: _textLight),
          ),
          const SizedBox(height: 12),
          Text(
            t,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _textLight),
          ),
        ],
      ),
    ),
  );
}

class EditClientProfileScreen extends StatefulWidget {
  const EditClientProfileScreen({super.key});
  @override
  State<EditClientProfileScreen> createState() =>
      _EditClientProfileScreenState();
}

class _EditClientProfileScreenState extends State<EditClientProfileScreen> {
  static const Color _primary = Color(0xFF0A66C2);
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMid = Color(0xFF4A5568);
  static const Color _textLight = Color(0xFF8FA3BF);
  static const Color _border = Color(0xFFE8EDF5);

  Map<String, dynamic> _data = {};
  bool _loading = true, _saving = false;

  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _companyDescCtrl = TextEditingController();
  final _companyWebCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController();
  final _foundedCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();

  String _companySize = '2-10';
  String _contractType = 'both';
  List<String> _preferredSkills = [];
  List<String> _hiringFor = [];
  Uint8List? _avatarBytes;
  String? _avatarName;
  Uint8List? _coverBytes;
  String? _coverName;
  Uint8List? _logoBytes;
  String? _logoName;

  final _skillInput = TextEditingController();
  final _hiringInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _taglineCtrl,
      _bioCtrl,
      _locationCtrl,
      _countryCtrl,
      _phoneCtrl,
      _companyCtrl,
      _industryCtrl,
      _companyDescCtrl,
      _companyWebCtrl,
      _linkedinCtrl,
      _twitterCtrl,
      _timezoneCtrl,
      _foundedCtrl,
      _budgetMinCtrl,
      _budgetMaxCtrl,
      _skillInput,
      _hiringInput,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ProfileApiService.getMyClientProfile();
    final u = Map<String, dynamic>.from(data['user'] ?? {});
    final p = Map<String, dynamic>.from(data['profile'] ?? {});

    _nameCtrl.text = u['name'] ?? '';
    _taglineCtrl.text = p['tagline'] ?? u['tagline'] ?? '';
    _bioCtrl.text = p['bio'] ?? u['bio'] ?? '';
    _locationCtrl.text = u['location'] ?? p['location'] ?? '';
    _countryCtrl.text = u['country'] ?? p['country'] ?? '';
    _phoneCtrl.text = u['phone'] ?? p['phone'] ?? '';
    _companyCtrl.text = p['company_name'] ?? '';
    _industryCtrl.text = p['industry'] ?? '';
    _companyDescCtrl.text = p['company_description'] ?? '';
    _companyWebCtrl.text = p['company_website'] ?? u['website'] ?? '';
    _linkedinCtrl.text = p['linkedin'] ?? u['linkedin'] ?? '';
    _twitterCtrl.text = p['twitter'] ?? u['twitter'] ?? '';
    _timezoneCtrl.text = p['timezone'] ?? '';
    _foundedCtrl.text = (p['founded_year'] ?? '').toString();
    _budgetMinCtrl.text = (p['budget_range_min'] ?? '').toString();
    _budgetMaxCtrl.text = (p['budget_range_max'] ?? '').toString();
    _companySize = p['company_size'] ?? '2-10';
    _contractType = p['preferred_contract_type'] ?? 'both';
    _preferredSkills = List<String>.from(p['preferred_skills'] ?? []);
    _hiringFor = List<String>.from(p['hiring_for'] ?? []);

    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<void> _pickImg(String type) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: type == 'cover' ? 1920 : 600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      if (type == 'cover') {
        _coverBytes = bytes;
        _coverName = file.name;
      } else if (type == 'logo') {
        _logoBytes = bytes;
        _logoName = file.name;
      } else {
        _avatarBytes = bytes;
        _avatarName = file.name;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {
      'name': _nameCtrl.text,
      'tagline': _taglineCtrl.text,
      'bio': _bioCtrl.text,
      'location': _locationCtrl.text,
      'country': _countryCtrl.text,
      'phone': _phoneCtrl.text,
      'company_name': _companyCtrl.text,
      'industry': _industryCtrl.text,
      'company_description': _companyDescCtrl.text,
      'company_website': _companyWebCtrl.text,
      'linkedin': _linkedinCtrl.text,
      'twitter': _twitterCtrl.text,
      'timezone': _timezoneCtrl.text,
      'founded_year': int.tryParse(_foundedCtrl.text),
      'budget_range_min': double.tryParse(_budgetMinCtrl.text),
      'budget_range_max': double.tryParse(_budgetMaxCtrl.text),
      'company_size': _companySize,
      'preferred_contract_type': _contractType,
      'preferred_skills': _preferredSkills,
      'hiring_for': _hiringFor,
    };
    final res = await ProfileApiService.updateClientProfile(
      data,
      avatarBytes: _avatarBytes,
      avatarFileName: _avatarName,
      coverBytes: _coverBytes,
      coverFileName: _coverName,
    );

    if (_logoBytes != null)
      await ProfileApiService.uploadCompanyLogo(_logoBytes!, _logoName!);

    setState(() => _saving = false);
    if (res['profile_strength'] != null ||
        res['message']?.toString().contains('✅') == true) {
      Fluttertoast.showToast(
        msg: '✅ Profile updated!',
        backgroundColor: _primary,
        textColor: Colors.white,
      );
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: res['message'] ?? 'Error',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _coverAvatarSection(),
                  const SizedBox(height: 16),
                  _section('Personal Info', Icons.person_outline, [
                    _field('Full Name', _nameCtrl, hint: 'Your name'),
                    _field(
                      'Tagline',
                      _taglineCtrl,
                      hint: 'What you\'re looking for',
                      maxLength: 160,
                    ),
                    _field(
                      'Bio',
                      _bioCtrl,
                      hint: 'Tell freelancers about yourself...',
                      maxLines: 4,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _section('Company Info', Icons.business, [
                    _field(
                      'Company Name',
                      _companyCtrl,
                      hint: 'Your company name',
                    ),
                    _field(
                      'Industry',
                      _industryCtrl,
                      hint: 'e.g. Software, E-commerce',
                    ),
                    _field(
                      'Company Description',
                      _companyDescCtrl,
                      hint: 'What does your company do?',
                      maxLines: 3,
                    ),
                    _field(
                      'Company Website',
                      _companyWebCtrl,
                      hint: 'https://company.com',
                      prefixIcon: Icons.public,
                    ),
                    _field(
                      'Founded Year',
                      _foundedCtrl,
                      hint: '2020',
                      keyboardType: TextInputType.number,
                    ),
                    _companySizePicker(),
                  ]),
                  const SizedBox(height: 16),
                  _section('Location & Contact', Icons.location_on_outlined, [
                    _field('Location', _locationCtrl, hint: 'City, Region'),
                    _field('Country', _countryCtrl, hint: 'Country'),
                    _field('Timezone', _timezoneCtrl, hint: 'e.g. GMT+3'),
                    _field(
                      'Phone',
                      _phoneCtrl,
                      hint: '+1 ···',
                      keyboardType: TextInputType.phone,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _section('Hiring Preferences', Icons.work_outline, [
                    _contractTypePicker(),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Min Budget (\$)',
                            _budgetMinCtrl,
                            hint: '100',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            'Max Budget (\$)',
                            _budgetMaxCtrl,
                            hint: '5000',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    _chipsEditor(
                      'Skills Needed',
                      _preferredSkills,
                      _skillInput,
                      'Add skill...',
                    ),
                    _chipsEditor(
                      'Hiring for (Project Types)',
                      _hiringFor,
                      _hiringInput,
                      'e.g. Mobile App, Website...',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _section('Social Links', Icons.link, [
                    _field(
                      'LinkedIn',
                      _linkedinCtrl,
                      hint: 'https://linkedin.com/company/...',
                      prefixIcon: Icons.work,
                    ),
                    _field(
                      'Twitter',
                      _twitterCtrl,
                      hint: 'https://twitter.com/...',
                      prefixIcon: Icons.chat,
                    ),
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _coverAvatarSection() {
    final u = Map<String, dynamic>.from(_data['user'] ?? {});
    final p = Map<String, dynamic>.from(_data['profile'] ?? {});
    final existingCover = ProfileApiService.fullImageUrl(u['cover_image']);
    final existingAvatar = ProfileApiService.fullImageUrl(u['avatar']);
    final existingLogo = ProfileApiService.fullImageUrl(p['company_logo']);
    final name = u['name'] ?? 'C';

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickImg('cover'),
            child: Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_coverBytes != null)
                      Image.memory(_coverBytes!, fit: BoxFit.cover)
                    else if (existingCover.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: existingCover,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0A3D6B),
                              Color(0xFF0A66C2),
                              Color(0xFF1DA1F2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    Container(color: Colors.black26),
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: Colors.white,
                            size: 26,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Change Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _pickImg('avatar'),
                  child: Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: _primary,
                        ),
                        child: ClipOval(
                          child: _avatarBytes != null
                              ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                              : existingAvatar.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: existingAvatar,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickImg('logo'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(10),
                        color: _bg,
                      ),
                      child: _logoBytes != null
                          ? Image.memory(_logoBytes!, fit: BoxFit.contain)
                          : existingLogo.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: existingLogo,
                              fit: BoxFit.contain,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.business,
                                  color: Color(0xFF8FA3BF),
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Upload Company Logo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8FA3BF),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: _primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: c,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    int? maxLength,
    IconData? prefixIcon,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _textMid,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textLight, fontSize: 13),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 16, color: _textLight)
              : null,
          filled: true,
          fillColor: _bg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          counterText: '',
        ),
        style: const TextStyle(fontSize: 13, color: _textDark),
      ),
    ],
  );

  Widget _companySizePicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Company Size',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _textMid,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: ['1', '2-10', '11-50', '51-200', '201-1000', '1000+']
            .map(
              (s) => GestureDetector(
                onTap: () => setState(() => _companySize = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _companySize == s ? _primary : _bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _companySize == s ? _primary : _border,
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _companySize == s ? Colors.white : _textMid,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget _contractTypePicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Preferred Contract Type',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _textMid,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _cBtn('Hourly', 'hourly'),
          const SizedBox(width: 8),
          _cBtn('Fixed Price', 'fixed'),
          const SizedBox(width: 8),
          _cBtn('Both', 'both'),
        ],
      ),
    ],
  );

  Widget _cBtn(String label, String val) => GestureDetector(
    onTap: () => setState(() => _contractType = val),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _contractType == val ? _primary : _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _contractType == val ? _primary : _border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _contractType == val ? Colors.white : _textMid,
        ),
      ),
    ),
  );

  Widget _chipsEditor(
    String label,
    List<String> list,
    TextEditingController ctrl,
    String hint,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _textMid,
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primary),
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onFieldSubmitted: (_) => _addChip(list, ctrl),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _addChip(list, ctrl),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: list
            .asMap()
            .entries
            .map(
              (e) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => list.removeAt(e.key)),
                      child: const Icon(Icons.close, size: 14, color: _primary),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ],
  );

  void _addChip(List<String> list, TextEditingController ctrl) {
    final s = ctrl.text.trim();
    if (s.isNotEmpty && !list.contains(s))
      setState(() {
        list.add(s);
        ctrl.clear();
      });
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});
  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _exp = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.text,
        maxLines: _exp ? null : 4,
        overflow: _exp ? null : TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF4A5568),
          height: 1.6,
        ),
      ),
      if (widget.text.length > 200)
        GestureDetector(
          onTap: () => setState(() => _exp = !_exp),
          child: Text(
            _exp ? 'Show less' : 'Show more',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF0A66C2),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ],
  );
}

// lib/screens/landing/landing_screen_enhanced.dart
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/landing_service.dart';
import '../../models/landing_data.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class AppColors {
  static const brand = Color(0xFF6C3AFF);
  static const brand2 = Color(0xFF9B59FF);
  static const accent = Color(0xFFFF6B35);
  static const accent2 = Color(0xFFFFB347);
  static const darkBg = Color(0xFF0D0B1E);
  static const darkCard = Color(0xFF1A1535);
  static const darkCard2 = Color(0xFF13102B);
  static const glass = Color(0x1AFFFFFF);
  static const border = Color(0x1FFFFFFF);
  static const textPrimary = Colors.white;
  static const textMuted = Color(0x99FFFFFF);
  static const textSubtle = Color(0x55FFFFFF);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brand, brand2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroBg = LinearGradient(
    colors: [darkBg, Color(0xFF130F2A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;

  const ParticleBackground({
    Key? key,
    required this.child,
    this.particleCount = 50,
  }) : super(key: key);

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _initParticles();

    _controller.addListener(() {
      _updateParticles();
    });
  }

  void _initParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 3,
        speed: 0.5 + _random.nextDouble() * 2,
        color: Color.fromRGBO(
          108 + _random.nextInt(50),
          58 + _random.nextInt(50),
          255,
          0.2 + _random.nextDouble() * 0.3,
        ),
      );
    });
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.y -= particle.speed * 0.001;
      if (particle.y < 0) {
        particle.y = 1;
        particle.x = _random.nextDouble();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(painter: _ParticlePainter(_particles), size: Size.infinite),
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x, y, size, speed;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = particle.color;
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedHover extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;

  const AnimatedHover({
    Key? key,
    required this.child,
    this.scale = 1.05,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<AnimatedHover> createState() => _AnimatedHoverState();
}

class _AnimatedHoverState extends State<AnimatedHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isHovered ? 1.0 : 0.9,
          duration: widget.duration,
          child: widget.child,
        ),
      ),
    );
  }
}

class AnimatedCounter extends StatefulWidget {
  final int targetValue;
  final String label;
  final String suffix;
  final bool isLast;

  const AnimatedCounter({
    Key? key,
    required this.targetValue,
    required this.label,
    required this.suffix,
    required this.isLast,
  }) : super(key: key);

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.targetValue.toDouble(),
    ).animate(_controller);

    _animation.addListener(() {
      setState(() {
        _currentValue = _animation.value.round();
      });
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        border: Border(
          right: widget.isLast
              ? BorderSide.none
              : BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [AppColors.brand2, AppColors.accent2],
            ).createShader(b),
            child: Text(
              '$_currentValue${widget.suffix}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class LandingScreenEnhanced extends StatefulWidget {
  const LandingScreenEnhanced({super.key});

  @override
  State<LandingScreenEnhanced> createState() => _LandingScreenEnhancedState();
}

class _LandingScreenEnhancedState extends State<LandingScreenEnhanced>
    with SingleTickerProviderStateMixin {
  LandingData? landingData;
  bool loading = true;
  late AnimationController _animController;
  late ScrollController _scrollController;
  bool _showBackToTop = false;
  int _currentCarouselIndex = 0;

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.verified_rounded,
      'title': 'Verified Pros',
      'desc': 'Every freelancer is background-checked & skill-verified.',
      'color': AppColors.brand,
    },
    {
      'icon': Icons.lock_rounded,
      'title': 'Secure Payments',
      'desc': 'Escrow system keeps funds safe until the job is approved.',
      'color': AppColors.accent,
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'title': 'AI Matching',
      'desc': 'Smart algorithm finds your perfect match in seconds.',
      'color': AppColors.accent2,
    },
    {
      'icon': Icons.public_rounded,
      'title': 'Global Talent',
      'desc': 'Access top talent from 150+ countries worldwide.',
      'color': AppColors.brand2,
    },
    {
      'icon': Icons.bar_chart_rounded,
      'title': 'Live Analytics',
      'desc': 'Real-time dashboards for projects, spending & performance.',
      'color': const Color(0xFF38BDF8),
    },
    {
      'icon': Icons.headset_mic_rounded,
      'title': '24/7 Support',
      'desc': 'Our team is always available to resolve issues instantly.',
      'color': const Color(0xFFF472B6),
    },
  ];

  final List<Map<String, dynamic>> _steps = [
    {
      'num': '1',
      'title': 'Create Account',
      'desc': 'Sign up in under 2 minutes and set up your profile.',
    },
    {
      'num': '2',
      'title': 'Post a Project',
      'desc': 'Describe your needs and set your budget range.',
    },
    {
      'num': '3',
      'title': 'Get AI Matched',
      'desc': 'Receive curated proposals from top-rated freelancers.',
    },
    {
      'num': '4',
      'title': 'Pay & Done',
      'desc': 'Approve the work and release payment securely.',
    },
  ];

  final List<Map<String, dynamic>> _jobs = [
    {
      'emoji': '📱',
      'badge': '🔥 Hot',
      'badgeColor': AppColors.brand,
      'title': 'Senior Flutter Developer',
      'budget': '\$5K–\$8K',
      'duration': '3 months',
      'skills': ['Flutter', 'Dart', 'Firebase'],
    },
    {
      'emoji': '🎨',
      'badge': '✨ New',
      'badgeColor': AppColors.accent,
      'title': 'UI/UX Designer',
      'budget': '\$3K–\$5K',
      'duration': '2 months',
      'skills': ['Figma', 'Adobe XD', 'Prototyping'],
    },
    {
      'emoji': '⚙️',
      'badge': '💎 Featured',
      'badgeColor': const Color(0xFF10B981),
      'title': 'Backend Developer',
      'budget': '\$6K–\$10K',
      'duration': '4 months',
      'skills': ['Node.js', 'Python', 'PostgreSQL'],
    },
  ];

  final List<Map<String, String>> _heroTagsList = const [
    {'label': '🎨 UI Design'},
    {'label': '⚙️ Flutter Dev'},
    {'label': '🤖 AI & ML'},
    {'label': '✍️ Content'},
    {'label': '📱 Mobile Apps'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _showBackToTop = _scrollController.offset > 400;
        });
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final data = await LandingService.getLandingPage();
      setState(() {
        landingData = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint('Landing page error: $e');
    }
  }

  void _scrollToTop() => _scrollController.animateTo(
    0,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.brand),
          ),
        ),
      );
    }

    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 800;

    return ParticleBackground(
      particleCount: 30,
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        floatingActionButton: _showBackToTop ? _backToTopBtn() : null,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildSliverAppBar(isMobile),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHero(isMobile),
                  _buildStats(),
                  _buildFeatures(isMobile),
                  _buildHowItWorks(isMobile),
                  _buildLatestJobs(isMobile),
                  _buildTestimonials(isMobile),
                  _buildCTA(isMobile),
                  _buildFooter(isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(bool isMobile) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppColors.darkBg.withOpacity(0.85),
      elevation: 0,
      toolbarHeight: 64,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.brandGradient.createShader(bounds),
                  child: const Text(
                    '⚡ FreelanceX',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                if (!isMobile) ...[
                  _navLink('Find Work'),
                  _navLink('Hire Talent'),
                  _navLink('Projects'),
                  const SizedBox(width: 24),
                ],
                _ghostBtn(
                  'Login',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                _gradientBtn(
                  'Get Started →',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroBg),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 60 : 100,
      ),
      child: isMobile ? _heroMobile() : _heroDesktop(),
    );
  }

  Widget _heroMobile() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      FadeInDown(child: _heroBadge()),
      const SizedBox(height: 24),
      _heroHeadline(center: true),
      const SizedBox(height: 20),
      FadeInLeft(
        child: Text(
          'Connect with verified freelancers, get projects done faster, and grow your business with confidence.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textMuted,
            height: 1.7,
          ),
        ),
      ),
      const SizedBox(height: 32),
      FadeInUp(child: _searchBar()),
      const SizedBox(height: 20),
      FadeInUp(delay: const Duration(milliseconds: 200), child: _heroTags()),
      const SizedBox(height: 40),
      ZoomIn(child: _heroLottie(200)),
    ],
  );

  Widget _heroDesktop() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(child: _heroBadge()),
            const SizedBox(height: 24),
            _heroHeadline(center: false),
            const SizedBox(height: 20),
            FadeInLeft(
              child: Text(
                'Connect with verified freelancers, get projects done faster, and grow your business with confidence.',
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.textMuted,
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 36),
            FadeInUp(child: _searchBar()),
            const SizedBox(height: 20),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _heroTags(),
            ),
          ],
        ),
      ),
      const SizedBox(width: 48),
      Expanded(child: ZoomIn(child: _heroLottie(380))),
    ],
  );

  Widget _heroBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.brand.withOpacity(0.15),
      border: Border.all(color: AppColors.brand.withOpacity(0.4)),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.brand2,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '#1 Freelance Platform 2025',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.brand2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _heroHeadline({required bool center}) {
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        FadeInDown(
          child: Text(
            'Find the best',
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: AnimatedTextKit(
            animatedTexts: [
              ColorizeAnimatedText(
                'Freelancers',
                textStyle: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                ),
                colors: [AppColors.brand2, AppColors.accent],
              ),
              ColorizeAnimatedText(
                'Developers',
                textStyle: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                ),
                colors: [AppColors.accent, AppColors.accent2],
              ),
              ColorizeAnimatedText(
                'Designers',
                textStyle: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                ),
                colors: [AppColors.accent2, AppColors.brand2],
              ),
            ],
            repeatForever: true,
            pause: const Duration(milliseconds: 1000),
          ),
        ),
      ],
    );
  }

  Widget _searchBar() => Container(
    height: 58,
    constraints: const BoxConstraints(maxWidth: 540),
    decoration: BoxDecoration(
      color: AppColors.glass,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Row(
      children: [
        const SizedBox(width: 20),
        const Icon(Icons.search, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search skills, jobs or freelancers...',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text(
              'Search',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _heroTags() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: _heroTagsList.map((t) => _pillTag(t['label']!)).toList(),
  );

  Widget _pillTag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.glass,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      label,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    ),
  );

  Widget _heroLottie(double size) => Lottie.network(
    'https://assets5.lottiefiles.com/packages/lf20_vp6f6fqg.json',
    height: size,
    errorBuilder: (_, __, ___) => Container(
      height: size,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Icon(Icons.animation_rounded, size: 64, color: AppColors.brand),
      ),
    ),
  );

  Widget _buildStats() {
    final s = landingData?.stats;
    final items = [
      {'val': '${s?.users ?? 50}K+', 'label': 'Freelancers'},
      {'val': '${s?.projects ?? 120}K+', 'label': 'Projects Done'},
      {'val': '98%', 'label': 'Satisfaction'},
      {'val': '\$${s?.earnings ?? 8}M+', 'label': 'Total Earnings'},
    ];

    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        color: AppColors.darkCard2,
        child: Row(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            final numericValue = int.parse(
              e.value['val']!.replaceAll(RegExp(r'[^0-9]'), ''),
            );
            return Expanded(
              child: AnimatedCounter(
                targetValue: numericValue,
                label: e.value['label']!,
                suffix: e.value['val']!.contains('K+')
                    ? 'K+'
                    : (e.value['val']!.contains('M+')
                          ? 'M+'
                          : (e.value['val']!.contains('%') ? '%' : '')),
                isLast: isLast,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeatures(bool isMobile) {
    return Container(
      color: AppColors.darkBg,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: 80,
      ),
      child: Column(
        children: [
          FadeInDown(child: _sectionLabel('Why FreelanceX')),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: _sectionTitle('Everything you need\nto succeed online'),
          ),
          const SizedBox(height: 48),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile
                  ? 1
                  : (MediaQuery.of(context).size.width > 900 ? 3 : 2),
              childAspectRatio: isMobile ? 2.5 : 1.15,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
            itemCount: _features.length,
            itemBuilder: (_, i) => FadeInUp(
              delay: Duration(milliseconds: 200 + i * 100),
              child: _featureCard(_features[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(Map<String, dynamic> f) {
    final color = f['color'] as Color;
    return AnimatedHover(
      scale: 1.03,
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkCard, AppColors.darkCard.withOpacity(0.8)],
          ),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 0.5,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      f['icon'] as IconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              f['title'] as String,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              f['desc'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
            const Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.5)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Learn more',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks(bool isMobile) {
    return Container(
      color: AppColors.darkCard2,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: 80,
      ),
      child: Column(
        children: [
          FadeInDown(child: _sectionLabel('Simple Process')),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: _sectionTitle('Start in 4 easy steps'),
          ),
          const SizedBox(height: 48),
          isMobile
              ? Column(
                  children: _steps
                      .asMap()
                      .entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: FadeInRight(
                            delay: Duration(milliseconds: 200 + e.key * 100),
                            child: _stepCard(
                              e.value,
                              isLast: e.key == _steps.length - 1,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _steps
                      .asMap()
                      .entries
                      .map(
                        (e) => Expanded(
                          child: FadeInUp(
                            delay: Duration(milliseconds: 200 + e.key * 100),
                            child: _stepCard(
                              e.value,
                              isLast: e.key == _steps.length - 1,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _stepCard(Map<String, dynamic> step, {required bool isLast}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (!isLast)
                Positioned(
                  left: 40,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: AppColors.brand.withOpacity(0.3),
                  ),
                ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + (value * 0.5),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          step['num'] as String,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            step['title'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step['desc'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestJobs(bool isMobile) {
    return Container(
      color: AppColors.darkBg,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: 80,
      ),
      child: Column(
        children: [
          FadeInDown(child: _sectionLabel('Hot Opportunities')),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: _sectionTitle('Latest projects posted'),
          ),
          const SizedBox(height: 48),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 18,
            children: _jobs
                .asMap()
                .entries
                .map(
                  (e) => FadeInUp(
                    delay: Duration(milliseconds: 200 + e.key * 100),
                    child: SizedBox(width: 320, child: _jobCard(e.value)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _jobCard(Map<String, dynamic> j) {
    final badgeColor = j['badgeColor'] as Color;
    return AnimatedHover(
      scale: 1.02,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      j['emoji'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    border: Border.all(color: badgeColor.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    j['badge'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              j['title'] as String,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.attach_money_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  j['budget'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  j['duration'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (j['skills'] as List<String>)
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Apply Now →',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonials(bool isMobile) {
    final testimonials = landingData?.testimonials ?? [];
    if (testimonials.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.darkCard2,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: 80,
      ),
      child: Column(
        children: [
          FadeInDown(child: _sectionLabel('Social Proof')),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: _sectionTitle('What our users say'),
          ),
          const SizedBox(height: 48),
          CarouselSlider(
            options: CarouselOptions(
              height: 280,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: isMobile ? 0.9 : 0.38,
              onPageChanged: (i, _) =>
                  setState(() => _currentCarouselIndex = i),
            ),
            items: testimonials.asMap().entries.map((entry) {
              final index = entry.key;
              final t = entry.value;
              return FadeInUp(
                delay: Duration(milliseconds: 200 + index * 100),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < t.rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppColors.accent2,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Text(
                          '"${t.content}"',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                            height: 1.65,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.brand.withOpacity(0.3),
                            backgroundImage: t.avatar != null
                                ? NetworkImage(t.avatar!)
                                : null,
                            child: t.avatar == null
                                ? Text(
                                    t.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.brand2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                t.role ?? 'User',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              testimonials.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentCarouselIndex == i ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentCarouselIndex == i
                      ? AppColors.brand2
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(bool isMobile) {
    return FadeInUp(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 48,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 64,
          vertical: 72,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A3C), Color(0xFF2D0E5C), Color(0xFF1A0A3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.brand.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Colors.white, Color(0xFFD4AAFF)],
              ).createShader(b),
              child: Text(
                'Ready to get started?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 32 : 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Join 50,000+ professionals already building their future on FreelanceX',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const Text(
                            'Start Hiring Today',
                            style: TextStyle(
                              color: AppColors.darkBg,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const Text(
                            '▶ Watch Demo',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      color: AppColors.darkCard2,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: 48,
      ),
      child: Column(
        children: [
          isMobile ? _footerMobile() : _footerDesktop(),
          const SizedBox(height: 32),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2025 FreelanceX. All rights reserved.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              Row(
                children: [
                  _socialBtn('𝕏'),
                  const SizedBox(width: 10),
                  _socialBtn('in'),
                  const SizedBox(width: 10),
                  _socialBtn('f'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerDesktop() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 2, child: _footerBrand()),
      Expanded(
        child: _footerCol('Platform', [
          'Find Work',
          'Hire Talent',
          'How it Works',
          'Pricing',
        ]),
      ),
      Expanded(
        child: _footerCol('Company', ['About Us', 'Blog', 'Careers', 'Press']),
      ),
      Expanded(
        child: _footerCol('Legal', [
          'Privacy Policy',
          'Terms',
          'Cookie Policy',
          'GDPR',
        ]),
      ),
    ],
  );

  Widget _footerMobile() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _footerBrand(),
      const SizedBox(height: 32),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _footerCol('Platform', [
              'Find Work',
              'Hire Talent',
              'Pricing',
            ]),
          ),
          Expanded(child: _footerCol('Company', ['About', 'Blog', 'Careers'])),
          Expanded(child: _footerCol('Legal', ['Privacy', 'Terms', 'GDPR'])),
        ],
      ),
    ],
  );

  Widget _footerBrand() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ShaderMask(
        shaderCallback: (b) => AppColors.brandGradient.createShader(b),
        child: const Text(
          '⚡ FreelanceX',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'The world\'s leading platform connecting top freelancers with innovative businesses.',
        style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.7),
      ),
    ],
  );

  Widget _footerCol(String title, List<String> links) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 14),
      ...links.map(
        (l) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () {},
            child: Text(
              l,
              style: const TextStyle(fontSize: 14, color: AppColors.textSubtle),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _socialBtn(String label) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: AppColors.glass,
      border: Border.all(color: AppColors.border),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.brand2,
      letterSpacing: 3,
    ),
  );

  Widget _sectionTitle(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      height: 1.2,
    ),
  );

  Widget _navLink(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      ),
    ),
  );

  Widget _ghostBtn(String label, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      foregroundColor: Colors.white,
    ),
    child: Text(label, style: const TextStyle(fontSize: 14)),
  );

  Widget _gradientBtn(String label, VoidCallback onTap) =>
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (value * 0.1),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _backToTopBtn() => FloatingActionButton(
    mini: true,
    onPressed: _scrollToTop,
    backgroundColor: AppColors.brand,
    elevation: 8,
    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
  );
}

// Preset project posts — client can apply from Create Project screen.

class ProjectPostTemplate {
  final String id;
  final String name;
  final String subtitle;
  final String title;
  final String description;
  final String category;
  final List<String> skills;
  final String budgetHint;
  final String durationHint;

  const ProjectPostTemplate({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.title,
    required this.description,
    required this.category,
    required this.skills,
    required this.budgetHint,
    required this.durationHint,
  });
}

class ProjectPostTemplates {
  static const List<ProjectPostTemplate> all = [
    ProjectPostTemplate(
      id: 'mobile_app',
      name: 'Mobile app (MVP)',
      subtitle: 'Flutter / React Native',
      title: 'Mobile app MVP — iOS & Android',
      description:
          'Looking for an experienced mobile developer to build an MVP.\n\n'
          'Scope:\n'
          '- Auth (email + social)\n'
          '- Core user flows and navigation\n'
          '- Backend API integration\n'
          '- Test build + store-ready basics\n\n'
          'Please include similar apps in your proposal and your suggested timeline.',
      category: 'Mobile Development',
      skills: ['Flutter', 'Node.js', 'PostgreSQL'],
      budgetHint: '4500',
      durationHint: '45',
    ),
    ProjectPostTemplate(
      id: 'web_saas',
      name: 'Web / SaaS',
      subtitle: 'Dashboard + API',
      title: 'SaaS web app — dashboard & billing',
      description:
          'We need a modern web application with:\n'
          '- Responsive dashboard (roles/permissions)\n'
          '- REST or GraphQL API\n'
          '- Stripe or similar billing hooks\n'
          '- Basic analytics\n\n'
          'Tech stack is flexible; justify your choices in the proposal.',
      category: 'Web Development',
      skills: ['React', 'Node.js', 'PostgreSQL', 'AWS'],
      budgetHint: '6000',
      durationHint: '60',
    ),
    ProjectPostTemplate(
      id: 'brand_ui',
      name: 'Brand & UI',
      subtitle: 'Design system',
      title: 'UI/UX + design system for product',
      description:
          'Looking for a designer to:\n'
          '- Audit current flows\n'
          '- Produce high-fidelity screens (Figma)\n'
          '- Deliver a small component library / tokens\n'
          '- Handoff notes for developers\n\n'
          'Attach portfolio links with similar B2B work.',
      category: 'UI/UX Design',
      skills: ['UI/UX', 'Graphic Design'],
      budgetHint: '2500',
      durationHint: '21',
    ),
    ProjectPostTemplate(
      id: 'content_seo',
      name: 'Content & SEO',
      subtitle: 'Blog + landing pages',
      title: 'Content strategy + SEO articles',
      description:
          'Need a writer/marketer to:\n'
          '- Define tone and content pillars\n'
          '- Write 8–12 long-form articles\n'
          '- On-page SEO (titles, meta, internal links)\n\n'
          'Share samples in your niche.',
      category: 'Content Writing',
      skills: ['Content Writing', 'SEO', 'Marketing'],
      budgetHint: '1200',
      durationHint: '30',
    ),
    ProjectPostTemplate(
      id: 'devops',
      name: 'DevOps / Cloud',
      subtitle: 'CI/CD + infra',
      title: 'CI/CD pipeline & cloud setup',
      description:
          'We want help with:\n'
          '- GitHub Actions or GitLab CI\n'
          '- Dockerized services\n'
          '- Staging + production on AWS or similar\n'
          '- Monitoring basics\n\n'
          'List certifications or similar projects.',
      category: 'DevOps',
      skills: ['Docker', 'AWS', 'Kubernetes'],
      budgetHint: '3500',
      durationHint: '28',
    ),
  ];
}

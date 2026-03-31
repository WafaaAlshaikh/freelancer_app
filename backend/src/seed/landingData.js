// seed/landingData.js
import PageContent from "../models/PageContent.js";

export const seedLandingData = async () => {
  const sections = [
    {
      section: "hero",
      title: "Find the Best Freelancers",
      subtitle: "Connect with top freelancers and get your projects done efficiently",
      mediaUrl: "https://images.unsplash.com/photo-1522071820081-009f0129c71c",
      order: 1,
      isActive: true,
    },
    {
      section: "features",
      title: "Why Choose Us?",
      subtitle: "We provide the best platform for freelancers and clients",
      content: JSON.stringify([
        {
          icon: "verified",
          title: "Verified Professionals",
          description: "All freelancers are verified and reviewed",
        },
        {
          icon: "security",
          title: "Secure Payments",
          description: "Escrow system ensures safe transactions",
        },
        {
          icon: "support_agent",
          title: "24/7 Support",
          description: "Dedicated support team available round the clock",
        },
      ]),
      order: 2,
      isActive: true,
    },
    {
      section: "how_it_works",
      title: "How It Works",
      subtitle: "Simple steps to get started",
      content: JSON.stringify([
        {
          title: "Create Account",
          description: "Sign up as a freelancer or client",
        },
        {
          title: "Post/Find Projects",
          description: "Post your project or find the perfect job",
        },
        {
          title: "Work & Get Paid",
          description: "Complete work and receive payment securely",
        },
      ]),
      order: 3,
      isActive: true,
    },
    {
      section: "video",
      title: "Watch Our Video",
      subtitle: "See how our platform works",
      mediaUrl: "https://www.youtube.com/embed/dQw4w9WgXcQ",
      order: 4,
      isActive: true,
    },
    {
      section: "cta",
      title: "Ready to Get Started?",
      subtitle: "Join thousands of freelancers and clients on our platform",
      content: "Sign Up Now",
      order: 5,
      isActive: true,
    },
  ];

  for (const section of sections) {
    await PageContent.upsert(section);
  }
  
  console.log("✅ Landing page data seeded");
};
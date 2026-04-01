// backend/src/seed/seedSkillTests.js
import { sequelize } from "../config/db.js";
import SkillTest from "../models/SkillTest.js";
import Badge from "../models/Badge.js";

const skillTests = [
  {
    name: "Flutter Development",
    slug: "flutter-development",
    description: "Test your knowledge of Flutter framework, widgets, state management, and app development.",
    skill_category: "Programming",
    difficulty: "intermediate",
    passing_score: 70,
    time_limit_minutes: 30,
    max_attempts: 3,
    questions: [
      {
        id: 1,
        text: "What is the main programming language used in Flutter?",
        type: "multiple_choice",
        options: ["JavaScript", "Kotlin", "Dart", "Swift"],
        correct_option: "Dart",
        points: 10
      },
      {
        id: 2,
        text: "Which widget is used for creating a scrollable list?",
        type: "multiple_choice",
        options: ["Column", "Row", "ListView", "Container"],
        correct_option: "ListView",
        points: 10
      },
      {
        id: 3,
        text: "What is the purpose of the 'setState' method?",
        type: "multiple_choice",
        options: [
          "To create a new widget",
          "To update the UI when state changes",
          "To navigate between screens",
          "To handle API calls"
        ],
        correct_option: "To update the UI when state changes",
        points: 10
      },
      {
        id: 4,
        text: "Which of these is a state management solution in Flutter?",
        type: "multiple_choice",
        options: ["Redux", "Provider", "Vuex", "NgRx"],
        correct_option: "Provider",
        points: 10
      },
      {
        id: 5,
        text: "What is the default entry point of a Flutter app?",
        type: "multiple_choice",
        options: ["start()", "main()", "run()", "app()"],
        correct_option: "main()",
        points: 10
      },
      {
        id: 6,
        text: "Which widget is used for navigation between screens?",
        type: "multiple_choice",
        options: ["Navigator", "Router", "PageView", "TabBar"],
        correct_option: "Navigator",
        points: 10
      },
      {
        id: 7,
        text: "What does 'pubspec.yaml' file contain?",
        type: "multiple_choice",
        options: [
          "Dart code",
          "Project dependencies and configuration",
          "App icons",
          "Database schema"
        ],
        correct_option: "Project dependencies and configuration",
        points: 10
      },
      {
        id: 8,
        text: "Which command is used to get dependencies in Flutter?",
        type: "multiple_choice",
        options: ["flutter install", "flutter get", "flutter pub get", "flutter update"],
        correct_option: "flutter pub get",
        points: 10
      },
      {
        id: 9,
        text: "What is Hot Reload in Flutter?",
        type: "multiple_choice",
        options: [
          "Restarting the entire app",
          "Injecting updated source code files into the running Dart VM",
          "Rebuilding the app from scratch",
          "Clearing app data"
        ],
        correct_option: "Injecting updated source code files into the running Dart VM",
        points: 10
      },
      {
        id: 10,
        text: "Which widget is the base class for all widgets?",
        type: "multiple_choice",
        options: ["Widget", "StatelessWidget", "StatefulWidget", "RenderObjectWidget"],
        correct_option: "Widget",
        points: 10
      }
    ]
  },
  {
    name: "React Development",
    slug: "react-development",
    description: "Test your knowledge of React.js, hooks, components, and state management.",
    skill_category: "Programming",
    difficulty: "intermediate",
    passing_score: 70,
    time_limit_minutes: 30,
    max_attempts: 3,
    questions: [
      {
        id: 1,
        text: "What is React?",
        type: "multiple_choice",
        options: [
          "A JavaScript framework",
          "A JavaScript library for building user interfaces",
          "A backend framework",
          "A database"
        ],
        correct_option: "A JavaScript library for building user interfaces",
        points: 10
      },
      {
        id: 2,
        text: "What is JSX?",
        type: "multiple_choice",
        options: [
          "JavaScript XML",
          "Java Syntax Extension",
          "JavaScript Extension",
          "JSON XML"
        ],
        correct_option: "JavaScript XML",
        points: 10
      },
      {
        id: 3,
        text: "Which hook is used to manage state in functional components?",
        type: "multiple_choice",
        options: ["useEffect", "useContext", "useState", "useReducer"],
        correct_option: "useState",
        points: 10
      },
      {
        id: 4,
        text: "What is the purpose of the 'useEffect' hook?",
        type: "multiple_choice",
        options: [
          "To manage state",
          "To perform side effects in function components",
          "To create refs",
          "To optimize performance"
        ],
        correct_option: "To perform side effects in function components",
        points: 10
      },
      {
        id: 5,
        text: "What are props in React?",
        type: "multiple_choice",
        options: [
          "Properties passed to components",
          "State variables",
          "Database connections",
          "CSS styles"
        ],
        correct_option: "Properties passed to components",
        points: 10
      },
      {
        id: 6,
        text: "What is the virtual DOM?",
        type: "multiple_choice",
        options: [
          "A copy of the real DOM",
          "A database for React",
          "A CSS framework",
          "A testing tool"
        ],
        correct_option: "A copy of the real DOM",
        points: 10
      },
      {
        id: 7,
        text: "Which command creates a new React app?",
        type: "multiple_choice",
        options: [
          "npm start react",
          "create-react-app my-app",
          "react new my-app",
          "npx create-react-app my-app"
        ],
        correct_option: "npx create-react-app my-app",
        points: 10
      }
    ]
  },
  {
    name: "UI/UX Design Fundamentals",
    slug: "ui-ux-design",
    description: "Test your knowledge of user interface and user experience design principles.",
    skill_category: "Design",
    difficulty: "beginner",
    passing_score: 70,
    time_limit_minutes: 20,
    max_attempts: 3,
    questions: [
      {
        id: 1,
        text: "What does UX stand for?",
        type: "multiple_choice",
        options: ["User Experience", "User X-ray", "Universal Xylophone", "Unique X-factor"],
        correct_option: "User Experience",
        points: 10
      },
      {
        id: 2,
        text: "What does UI stand for?",
        type: "multiple_choice",
        options: ["User Interface", "Universal Interaction", "User Integration", "Unique Identity"],
        correct_option: "User Interface",
        points: 10
      },
      {
        id: 3,
        text: "What is a wireframe?",
        type: "multiple_choice",
        options: [
          "A high-fidelity mockup",
          "A low-fidelity layout of a design",
          "A color palette",
          "A font style"
        ],
        correct_option: "A low-fidelity layout of a design",
        points: 10
      },
      {
        id: 4,
        text: "Which color scheme uses colors opposite each other on the color wheel?",
        type: "multiple_choice",
        options: ["Analogous", "Complementary", "Monochromatic", "Triadic"],
        correct_option: "Complementary",
        points: 10
      },
      {
        id: 5,
        text: "What is the purpose of user research?",
        type: "multiple_choice",
        options: [
          "To test code",
          "To understand user needs and behaviors",
          "To create logos",
          "To write documentation"
        ],
        correct_option: "To understand user needs and behaviors",
        points: 10
      }
    ]
  },
  {
    name: "Content Writing",
    slug: "content-writing",
    description: "Test your knowledge of content writing, SEO, and copywriting.",
    skill_category: "Writing",
    difficulty: "beginner",
    passing_score: 70,
    time_limit_minutes: 20,
    max_attempts: 3,
    questions: [
      {
        id: 1,
        text: "What does SEO stand for?",
        type: "multiple_choice",
        options: [
          "Search Engine Optimization",
          "Social Engagement Optimization",
          "Site Enhancement Operation",
          "Search Enhancement Organization"
        ],
        correct_option: "Search Engine Optimization",
        points: 10
      },
      {
        id: 2,
        text: "What is a headline?",
        type: "multiple_choice",
        options: [
          "The title of an article",
          "A type of font",
          "A website footer",
          "An image caption"
        ],
        correct_option: "The title of an article",
        points: 10
      },
      {
        id: 3,
        text: "What is copywriting?",
        type: "multiple_choice",
        options: [
          "Writing code",
          "Writing text for advertising or marketing",
          "Copying other content",
          "Writing academic papers"
        ],
        correct_option: "Writing text for advertising or marketing",
        points: 10
      },
      {
        id: 4,
        text: "What is a call to action (CTA)?",
        type: "multiple_choice",
        options: [
          "A phone number",
          "A prompt that encourages users to take action",
          "A website menu",
          "A type of button style"
        ],
        correct_option: "A prompt that encourages users to take action",
        points: 10
      }
    ]
  }
];

// دالة لإضافة الشارات الافتراضية للاختبارات
async function createBadges() {
  const badges = [
    {
      name: "Flutter Expert",
      slug: "flutter-expert",
      description: "Certified Flutter Developer",
      icon: "flutter",
      color: "#14A800",
      badge_type: "verification",
      is_active: true,
      is_featured: true,
      show_on_profile: true,
      criteria: JSON.stringify({ test_id: 1, min_score: 70 })
    },
    {
      name: "React Developer",
      slug: "react-developer",
      description: "Certified React Developer",
      icon: "react",
      color: "#61DAFB",
      badge_type: "verification",
      is_active: true,
      is_featured: true,
      show_on_profile: true,
      criteria: JSON.stringify({ test_id: 2, min_score: 70 })
    },
    {
      name: "UI/UX Designer",
      slug: "ui-ux-designer",
      description: "Certified UI/UX Designer",
      icon: "design",
      color: "#9C27B0",
      badge_type: "verification",
      is_active: true,
      is_featured: true,
      show_on_profile: true,
      criteria: JSON.stringify({ test_id: 3, min_score: 70 })
    },
    {
      name: "Content Writer",
      slug: "content-writer",
      description: "Certified Content Writer",
      icon: "write",
      color: "#FF9800",
      badge_type: "verification",
      is_active: true,
      is_featured: true,
      show_on_profile: true,
      criteria: JSON.stringify({ test_id: 4, min_score: 70 })
    }
  ];

  for (const badge of badges) {
    const [created] = await Badge.findOrCreate({
      where: { slug: badge.slug },
      defaults: badge,
    });
    console.log(`✅ Badge: ${created.name}`);
  }
}

async function seedSkillTests() {
  try {
    console.log("🌱 Seeding skill tests...");
    
    // أولاً نضيف الشارات
    await createBadges();
    
    // ثم نضيف الاختبارات
    for (let i = 0; i < skillTests.length; i++) {
      const testData = skillTests[i];
      const [test, created] = await SkillTest.findOrCreate({
        where: { slug: testData.slug },
        defaults: {
          name: testData.name,
          slug: testData.slug,
          description: testData.description,
          skill_category: testData.skill_category,
          difficulty: testData.difficulty,
          passing_score: testData.passing_score,
          time_limit_minutes: testData.time_limit_minutes,
          max_attempts: testData.max_attempts,
          questions: testData.questions,
          is_active: true,
        }
      });
      
      // ربط الشارة بالاختبار
      const badge = await Badge.findOne({
        where: { slug: `${testData.skill_category.toLowerCase()}-${testData.slug.split('-')[0]}` }
      });
      
      if (badge) {
        await test.update({ badge_id: badge.id });
      }
      
      console.log(`✅ Test: ${test.name} (${created ? 'created' : 'already exists'})`);
    }
    
    console.log("🎉 Skill tests seeding completed!");
    
  } catch (error) {
    console.error("❌ Error seeding skill tests:", error);
  }
}

export default seedSkillTests;
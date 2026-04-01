// backend/src/services/skillTestService.js
import { SkillTest, UserSkillTest, User, Badge, UserBadge, FreelancerProfile } from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "./notificationService.js";

class SkillTestService {
  // الحصول على جميع الاختبارات المتاحة
  static async getAvailableTests(userId, skillCategory = null) {
    try {
      const userTests = await UserSkillTest.findAll({
        where: { user_id: userId },
        attributes: ['test_id', 'passed', 'attempt_number'],
      });

      const completedTestIds = userTests
        .filter(ut => ut.passed || ut.attempt_number >= 3)
        .map(ut => ut.test_id);

      const whereClause = { is_active: true };
      if (skillCategory) whereClause.skill_category = skillCategory;
      if (completedTestIds.length > 0) {
        whereClause.id = { [Op.notIn]: completedTestIds };
      }

      const tests = await SkillTest.findAll({
        where: whereClause,
        order: [['difficulty', 'ASC']],
      });

      // إضافة معلومات عن محاولات المستخدم السابقة
      const testsWithUserInfo = tests.map(test => {
        const userTest = userTests.find(ut => ut.test_id === test.id);
        return {
          ...test.toJSON(),
          user_attempts: userTest?.attempt_number || 0,
          user_passed: userTest?.passed || false,
          can_retake: userTest && !userTest.passed && userTest.attempt_number < test.max_attempts,
        };
      });

      return testsWithUserInfo;
    } catch (error) {
      console.error('Error getting available tests:', error);
      return [];
    }
  }

  // الحصول على اختبار محدد مع أسئلته
  static async getTest(testId, userId) {
    try {
      const test = await SkillTest.findByPk(testId, {
        include: [{ model: Badge }],
      });

      if (!test) return null;

      // التحقق من عدد المحاولات
      const attempts = await UserSkillTest.count({
        where: { user_id: userId, test_id: testId },
      });

      if (attempts >= test.max_attempts) {
        throw new Error('Maximum attempts reached for this test');
      }

      // إخفاء الإجابات الصحيحة من الأسئلة
      const questions = test.questions.map(q => ({
        id: q.id,
        text: q.text,
        type: q.type,
        options: q.options,
        points: q.points,
      }));

      return {
        ...test.toJSON(),
        questions,
        remaining_attempts: test.max_attempts - attempts,
      };
    } catch (error) {
      console.error('Error getting test:', error);
      throw error;
    }
  }

// backend/src/services/skillTestService.js
static async startTest(testId, userId) {
  try {
    console.log(`Starting test ${testId} for user ${userId}`);
    
    const test = await SkillTest.findByPk(testId);
    if (!test) {
      console.log(`Test ${testId} not found`);
      throw new Error('Test not found');
    }

    const attempts = await UserSkillTest.count({
      where: { user_id: userId, test_id: testId },
    });
    
    console.log(`User ${userId} has ${attempts} attempts for test ${testId}`);

    if (attempts >= test.max_attempts) {
      throw new Error('Maximum attempts reached');
    }

    const userTest = await UserSkillTest.create({
      user_id: userId,
      test_id: testId,
      started_at: new Date(),
      attempt_number: attempts + 1,
      answers: [],
    });

    console.log(`Created user test with id: ${userTest.id}`);
    
    return { 
      userTestId: userTest.id,
      testId: test.id,
      startedAt: userTest.started_at 
    };
  } catch (error) {
    console.error('Error starting test:', error);
    throw error;
  }
}
  // تقديم الاختبار
  static async submitTest(userTestId, answers) {
    try {
      const userTest = await UserSkillTest.findByPk(userTestId, {
        include: [{ model: SkillTest }],
      });

      if (!userTest) throw new Error('Test session not found');
      if (userTest.completed_at) throw new Error('Test already completed');

      const test = userTest.SkillTest;
      let totalPoints = 0;
      let earnedPoints = 0;
      const gradedAnswers = [];

      // تصحيح الإجابات
      for (const answer of answers) {
        const question = test.questions.find(q => q.id === answer.questionId);
        if (!question) continue;

        totalPoints += question.points || 1;
        let isCorrect = false;

        if (question.type === 'multiple_choice') {
          isCorrect = question.correct_option === answer.answer;
        } else if (question.type === 'true_false') {
          isCorrect = question.correct_answer === answer.answer;
        } else if (question.type === 'multiple_select') {
          const correctSet = new Set(question.correct_options);
          const answerSet = new Set(answer.answers);
          isCorrect = correctSet.size === answerSet.size && 
                      [...correctSet].every(c => answerSet.has(c));
        }

        if (isCorrect) {
          earnedPoints += question.points || 1;
        }

        gradedAnswers.push({
          questionId: question.id,
          userAnswer: answer.answer,
          isCorrect,
          pointsEarned: isCorrect ? (question.points || 1) : 0,
        });
      }

      const percentage = totalPoints > 0 ? Math.round((earnedPoints / totalPoints) * 100) : 0;
      const passed = percentage >= test.passing_score;

      await userTest.update({
        answers: gradedAnswers,
        score: earnedPoints,
        percentage: percentage,
        passed: passed,
        completed_at: new Date(),
      });

      // تحديث ملف المستقل إذا نجح
      if (passed) {
        await this.awardBadgeForTest(userTest.user_id, test);
        await this.updateFreelancerSkills(userTest.user_id, test);
      }

      // إرسال إشعار
      await NotificationService.createNotification({
        userId: userTest.user_id,
        type: 'skill_test_completed',
        title: passed ? '🎉 Test Passed!' : '📝 Test Completed',
        body: passed 
          ? `You passed the ${test.name} test with ${percentage}%! A badge has been added to your profile.`
          : `You scored ${percentage}% on the ${test.name} test. You can try again later.`,
        data: {
          testId: test.id,
          testName: test.name,
          score: percentage,
          passed: passed,
          screen: 'skill_tests',
        },
      });

      return {
        passed,
        percentage,
        totalPoints,
        earnedPoints,
        answers: gradedAnswers,
      };
    } catch (error) {
      console.error('Error submitting test:', error);
      throw error;
    }
  }

  // منح الشارة للاختبار
  static async awardBadgeForTest(userId, test) {
    try {
      if (!test.badge_id) return;

      // التحقق من عدم منح الشارة مسبقاً
      const existingBadge = await UserBadge.findOne({
        where: { user_id: userId, badge_id: test.badge_id },
      });

      if (existingBadge) return;

      const userBadge = await UserBadge.create({
        user_id: userId,
        badge_id: test.badge_id,
        awarded_at: new Date(),
        achievement_context: JSON.stringify({
          test_id: test.id,
          test_name: test.name,
          date: new Date(),
        }),
      });

      // تحديث UserSkillTest بأن الشارة منحت
      await UserSkillTest.update(
        { badge_awarded: true },
        { where: { user_id: userId, test_id: test.id, passed: true } }
      );

      return userBadge;
    } catch (error) {
      console.error('Error awarding badge for test:', error);
    }
  }

  // تحديث مهارات المستقل بناءً على الاختبار
  static async updateFreelancerSkills(userId, test) {
    try {
      const profile = await FreelancerProfile.findOne({
        where: { UserId: userId },
      });

      if (!profile) return;

      let skillsVerified = profile.skills_verified ? JSON.parse(profile.skills_verified) : [];
      let testScores = profile.test_scores ? JSON.parse(profile.test_scores) : [];

      // إضافة المهارة المختبرة
      if (!skillsVerified.includes(test.skill_category)) {
        skillsVerified.push(test.skill_category);
      }

      // إضافة نتيجة الاختبار
      testScores.push({
        test_id: test.id,
        test_name: test.name,
        skill: test.skill_category,
        date: new Date(),
        score: null, // سيتم تحديثه بعد التصحيح
      });

      await profile.update({
        skills_verified: JSON.stringify(skillsVerified),
        test_scores: JSON.stringify(testScores),
      });
    } catch (error) {
      console.error('Error updating freelancer skills:', error);
    }
  }

  // الحصول على نتائج المستخدم
  static async getUserTestResults(userId) {
    try {
      const results = await UserSkillTest.findAll({
        where: { user_id: userId },
        include: [
          {
            model: SkillTest,
            include: [{ model: Badge }],
          },
        ],
        order: [['completed_at', 'DESC']],
      });

      return results.map(r => ({
        id: r.id,
        test_name: r.SkillTest.name,
        skill_category: r.SkillTest.skill_category,
        percentage: r.percentage,
        passed: r.passed,
        completed_at: r.completed_at,
        badge: r.SkillTest.Badge,
        attempt_number: r.attempt_number,
      }));
    } catch (error) {
      console.error('Error getting user test results:', error);
      return [];
    }
  }

  // الحصول على إحصائيات الاختبارات للمستخدم
  static async getUserTestStats(userId) {
    try {
      const results = await UserSkillTest.findAll({
        where: { user_id: userId },
        include: [{ model: SkillTest }],
      });

      const totalTests = results.length;
      const passedTests = results.filter(r => r.passed).length;
      const averageScore = totalTests > 0 
        ? Math.round(results.reduce((sum, r) => sum + r.percentage, 0) / totalTests)
        : 0;

      // تجميع حسب فئة المهارات
      const skillsStats = {};
      results.forEach(r => {
        const skill = r.SkillTest.skill_category;
        if (!skillsStats[skill]) {
          skillsStats[skill] = { total: 0, passed: 0, bestScore: 0 };
        }
        skillsStats[skill].total++;
        if (r.passed) skillsStats[skill].passed++;
        if (r.percentage > skillsStats[skill].bestScore) {
          skillsStats[skill].bestScore = r.percentage;
        }
      });

      return {
        totalTests,
        passedTests,
        averageScore,
        passRate: totalTests > 0 ? Math.round((passedTests / totalTests) * 100) : 0,
        skillsStats,
      };
    } catch (error) {
      console.error('Error getting user test stats:', error);
      return {
        totalTests: 0,
        passedTests: 0,
        averageScore: 0,
        passRate: 0,
        skillsStats: {},
      };
    }
  }

  // إنشاء اختبار جديد (للمشرفين)
  static async createTest(testData) {
    try {
      const test = await SkillTest.create({
        name: testData.name,
        slug: testData.slug,
        description: testData.description,
        skill_category: testData.skill_category,
        difficulty: testData.difficulty,
        questions: testData.questions,
        passing_score: testData.passing_score || 70,
        time_limit_minutes: testData.time_limit_minutes || 30,
        max_attempts: testData.max_attempts || 3,
        badge_id: testData.badge_id,
      });

      return test;
    } catch (error) {
      console.error('Error creating test:', error);
      throw error;
    }
  }
}

export default SkillTestService;
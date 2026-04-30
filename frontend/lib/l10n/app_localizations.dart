import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Freelancer Platform'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @findWork.
  ///
  /// In en, this message translates to:
  /// **'Find Work'**
  String get findWork;

  /// No description provided for @myProposals.
  ///
  /// In en, this message translates to:
  /// **'My Proposals'**
  String get myProposals;

  /// No description provided for @myProjects.
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get myProjects;

  /// No description provided for @contracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contracts;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @financial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get financial;

  /// No description provided for @advancedSearch.
  ///
  /// In en, this message translates to:
  /// **'Advanced Search'**
  String get advancedSearch;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @freelancer.
  ///
  /// In en, this message translates to:
  /// **'Freelancer'**
  String get freelancer;

  /// No description provided for @jobSuccessScore.
  ///
  /// In en, this message translates to:
  /// **'JSS'**
  String get jobSuccessScore;

  /// No description provided for @activeProjects.
  ///
  /// In en, this message translates to:
  /// **'Active Projects'**
  String get activeProjects;

  /// No description provided for @proposals.
  ///
  /// In en, this message translates to:
  /// **'Proposals'**
  String get proposals;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletion;

  /// No description provided for @trendingSkills.
  ///
  /// In en, this message translates to:
  /// **'Trending Skills 🔥'**
  String get trendingSkills;

  /// No description provided for @myPortfolio.
  ///
  /// In en, this message translates to:
  /// **'My Portfolio 🎨'**
  String get myPortfolio;

  /// No description provided for @skillTests.
  ///
  /// In en, this message translates to:
  /// **'Skill Tests 🏆'**
  String get skillTests;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Freelancer Premium'**
  String get premium;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Your schedule'**
  String get schedule;

  /// No description provided for @fullCalendar.
  ///
  /// In en, this message translates to:
  /// **'Full calendar'**
  String get fullCalendar;

  /// No description provided for @bestMatches.
  ///
  /// In en, this message translates to:
  /// **'Best Matches'**
  String get bestMatches;

  /// No description provided for @mostRecent.
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get mostRecent;

  /// No description provided for @savedJobs.
  ///
  /// In en, this message translates to:
  /// **'Saved Jobs'**
  String get savedJobs;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @switchTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark theme'**
  String get switchTheme;

  /// No description provided for @useSystemTheme.
  ///
  /// In en, this message translates to:
  /// **'Use System Theme'**
  String get useSystemTheme;

  /// No description provided for @followSystemTheme.
  ///
  /// In en, this message translates to:
  /// **'Follow system theme settings'**
  String get followSystemTheme;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @updatePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updatePersonalInfo;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get updatePassword;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @manageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get manageNotifications;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @getHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get getHelpSupport;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @readTerms.
  ///
  /// In en, this message translates to:
  /// **'Read our terms and conditions'**
  String get readTerms;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @readPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacy;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate this app on the store'**
  String get rateApp;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgrade;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get noImage;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @reviewsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Reviews will appear here once completed projects are rated'**
  String get reviewsWillAppearHere;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @positive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get positive;

  /// No description provided for @negative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get negative;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @foundThisHelpful.
  ///
  /// In en, this message translates to:
  /// **'found this helpful'**
  String get foundThisHelpful;

  /// No description provided for @responseFromSeller.
  ///
  /// In en, this message translates to:
  /// **'Response from seller:'**
  String get responseFromSeller;

  /// No description provided for @ratingDistribution.
  ///
  /// In en, this message translates to:
  /// **'Rating Distribution'**
  String get ratingDistribution;

  /// No description provided for @ratingSummary.
  ///
  /// In en, this message translates to:
  /// **'Rating Summary'**
  String get ratingSummary;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @withComments.
  ///
  /// In en, this message translates to:
  /// **'With Comments'**
  String get withComments;

  /// No description provided for @withReplies.
  ///
  /// In en, this message translates to:
  /// **'With Replies'**
  String get withReplies;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @reviewDetails.
  ///
  /// In en, this message translates to:
  /// **'Review Details'**
  String get reviewDetails;

  /// No description provided for @replyToReview.
  ///
  /// In en, this message translates to:
  /// **'Reply to Review'**
  String get replyToReview;

  /// No description provided for @alreadyMarkedHelpful.
  ///
  /// In en, this message translates to:
  /// **'You already marked this as helpful'**
  String get alreadyMarkedHelpful;

  /// No description provided for @thanksForFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get thanksForFeedback;

  /// No description provided for @replyAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reply added successfully'**
  String get replyAddedSuccess;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @sellerResponse.
  ///
  /// In en, this message translates to:
  /// **'Seller Response'**
  String get sellerResponse;

  /// No description provided for @outOf5.
  ///
  /// In en, this message translates to:
  /// **'out of 5'**
  String get outOf5;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @communication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @youFoundThisHelpful.
  ///
  /// In en, this message translates to:
  /// **'You found this helpful'**
  String get youFoundThisHelpful;

  /// No description provided for @wasThisReviewHelpful.
  ///
  /// In en, this message translates to:
  /// **'Was this review helpful?'**
  String get wasThisReviewHelpful;

  /// No description provided for @errorLoadingProjects.
  ///
  /// In en, this message translates to:
  /// **'Error loading projects'**
  String get errorLoadingProjects;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @budgetLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Budget: Low to High'**
  String get budgetLowToHigh;

  /// No description provided for @budgetHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Budget: High to Low'**
  String get budgetHighToLow;

  /// No description provided for @durationShortestFirst.
  ///
  /// In en, this message translates to:
  /// **'Duration: Shortest First'**
  String get durationShortestFirst;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @unknownClient.
  ///
  /// In en, this message translates to:
  /// **'Unknown Client'**
  String get unknownClient;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @remote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remote;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'d ago'**
  String get daysAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get hoursAgo;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @searchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects...'**
  String get searchProjects;

  /// No description provided for @projectsFound.
  ///
  /// In en, this message translates to:
  /// **'projects found'**
  String get projectsFound;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @noProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get noProjectsFound;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @mobileDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Mobile Development'**
  String get mobileDevelopment;

  /// No description provided for @webDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Web Development'**
  String get webDevelopment;

  /// No description provided for @backendDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Backend Development'**
  String get backendDevelopment;

  /// No description provided for @uiUxDesign.
  ///
  /// In en, this message translates to:
  /// **'UI/UX Design'**
  String get uiUxDesign;

  /// No description provided for @graphicDesign.
  ///
  /// In en, this message translates to:
  /// **'Graphic Design'**
  String get graphicDesign;

  /// No description provided for @contentWriting.
  ///
  /// In en, this message translates to:
  /// **'Content Writing'**
  String get contentWriting;

  /// No description provided for @digitalMarketing.
  ///
  /// In en, this message translates to:
  /// **'Digital Marketing'**
  String get digitalMarketing;

  /// No description provided for @devOps.
  ///
  /// In en, this message translates to:
  /// **'DevOps'**
  String get devOps;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @durationLongestFirst.
  ///
  /// In en, this message translates to:
  /// **'Duration: Longest First'**
  String get durationLongestFirst;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search error'**
  String get searchError;

  /// No description provided for @saveSearchFilter.
  ///
  /// In en, this message translates to:
  /// **'Save Search Filter'**
  String get saveSearchFilter;

  /// No description provided for @filterName.
  ///
  /// In en, this message translates to:
  /// **'Filter Name'**
  String get filterName;

  /// No description provided for @filterHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., High Budget Flutter Jobs'**
  String get filterHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @filterSaved.
  ///
  /// In en, this message translates to:
  /// **'Filter saved successfully'**
  String get filterSaved;

  /// No description provided for @errorSavingFilter.
  ///
  /// In en, this message translates to:
  /// **'Error saving filter'**
  String get errorSavingFilter;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @saveThisSearch.
  ///
  /// In en, this message translates to:
  /// **'Save this search'**
  String get saveThisSearch;

  /// No description provided for @adjustYourFilters.
  ///
  /// In en, this message translates to:
  /// **'Adjust your search filters'**
  String get adjustYourFilters;

  /// No description provided for @savedSearches.
  ///
  /// In en, this message translates to:
  /// **'Saved Searches'**
  String get savedSearches;

  /// No description provided for @projectAlerts.
  ///
  /// In en, this message translates to:
  /// **'Project Alerts'**
  String get projectAlerts;

  /// No description provided for @createNewAlert.
  ///
  /// In en, this message translates to:
  /// **'Create New Alert'**
  String get createNewAlert;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @deleteFilter.
  ///
  /// In en, this message translates to:
  /// **'Delete Filter'**
  String get deleteFilter;

  /// No description provided for @deleteFilterQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteFilterQuestion;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @filterDeleted.
  ///
  /// In en, this message translates to:
  /// **'Filter deleted'**
  String get filterDeleted;

  /// No description provided for @alertDeleted.
  ///
  /// In en, this message translates to:
  /// **'Alert deleted'**
  String get alertDeleted;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @createProjectAlert.
  ///
  /// In en, this message translates to:
  /// **'Create Project Alert'**
  String get createProjectAlert;

  /// No description provided for @alertName.
  ///
  /// In en, this message translates to:
  /// **'Alert Name'**
  String get alertName;

  /// No description provided for @keywordsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Keywords (comma separated)'**
  String get keywordsCommaSeparated;

  /// No description provided for @keywordsHint.
  ///
  /// In en, this message translates to:
  /// **'flutter, mobile, app'**
  String get keywordsHint;

  /// No description provided for @skillsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Skills (comma separated)'**
  String get skillsCommaSeparated;

  /// No description provided for @alertCreated.
  ///
  /// In en, this message translates to:
  /// **'Alert created successfully'**
  String get alertCreated;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites!'**
  String get addedToFavorites;

  /// No description provided for @anyKeywords.
  ///
  /// In en, this message translates to:
  /// **'Any keywords'**
  String get anyKeywords;

  /// No description provided for @avatarUploaded.
  ///
  /// In en, this message translates to:
  /// **'Avatar uploaded successfully'**
  String get avatarUploaded;

  /// No description provided for @errorUploadingAvatar.
  ///
  /// In en, this message translates to:
  /// **'Error uploading avatar'**
  String get errorUploadingAvatar;

  /// No description provided for @uploadCV.
  ///
  /// In en, this message translates to:
  /// **'Upload CV'**
  String get uploadCV;

  /// No description provided for @updateCV.
  ///
  /// In en, this message translates to:
  /// **'Update CV'**
  String get updateCV;

  /// No description provided for @errorUploadingCV.
  ///
  /// In en, this message translates to:
  /// **'Error uploading CV'**
  String get errorUploadingCV;

  /// No description provided for @cvAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'✅ CV analyzed! {count} skills found'**
  String cvAnalyzed(Object count);

  /// No description provided for @cvAnalyzed_plural.
  ///
  /// In en, this message translates to:
  /// **'✅ CV analyzed! {count} skills found'**
  String cvAnalyzed_plural(Object count);

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied'**
  String get locationPermissionsDenied;

  /// No description provided for @locationPermissionsDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied'**
  String get locationPermissionsDeniedForever;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully'**
  String get locationUpdated;

  /// No description provided for @errorGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting location'**
  String get errorGettingLocation;

  /// No description provided for @errorSavingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error saving profile'**
  String get errorSavingProfile;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Tagline'**
  String get tagline;

  /// No description provided for @taglineHint.
  ///
  /// In en, this message translates to:
  /// **'Short headline (shown to clients)'**
  String get taglineHint;

  /// No description provided for @professionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Professional Title'**
  String get professionalTitle;

  /// No description provided for @professionalTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Senior Flutter Developer'**
  String get professionalTitleHint;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get bioHint;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @mapPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map preview unavailable'**
  String get mapPreviewUnavailable;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @addSkill.
  ///
  /// In en, this message translates to:
  /// **'Add a skill'**
  String get addSkill;

  /// No description provided for @noSkillsAdded.
  ///
  /// In en, this message translates to:
  /// **'No skills added yet'**
  String get noSkillsAdded;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @addLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add a language'**
  String get addLanguage;

  /// No description provided for @noLanguagesAdded.
  ///
  /// In en, this message translates to:
  /// **'No languages added yet'**
  String get noLanguagesAdded;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @degree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get degree;

  /// No description provided for @institution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @noEducationAdded.
  ///
  /// In en, this message translates to:
  /// **'No education added yet'**
  String get noEducationAdded;

  /// No description provided for @certifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @certificationName.
  ///
  /// In en, this message translates to:
  /// **'Certification name'**
  String get certificationName;

  /// No description provided for @issuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get issuer;

  /// No description provided for @noCertificationsAdded.
  ///
  /// In en, this message translates to:
  /// **'No certifications added yet'**
  String get noCertificationsAdded;

  /// No description provided for @socialLinks.
  ///
  /// In en, this message translates to:
  /// **'Social & Professional Links'**
  String get socialLinks;

  /// No description provided for @portfolioWebsite.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Website'**
  String get portfolioWebsite;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @linkedin.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkedin;

  /// No description provided for @behance.
  ///
  /// In en, this message translates to:
  /// **'Behance / Dribbble'**
  String get behance;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @fullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get fullTime;

  /// No description provided for @partTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get partTime;

  /// No description provided for @asNeeded.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get asNeeded;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @weeklyHours.
  ///
  /// In en, this message translates to:
  /// **'Weekly hours (available)'**
  String get weeklyHours;

  /// No description provided for @yearsOfExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get yearsOfExperience;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @aiAnalysisComplete.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis Complete!'**
  String get aiAnalysisComplete;

  /// No description provided for @extractedFromCV.
  ///
  /// In en, this message translates to:
  /// **'Extracted from your CV'**
  String get extractedFromCV;

  /// No description provided for @skillsCount.
  ///
  /// In en, this message translates to:
  /// **'skills'**
  String get skillsCount;

  /// No description provided for @languagesCount.
  ///
  /// In en, this message translates to:
  /// **'languages'**
  String get languagesCount;

  /// No description provided for @educationCount.
  ///
  /// In en, this message translates to:
  /// **'education'**
  String get educationCount;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @errorLoadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error loading favorites'**
  String get errorLoadingFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @removeFromFavoritesConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{projectTitle}\" from favorites?'**
  String removeFromFavoritesConfirmation(String projectTitle);

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @saveProjectsByTappingHeart.
  ///
  /// In en, this message translates to:
  /// **'Save projects you like by tapping the heart icon'**
  String get saveProjectsByTappingHeart;

  /// No description provided for @browseProjects.
  ///
  /// In en, this message translates to:
  /// **'Browse Projects'**
  String get browseProjects;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @financialDashboard.
  ///
  /// In en, this message translates to:
  /// **'Financial Dashboard'**
  String get financialDashboard;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get downloadReport;

  /// No description provided for @errorLoadingFinancialData.
  ///
  /// In en, this message translates to:
  /// **'Error loading financial data'**
  String get errorLoadingFinancialData;

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully'**
  String get reportGenerated;

  /// No description provided for @errorGeneratingReport.
  ///
  /// In en, this message translates to:
  /// **'Error generating report'**
  String get errorGeneratingReport;

  /// No description provided for @withdrawFunds.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get withdrawFunds;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @withdrawalMethod.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Method'**
  String get withdrawalMethod;

  /// No description provided for @paypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get paypal;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @stripe.
  ///
  /// In en, this message translates to:
  /// **'Stripe'**
  String get stripe;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @withdrawalRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'✅ Withdrawal request submitted'**
  String get withdrawalRequestSubmitted;

  /// No description provided for @noFinancialData.
  ///
  /// In en, this message translates to:
  /// **'No financial data available'**
  String get noFinancialData;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @platformFees.
  ///
  /// In en, this message translates to:
  /// **'Platform Fees'**
  String get platformFees;

  /// No description provided for @withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get withdrawn;

  /// No description provided for @totalWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Total withdrawn'**
  String get totalWithdrawn;

  /// No description provided for @netEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net Earnings'**
  String get netEarnings;

  /// No description provided for @availableToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Available to withdraw'**
  String get availableToWithdraw;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @noDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data available for this period'**
  String get noDataForPeriod;

  /// No description provided for @earningsOverview.
  ///
  /// In en, this message translates to:
  /// **'Earnings Overview'**
  String get earningsOverview;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentReceived;

  /// No description provided for @paymentSent.
  ///
  /// In en, this message translates to:
  /// **'Payment Sent'**
  String get paymentSent;

  /// No description provided for @withdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get withdrawal;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @platformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee'**
  String get platformFee;

  /// No description provided for @bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get bonus;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @noAnalyticsData.
  ///
  /// In en, this message translates to:
  /// **'No analytics data available'**
  String get noAnalyticsData;

  /// No description provided for @topProjects.
  ///
  /// In en, this message translates to:
  /// **'Top Projects'**
  String get topProjects;

  /// No description provided for @earningsByCategory.
  ///
  /// In en, this message translates to:
  /// **'Earnings by Category'**
  String get earningsByCategory;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @projectedEarnings.
  ///
  /// In en, this message translates to:
  /// **'Projected Earnings'**
  String get projectedEarnings;

  /// No description provided for @projectedEarningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Next 3 months based on your history'**
  String get projectedEarningsSubtitle;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @submitWork.
  ///
  /// In en, this message translates to:
  /// **'Submit Work'**
  String get submitWork;

  /// No description provided for @submitWorkConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit this work for review?'**
  String get submitWorkConfirmation;

  /// No description provided for @workSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Work submitted successfully!'**
  String get workSubmittedSuccess;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent!'**
  String get messageSent;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @untitledProject.
  ///
  /// In en, this message translates to:
  /// **'Untitled Project'**
  String get untitledProject;

  /// No description provided for @projectProgress.
  ///
  /// In en, this message translates to:
  /// **'Project Progress'**
  String get projectProgress;

  /// No description provided for @openWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Open Workspace'**
  String get openWorkspace;

  /// No description provided for @openContract.
  ///
  /// In en, this message translates to:
  /// **'Open Contract'**
  String get openContract;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loadingProjects.
  ///
  /// In en, this message translates to:
  /// **'Loading your projects...'**
  String get loadingProjects;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No Projects Yet'**
  String get noProjectsYet;

  /// No description provided for @acceptedProposalsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your accepted proposals will appear here'**
  String get acceptedProposalsWillAppear;

  /// No description provided for @viewMyProposals.
  ///
  /// In en, this message translates to:
  /// **'View My Proposals'**
  String get viewMyProposals;

  /// No description provided for @errorLoadingProposals.
  ///
  /// In en, this message translates to:
  /// **'Error loading proposals'**
  String get errorLoadingProposals;

  /// No description provided for @proposalsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Proposals This Month'**
  String get proposalsThisMonth;

  /// No description provided for @proposalLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached your proposal limit. Upgrade to submit more.'**
  String get proposalLimitReached;

  /// No description provided for @proposalsRemaining.
  ///
  /// In en, this message translates to:
  /// **'✨ You have {count} proposal remaining this month.'**
  String proposalsRemaining(int count);

  /// No description provided for @proposalsRemaining_plural.
  ///
  /// In en, this message translates to:
  /// **'✨ You have {count} proposals remaining this month.'**
  String proposalsRemaining_plural(Object count);

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get rejected;

  /// No description provided for @unknownProject.
  ///
  /// In en, this message translates to:
  /// **'Unknown Project'**
  String get unknownProject;

  /// No description provided for @noMessageProvided.
  ///
  /// In en, this message translates to:
  /// **'No message provided'**
  String get noMessageProvided;

  /// No description provided for @startWorking.
  ///
  /// In en, this message translates to:
  /// **'Start Working'**
  String get startWorking;

  /// No description provided for @noProposalsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No proposals in this category'**
  String get noProposalsInCategory;

  /// No description provided for @loadingProposals.
  ///
  /// In en, this message translates to:
  /// **'Loading proposals...'**
  String get loadingProposals;

  /// No description provided for @noProposalsYet.
  ///
  /// In en, this message translates to:
  /// **'No Proposals Yet'**
  String get noProposalsYet;

  /// No description provided for @browseProjectsAndSubmitProposal.
  ///
  /// In en, this message translates to:
  /// **'Browse projects and submit your first proposal'**
  String get browseProjectsAndSubmitProposal;

  /// No description provided for @findProjects.
  ///
  /// In en, this message translates to:
  /// **'Find Projects'**
  String get findProjects;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @errorLoadingProjectDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading project details'**
  String get errorLoadingProjectDetails;

  /// No description provided for @projectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project not found'**
  String get projectNotFound;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @aiSmartPricingAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Smart Pricing Analysis'**
  String get aiSmartPricingAnalysis;

  /// No description provided for @recommendedPrice.
  ///
  /// In en, this message translates to:
  /// **'Recommended Price'**
  String get recommendedPrice;

  /// No description provided for @estHours.
  ///
  /// In en, this message translates to:
  /// **'Est. Hours'**
  String get estHours;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hrs'**
  String get hours;

  /// No description provided for @baseRate.
  ///
  /// In en, this message translates to:
  /// **'Base Rate'**
  String get baseRate;

  /// No description provided for @complexity.
  ///
  /// In en, this message translates to:
  /// **'Complexity'**
  String get complexity;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @requiredSkills.
  ///
  /// In en, this message translates to:
  /// **'Required Skills'**
  String get requiredSkills;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @proposalsRemainingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Proposals remaining this month: {count}'**
  String proposalsRemainingThisMonth(int count);

  /// No description provided for @upgradeToSendMoreProposals.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to send more proposals'**
  String get upgradeToSendMoreProposals;

  /// No description provided for @submitProposal.
  ///
  /// In en, this message translates to:
  /// **'Submit Proposal'**
  String get submitProposal;

  /// No description provided for @proposalSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Proposal submitted successfully!'**
  String get proposalSubmittedSuccess;

  /// No description provided for @alreadySubmittedProposal.
  ///
  /// In en, this message translates to:
  /// **'You have already submitted a proposal for this project'**
  String get alreadySubmittedProposal;

  /// No description provided for @projectStatus.
  ///
  /// In en, this message translates to:
  /// **'This project is {status}'**
  String projectStatus(String status);

  /// No description provided for @projectStatusWithContract.
  ///
  /// In en, this message translates to:
  /// **'This project is {status}. Your workspace is in the contract.'**
  String projectStatusWithContract(String status);

  /// No description provided for @restoredProposalDraft.
  ///
  /// In en, this message translates to:
  /// **'Restored your saved proposal draft'**
  String get restoredProposalDraft;

  /// No description provided for @aiPriceApplied.
  ///
  /// In en, this message translates to:
  /// **'AI recommended price applied!'**
  String get aiPriceApplied;

  /// No description provided for @aiSuggestedMilestones.
  ///
  /// In en, this message translates to:
  /// **'AI Suggested Milestones'**
  String get aiSuggestedMilestones;

  /// No description provided for @aiMilestonesDescription.
  ///
  /// In en, this message translates to:
  /// **'Based on your project analysis, here are recommended milestones:'**
  String get aiMilestonesDescription;

  /// No description provided for @applyMilestones.
  ///
  /// In en, this message translates to:
  /// **'Apply Milestones'**
  String get applyMilestones;

  /// No description provided for @aiMilestonesApplied.
  ///
  /// In en, this message translates to:
  /// **'AI milestones applied! You can edit them below.'**
  String get aiMilestonesApplied;

  /// No description provided for @milestoneAmountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Total milestone amounts (\${total}) does not match your price (\${price})'**
  String milestoneAmountMismatch(Object price, Object total);

  /// No description provided for @milestoneAmountMismatch_plural.
  ///
  /// In en, this message translates to:
  /// **'Total milestone amounts (\${total}) does not match your price (\${price})'**
  String milestoneAmountMismatch_plural(Object price, Object total);

  /// No description provided for @proposalLimitReachedUpgrade.
  ///
  /// In en, this message translates to:
  /// **'You have reached your proposal limit. Please upgrade to submit more proposals.'**
  String get proposalLimitReachedUpgrade;

  /// No description provided for @errorSubmittingProposal.
  ///
  /// In en, this message translates to:
  /// **'Error submitting proposal'**
  String get errorSubmittingProposal;

  /// No description provided for @fillProposalFieldsFirst.
  ///
  /// In en, this message translates to:
  /// **'Fill price, delivery time, and a meaningful cover letter first'**
  String get fillProposalFieldsFirst;

  /// No description provided for @couldNotAnalyzeProposal.
  ///
  /// In en, this message translates to:
  /// **'Could not analyze proposal'**
  String get couldNotAnalyzeProposal;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed'**
  String get analysisFailed;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get draftSaved;

  /// No description provided for @proposalAutosaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Proposal autosaves on this device while you edit.'**
  String get proposalAutosaveMessage;

  /// No description provided for @youAreApplyingFor.
  ///
  /// In en, this message translates to:
  /// **'You\'re applying for:'**
  String get youAreApplyingFor;

  /// No description provided for @yourProposal.
  ///
  /// In en, this message translates to:
  /// **'Your Proposal'**
  String get yourProposal;

  /// No description provided for @fillProposalDetails.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details below to submit your proposal'**
  String get fillProposalDetails;

  /// No description provided for @yourPrice.
  ///
  /// In en, this message translates to:
  /// **'Your Price (\$)'**
  String get yourPrice;

  /// No description provided for @enterYourPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter your proposed price'**
  String get enterYourPrice;

  /// No description provided for @pleaseEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter your price'**
  String get pleaseEnterPrice;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @priceGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than 0'**
  String get priceGreaterThanZero;

  /// No description provided for @deliveryTimeDays.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time (days)'**
  String get deliveryTimeDays;

  /// No description provided for @howManyDays.
  ///
  /// In en, this message translates to:
  /// **'How many days you need?'**
  String get howManyDays;

  /// No description provided for @pleaseEnterDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Please enter delivery time'**
  String get pleaseEnterDeliveryTime;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @deliveryTimeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Delivery time must be greater than 0'**
  String get deliveryTimeGreaterThanZero;

  /// No description provided for @paymentMilestones.
  ///
  /// In en, this message translates to:
  /// **'Payment Milestones'**
  String get paymentMilestones;

  /// No description provided for @aiGenerated.
  ///
  /// In en, this message translates to:
  /// **'AI Generated'**
  String get aiGenerated;

  /// No description provided for @defineMilestones.
  ///
  /// In en, this message translates to:
  /// **'Define the project phases and payment schedule'**
  String get defineMilestones;

  /// No description provided for @coverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get coverLetter;

  /// No description provided for @coverLetterHint.
  ///
  /// In en, this message translates to:
  /// **'Explain why you\'re the best candidate for this project...\n- Your relevant experience\n- How you\'ll approach the project\n- Any questions you have'**
  String get coverLetterHint;

  /// No description provided for @pleaseWriteCoverLetter.
  ///
  /// In en, this message translates to:
  /// **'Please write a cover letter'**
  String get pleaseWriteCoverLetter;

  /// No description provided for @coverLetterMinLength.
  ///
  /// In en, this message translates to:
  /// **'Cover letter should be at least 50 characters'**
  String get coverLetterMinLength;

  /// No description provided for @analyzingProposal.
  ///
  /// In en, this message translates to:
  /// **'Analyzing proposal...'**
  String get analyzingProposal;

  /// No description provided for @analyzeProposalQuality.
  ///
  /// In en, this message translates to:
  /// **'Analyze Proposal Quality (AI)'**
  String get analyzeProposalQuality;

  /// No description provided for @proposalScore.
  ///
  /// In en, this message translates to:
  /// **'Proposal Score'**
  String get proposalScore;

  /// No description provided for @strengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get strengths;

  /// No description provided for @improve.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get improve;

  /// No description provided for @priceWithinBudget.
  ///
  /// In en, this message translates to:
  /// **'Your price is within the project budget'**
  String get priceWithinBudget;

  /// No description provided for @priceAboveBudget.
  ///
  /// In en, this message translates to:
  /// **'Your price is above the project budget. Make sure to justify this in your cover letter.'**
  String get priceAboveBudget;

  /// No description provided for @paymentScheduleSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Schedule Summary'**
  String get paymentScheduleSummary;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'By submitting, you agree to our Terms of Service'**
  String get agreeToTerms;

  /// No description provided for @aiSmartPricing.
  ///
  /// In en, this message translates to:
  /// **'AI Smart Pricing'**
  String get aiSmartPricing;

  /// No description provided for @useRecommendedPrice.
  ///
  /// In en, this message translates to:
  /// **'Use Recommended Price'**
  String get useRecommendedPrice;

  /// No description provided for @aiMilestoneSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Milestone Suggestions'**
  String get aiMilestoneSuggestions;

  /// No description provided for @viewAndApplyMilestones.
  ///
  /// In en, this message translates to:
  /// **'View & Apply AI Milestones'**
  String get viewAndApplyMilestones;

  /// No description provided for @plusMoreMilestones.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more milestones'**
  String plusMoreMilestones(int count);

  /// No description provided for @submittingWorkFor.
  ///
  /// In en, this message translates to:
  /// **'Submitting work for: {projectTitle}'**
  String submittingWorkFor(String projectTitle);

  /// No description provided for @submissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission Title'**
  String get submissionTitle;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @describeYourWork.
  ///
  /// In en, this message translates to:
  /// **'Describe what you have completed...'**
  String get describeYourWork;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add Files'**
  String get addFiles;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @pleaseAddAtLeastOneFileOrLink.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one file or link'**
  String get pleaseAddAtLeastOneFileOrLink;

  /// No description provided for @errorSubmittingWork.
  ///
  /// In en, this message translates to:
  /// **'Error submitting work'**
  String get errorSubmittingWork;

  /// No description provided for @boostYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Boost Your Profile'**
  String get boostYourProfile;

  /// No description provided for @errorLoadingPrices.
  ///
  /// In en, this message translates to:
  /// **'Error loading prices'**
  String get errorLoadingPrices;

  /// No description provided for @featurePurchasedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Feature purchased successfully!'**
  String get featurePurchasedSuccess;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get purchaseFailed;

  /// No description provided for @noProjectsToHighlight.
  ///
  /// In en, this message translates to:
  /// **'You have no projects to highlight'**
  String get noProjectsToHighlight;

  /// No description provided for @selectProject.
  ///
  /// In en, this message translates to:
  /// **'Select a project'**
  String get selectProject;

  /// No description provided for @featureYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Feature Your Profile'**
  String get featureYourProfile;

  /// No description provided for @featureYourProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Get featured at the top of search results for 7 days'**
  String get featureYourProfileDesc;

  /// No description provided for @highlightYourProject.
  ///
  /// In en, this message translates to:
  /// **'Highlight Your Project'**
  String get highlightYourProject;

  /// No description provided for @highlightYourProjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Make your project stand out with a highlight badge'**
  String get highlightYourProjectDesc;

  /// No description provided for @skillCertificate.
  ///
  /// In en, this message translates to:
  /// **'Skill Certificate'**
  String get skillCertificate;

  /// No description provided for @skillCertificateDesc.
  ///
  /// In en, this message translates to:
  /// **'Get certified and earn a verified badge'**
  String get skillCertificateDesc;

  /// No description provided for @aiResumeReview.
  ///
  /// In en, this message translates to:
  /// **'AI Resume Review'**
  String get aiResumeReview;

  /// No description provided for @aiResumeReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Get professional feedback on your resume'**
  String get aiResumeReviewDesc;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @contractProgress.
  ///
  /// In en, this message translates to:
  /// **'Contract progress'**
  String get contractProgress;

  /// No description provided for @couldNotLoadProgress.
  ///
  /// In en, this message translates to:
  /// **'Could not load progress'**
  String get couldNotLoadProgress;

  /// No description provided for @milestoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Milestone updated'**
  String get milestoneUpdated;

  /// No description provided for @couldNotApproveMilestone.
  ///
  /// In en, this message translates to:
  /// **'Could not approve milestone'**
  String get couldNotApproveMilestone;

  /// No description provided for @workApproved.
  ///
  /// In en, this message translates to:
  /// **'Work approved'**
  String get workApproved;

  /// No description provided for @approvalFailed.
  ///
  /// In en, this message translates to:
  /// **'Approval failed'**
  String get approvalFailed;

  /// No description provided for @requestRevision.
  ///
  /// In en, this message translates to:
  /// **'Request revision'**
  String get requestRevision;

  /// No description provided for @whatShouldBeChanged.
  ///
  /// In en, this message translates to:
  /// **'What should be changed?'**
  String get whatShouldBeChanged;

  /// No description provided for @revisionRequested.
  ///
  /// In en, this message translates to:
  /// **'Revision requested'**
  String get revisionRequested;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed'**
  String get requestFailed;

  /// No description provided for @addedToPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Added to portfolio'**
  String get addedToPortfolio;

  /// No description provided for @couldNotAddToPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Could not add to portfolio'**
  String get couldNotAddToPortfolio;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @contractNumber.
  ///
  /// In en, this message translates to:
  /// **'Contract #{id}'**
  String contractNumber(int id);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @escrow.
  ///
  /// In en, this message translates to:
  /// **'Escrow'**
  String get escrow;

  /// No description provided for @pool.
  ///
  /// In en, this message translates to:
  /// **'Pool'**
  String get pool;

  /// No description provided for @coupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get coupon;

  /// No description provided for @dollar.
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get dollar;

  /// No description provided for @commissionPreview.
  ///
  /// In en, this message translates to:
  /// **'Commission preview'**
  String get commissionPreview;

  /// No description provided for @planRateIndicative.
  ///
  /// In en, this message translates to:
  /// **'Plan rate (indicative)'**
  String get planRateIndicative;

  /// No description provided for @estPlatformFeeOnRelease.
  ///
  /// In en, this message translates to:
  /// **'Est. platform fee on release'**
  String get estPlatformFeeOnRelease;

  /// No description provided for @noPendingSteps.
  ///
  /// In en, this message translates to:
  /// **'No pending steps'**
  String get noPendingSteps;

  /// No description provided for @upToDateOnMilestones.
  ///
  /// In en, this message translates to:
  /// **'You are up to date on milestones and deliverables.'**
  String get upToDateOnMilestones;

  /// No description provided for @yourNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Your next steps'**
  String get yourNextSteps;

  /// No description provided for @approveMilestone.
  ///
  /// In en, this message translates to:
  /// **'Approve Milestone'**
  String get approveMilestone;

  /// No description provided for @reviewSubmission.
  ///
  /// In en, this message translates to:
  /// **'Review submission'**
  String get reviewSubmission;

  /// No description provided for @submitDeliverable.
  ///
  /// In en, this message translates to:
  /// **'Submit deliverable'**
  String get submitDeliverable;

  /// No description provided for @approveAndRelease.
  ///
  /// In en, this message translates to:
  /// **'Approve & Release'**
  String get approveAndRelease;

  /// No description provided for @approveWork.
  ///
  /// In en, this message translates to:
  /// **'Approve work'**
  String get approveWork;

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// No description provided for @milestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get milestone;

  /// No description provided for @deliverables.
  ///
  /// In en, this message translates to:
  /// **'Deliverables'**
  String get deliverables;

  /// No description provided for @submission.
  ///
  /// In en, this message translates to:
  /// **'Submission'**
  String get submission;

  /// No description provided for @addToPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Add to Portfolio'**
  String get addToPortfolio;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @contractAgreement.
  ///
  /// In en, this message translates to:
  /// **'Contract Agreement'**
  String get contractAgreement;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @contractNotFound.
  ///
  /// In en, this message translates to:
  /// **'Contract not found'**
  String get contractNotFound;

  /// No description provided for @signedOn.
  ///
  /// In en, this message translates to:
  /// **'Signed on'**
  String get signedOn;

  /// No description provided for @contractAmount.
  ///
  /// In en, this message translates to:
  /// **'Contract Amount'**
  String get contractAmount;

  /// No description provided for @aiOptimized.
  ///
  /// In en, this message translates to:
  /// **'AI Optimized'**
  String get aiOptimized;

  /// No description provided for @noMilestonesFound.
  ///
  /// In en, this message translates to:
  /// **'No milestones found for this contract'**
  String get noMilestonesFound;

  /// No description provided for @githubIntegration.
  ///
  /// In en, this message translates to:
  /// **'GitHub Integration'**
  String get githubIntegration;

  /// No description provided for @connectGithubRepository.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub Repository'**
  String get connectGithubRepository;

  /// No description provided for @trackProgressAndShowWork.
  ///
  /// In en, this message translates to:
  /// **'Track your progress and show your work'**
  String get trackProgressAndShowWork;

  /// No description provided for @connectRepository.
  ///
  /// In en, this message translates to:
  /// **'Connect Repository'**
  String get connectRepository;

  /// No description provided for @recentCommits.
  ///
  /// In en, this message translates to:
  /// **'Recent Commits'**
  String get recentCommits;

  /// No description provided for @commits.
  ///
  /// In en, this message translates to:
  /// **'commits'**
  String get commits;

  /// No description provided for @contractDocument.
  ///
  /// In en, this message translates to:
  /// **'Contract Document'**
  String get contractDocument;

  /// No description provided for @contractDocumentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Contract document not available'**
  String get contractDocumentNotAvailable;

  /// No description provided for @clientSignature.
  ///
  /// In en, this message translates to:
  /// **'Client Signature'**
  String get clientSignature;

  /// No description provided for @freelancerSignature.
  ///
  /// In en, this message translates to:
  /// **'Freelancer Signature'**
  String get freelancerSignature;

  /// No description provided for @enterCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a coupon code'**
  String get enterCouponCode;

  /// No description provided for @couponApplied.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied'**
  String get couponApplied;

  /// No description provided for @couldNotApplyCoupon.
  ///
  /// In en, this message translates to:
  /// **'Could not apply coupon'**
  String get couldNotApplyCoupon;

  /// No description provided for @couponRemoved.
  ///
  /// In en, this message translates to:
  /// **'Coupon removed'**
  String get couponRemoved;

  /// No description provided for @couldNotRemoveCoupon.
  ///
  /// In en, this message translates to:
  /// **'Could not remove coupon'**
  String get couldNotRemoveCoupon;

  /// No description provided for @errorLoadingContract.
  ///
  /// In en, this message translates to:
  /// **'Error loading contract'**
  String get errorLoadingContract;

  /// No description provided for @errorCreatingPayment.
  ///
  /// In en, this message translates to:
  /// **'Error creating payment'**
  String get errorCreatingPayment;

  /// No description provided for @contractSignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Contract signed successfully'**
  String get contractSignedSuccess;

  /// No description provided for @errorSigningContract.
  ///
  /// In en, this message translates to:
  /// **'Error signing contract'**
  String get errorSigningContract;

  /// No description provided for @awaitingSignatures.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Signatures'**
  String get awaitingSignatures;

  /// No description provided for @waitingForClientSignature.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Client Signature'**
  String get waitingForClientSignature;

  /// No description provided for @waitingForFreelancerSignature.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Freelancer Signature'**
  String get waitingForFreelancerSignature;

  /// No description provided for @contractActive.
  ///
  /// In en, this message translates to:
  /// **'Contract Active'**
  String get contractActive;

  /// No description provided for @contractCompleted.
  ///
  /// In en, this message translates to:
  /// **'Contract Completed'**
  String get contractCompleted;

  /// No description provided for @contractCancelled.
  ///
  /// In en, this message translates to:
  /// **'Contract Cancelled'**
  String get contractCancelled;

  /// No description provided for @connectGithub.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub'**
  String get connectGithub;

  /// No description provided for @connectGithubDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect your GitHub repository to track commits and show your progress to the client.'**
  String get connectGithubDescription;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @escrowFunded.
  ///
  /// In en, this message translates to:
  /// **'✅ Escrow Funded'**
  String get escrowFunded;

  /// No description provided for @paymentRequired.
  ///
  /// In en, this message translates to:
  /// **'💰 Payment Required'**
  String get paymentRequired;

  /// No description provided for @escrowFundedDescription.
  ///
  /// In en, this message translates to:
  /// **'The payment is secured in escrow. Milestone payments will be released upon approval.'**
  String get escrowFundedDescription;

  /// No description provided for @paymentRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'To activate this contract and start working, please deposit the contract amount into escrow.'**
  String get paymentRequiredDescription;

  /// No description provided for @contractCouponEscrow.
  ///
  /// In en, this message translates to:
  /// **'Contract coupon (escrow)'**
  String get contractCouponEscrow;

  /// No description provided for @applyBeforePaying.
  ///
  /// In en, this message translates to:
  /// **'Apply before paying'**
  String get applyBeforePaying;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @amountDueNow.
  ///
  /// In en, this message translates to:
  /// **'Amount due now'**
  String get amountDueNow;

  /// No description provided for @afterCoupon.
  ///
  /// In en, this message translates to:
  /// **'after coupon'**
  String get afterCoupon;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @paymentSecured.
  ///
  /// In en, this message translates to:
  /// **'Payment secured'**
  String get paymentSecured;

  /// No description provided for @inEscrow.
  ///
  /// In en, this message translates to:
  /// **'in escrow'**
  String get inEscrow;

  /// No description provided for @thankYouForRating.
  ///
  /// In en, this message translates to:
  /// **'✅ Thank you for your rating!'**
  String get thankYouForRating;

  /// No description provided for @rateThisExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate this experience'**
  String get rateThisExperience;

  /// No description provided for @waitingForOtherParty.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Other Party'**
  String get waitingForOtherParty;

  /// No description provided for @signContract.
  ///
  /// In en, this message translates to:
  /// **'Sign Contract'**
  String get signContract;

  /// No description provided for @contractActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Contract is active. You can now start working!'**
  String get contractActiveMessage;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid ✓'**
  String get paid;

  /// No description provided for @completedAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Completed - Awaiting Approval'**
  String get completedAwaitingApproval;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// No description provided for @updateProgress.
  ///
  /// In en, this message translates to:
  /// **'Update Progress'**
  String get updateProgress;

  /// No description provided for @requestChanges.
  ///
  /// In en, this message translates to:
  /// **'Request Changes'**
  String get requestChanges;

  /// No description provided for @paymentReleasedOn.
  ///
  /// In en, this message translates to:
  /// **'Payment released on'**
  String get paymentReleasedOn;

  /// No description provided for @milestoneMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'✅ Milestone marked as completed'**
  String get milestoneMarkedCompleted;

  /// No description provided for @errorCompletingMilestone.
  ///
  /// In en, this message translates to:
  /// **'Error completing milestone'**
  String get errorCompletingMilestone;

  /// No description provided for @approveMilestoneConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve \"{title}\"?'**
  String approveMilestoneConfirmation(String title);

  /// No description provided for @amountWillBeReleased.
  ///
  /// In en, this message translates to:
  /// **'\${amount} will be released to the freelancer'**
  String amountWillBeReleased(String amount);

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @milestoneApprovedPaymentReleased.
  ///
  /// In en, this message translates to:
  /// **'✅ Milestone approved and payment released'**
  String get milestoneApprovedPaymentReleased;

  /// No description provided for @errorApprovingMilestone.
  ///
  /// In en, this message translates to:
  /// **'Error approving milestone'**
  String get errorApprovingMilestone;

  /// No description provided for @explainWhatNeedsToBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Please explain what needs to be changed:'**
  String get explainWhatNeedsToBeChanged;

  /// No description provided for @describeChangesNeeded.
  ///
  /// In en, this message translates to:
  /// **'Describe the changes needed...'**
  String get describeChangesNeeded;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @revisionRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Revision request sent to freelancer'**
  String get revisionRequestSent;

  /// No description provided for @notSigned.
  ///
  /// In en, this message translates to:
  /// **'Not signed'**
  String get notSigned;

  /// No description provided for @previewSOW.
  ///
  /// In en, this message translates to:
  /// **'Preview SOW'**
  String get previewSOW;

  /// No description provided for @verificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'✅ Verification code sent'**
  String get verificationCodeSent;

  /// No description provided for @codeMustBe6Digits.
  ///
  /// In en, this message translates to:
  /// **'❌ Code must be 6 digits'**
  String get codeMustBe6Digits;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'❌ Invalid code'**
  String get invalidCode;

  /// No description provided for @maxAttemptsReached.
  ///
  /// In en, this message translates to:
  /// **'❌ Max attempts. Request new code'**
  String get maxAttemptsReached;

  /// No description provided for @errorGeneratingPDF.
  ///
  /// In en, this message translates to:
  /// **'Error generating PDF'**
  String get errorGeneratingPDF;

  /// No description provided for @viewPDF.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get viewPDF;

  /// No description provided for @downloadPDF.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPDF;

  /// No description provided for @sharePDF.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePDF;

  /// No description provided for @downloadingPDF.
  ///
  /// In en, this message translates to:
  /// **'Downloading PDF...'**
  String get downloadingPDF;

  /// No description provided for @errorDownloadingPDF.
  ///
  /// In en, this message translates to:
  /// **'Error downloading PDF'**
  String get errorDownloadingPDF;

  /// No description provided for @errorSharing.
  ///
  /// In en, this message translates to:
  /// **'Error sharing'**
  String get errorSharing;

  /// No description provided for @contractSignedSuccessViewSOW.
  ///
  /// In en, this message translates to:
  /// **'Contract signed successfully! View the SOW document:'**
  String get contractSignedSuccessViewSOW;

  /// No description provided for @contractSOWDocument.
  ///
  /// In en, this message translates to:
  /// **'Contract SOW Document'**
  String get contractSOWDocument;

  /// No description provided for @electronicContractSigning.
  ///
  /// In en, this message translates to:
  /// **'Electronic Contract Signing'**
  String get electronicContractSigning;

  /// No description provided for @verificationCodeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'A verification code has been sent to your email'**
  String get verificationCodeSentToEmail;

  /// No description provided for @codeValidFor.
  ///
  /// In en, this message translates to:
  /// **'Code valid for'**
  String get codeValidFor;

  /// No description provided for @generatingPDFDocument.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF document...'**
  String get generatingPDFDocument;

  /// No description provided for @confirmSignature.
  ///
  /// In en, this message translates to:
  /// **'Confirm Signature'**
  String get confirmSignature;

  /// No description provided for @waitSecondsToResend.
  ///
  /// In en, this message translates to:
  /// **'Wait {seconds}s to resend'**
  String waitSecondsToResend(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @aiGeneratedSOW.
  ///
  /// In en, this message translates to:
  /// **'AI-Generated SOW'**
  String get aiGeneratedSOW;

  /// No description provided for @aiGeneratedSOWDescription.
  ///
  /// In en, this message translates to:
  /// **'This document was generated by AI and is legally binding'**
  String get aiGeneratedSOWDescription;

  /// No description provided for @statementOfWorkPreview.
  ///
  /// In en, this message translates to:
  /// **'Statement of Work Preview'**
  String get statementOfWorkPreview;

  /// No description provided for @reviewBeforeSigning.
  ///
  /// In en, this message translates to:
  /// **'Please review the document before signing'**
  String get reviewBeforeSigning;

  /// No description provided for @sowContentWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'SOW content will appear here\n(HTML rendering)'**
  String get sowContentWillAppearHere;

  /// No description provided for @myContracts.
  ///
  /// In en, this message translates to:
  /// **'My Contracts'**
  String get myContracts;

  /// No description provided for @noContractsYet.
  ///
  /// In en, this message translates to:
  /// **'No contracts yet'**
  String get noContractsYet;

  /// No description provided for @submitFinalWork.
  ///
  /// In en, this message translates to:
  /// **'Submit Final Work'**
  String get submitFinalWork;

  /// No description provided for @submitWorkForMilestones.
  ///
  /// In en, this message translates to:
  /// **'Submit Work for Milestones:'**
  String get submitWorkForMilestones;

  /// No description provided for @signed.
  ///
  /// In en, this message translates to:
  /// **'Signed ✓'**
  String get signed;

  /// No description provided for @waitingForFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Freelancer'**
  String get waitingForFreelancer;

  /// No description provided for @waitingForClient.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Client'**
  String get waitingForClient;

  /// No description provided for @signNow.
  ///
  /// In en, this message translates to:
  /// **'Sign Now'**
  String get signNow;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Title'**
  String get reminderTitle;

  /// No description provided for @reminderTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Submit milestone 1'**
  String get reminderTitleHint;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional details...'**
  String get additionalDetails;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'✅ Reminder set'**
  String get reminderSet;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @calendarAndDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Calendar & Deadlines'**
  String get calendarAndDeadlines;

  /// No description provided for @noActiveContractsToAddReminder.
  ///
  /// In en, this message translates to:
  /// **'No active contracts to add reminder'**
  String get noActiveContractsToAddReminder;

  /// No description provided for @weekDays.
  ///
  /// In en, this message translates to:
  /// **'M,T,W,T,F,S,S'**
  String get weekDays;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get months;

  /// No description provided for @responseTimeRanges.
  ///
  /// In en, this message translates to:
  /// **'<1h,1-6h,6-12h,12-24h,>24h'**
  String get responseTimeRanges;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'events'**
  String get events;

  /// No description provided for @noEventsForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No events for this day'**
  String get noEventsForThisDay;

  /// No description provided for @upcomingNext7Days.
  ///
  /// In en, this message translates to:
  /// **'Upcoming (Next 7 Days)'**
  String get upcomingNext7Days;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String daysLeft(int count);

  /// No description provided for @repositoryUrl.
  ///
  /// In en, this message translates to:
  /// **'Repository URL'**
  String get repositoryUrl;

  /// No description provided for @repositoryUrlExample.
  ///
  /// In en, this message translates to:
  /// **'Example: https://github.com/flutter/flutter'**
  String get repositoryUrlExample;

  /// No description provided for @branchOptional.
  ///
  /// In en, this message translates to:
  /// **'Branch (Optional)'**
  String get branchOptional;

  /// No description provided for @pleaseEnterRepositoryUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter repository URL'**
  String get pleaseEnterRepositoryUrl;

  /// No description provided for @pleaseEnterValidGithubUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid GitHub URL'**
  String get pleaseEnterValidGithubUrl;

  /// No description provided for @repositoryConnected.
  ///
  /// In en, this message translates to:
  /// **'✅ Repository connected'**
  String get repositoryConnected;

  /// No description provided for @projectWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Project Workspace'**
  String get projectWorkspace;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @filesSectionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Files section coming soon...'**
  String get filesSectionComingSoon;

  /// No description provided for @chatSectionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Chat section coming soon...'**
  String get chatSectionComingSoon;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWallet;

  /// No description provided for @errorLoadingWallet.
  ///
  /// In en, this message translates to:
  /// **'Error loading wallet'**
  String get errorLoadingWallet;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get pleaseEnterAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get insufficientBalance;

  /// No description provided for @completeStripeAccountSetup.
  ///
  /// In en, this message translates to:
  /// **'Please complete Stripe account setup'**
  String get completeStripeAccountSetup;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'m ago'**
  String get minutesAgo;

  /// No description provided for @noWalletFound.
  ///
  /// In en, this message translates to:
  /// **'No wallet found'**
  String get noWalletFound;

  /// No description provided for @boost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get boost;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get errorLoadingNotifications;

  /// No description provided for @allNotificationsMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allNotificationsMarkedAsRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'When you receive notifications, they will appear here'**
  String get notificationsWillAppearHere;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @clearChatConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear chat history?'**
  String get clearChatConfirmation;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @chatHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Chat history cleared'**
  String get chatHistoryCleared;

  /// No description provided for @askMeAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get askMeAnything;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get opening;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn'**
  String get referAndEarn;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @shareReferralMessage.
  ///
  /// In en, this message translates to:
  /// **'Join me on Freelancer Platform and get benefits! Use my code:'**
  String get shareReferralMessage;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get yourReferralCode;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share Code'**
  String get shareCode;

  /// No description provided for @referredFriends.
  ///
  /// In en, this message translates to:
  /// **'Referred Friends'**
  String get referredFriends;

  /// No description provided for @rateYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Experience'**
  String get rateYourExperience;

  /// No description provided for @youAreRating.
  ///
  /// In en, this message translates to:
  /// **'You are rating'**
  String get youAreRating;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get yourRating;

  /// No description provided for @yourReviewOptional.
  ///
  /// In en, this message translates to:
  /// **'Your Review (Optional)'**
  String get yourReviewOptional;

  /// No description provided for @shareYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Share Your Experience'**
  String get shareYourExperience;

  /// No description provided for @pleaseSelectRating.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating'**
  String get pleaseSelectRating;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get submitRating;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @errorSubmittingRating.
  ///
  /// In en, this message translates to:
  /// **'Error submitting rating'**
  String get errorSubmittingRating;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @replyVisibilityMessage.
  ///
  /// In en, this message translates to:
  /// **'Your reply will be visible to everyone. Be professional and courteous.'**
  String get replyVisibilityMessage;

  /// No description provided for @yourReply.
  ///
  /// In en, this message translates to:
  /// **'Your Reply'**
  String get yourReply;

  /// No description provided for @replyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your response to this review...\n\nExample: \"Thank you for your feedback! We appreciate your business and will work on improving.\"'**
  String get replyHint;

  /// No description provided for @tipsForGoodReply.
  ///
  /// In en, this message translates to:
  /// **'Tips for a good reply'**
  String get tipsForGoodReply;

  /// No description provided for @beProfessionalAndPolite.
  ///
  /// In en, this message translates to:
  /// **'• Be professional and polite'**
  String get beProfessionalAndPolite;

  /// No description provided for @addressSpecificConcerns.
  ///
  /// In en, this message translates to:
  /// **'• Address specific concerns'**
  String get addressSpecificConcerns;

  /// No description provided for @thankReviewerForFeedback.
  ///
  /// In en, this message translates to:
  /// **'• Thank the reviewer for feedback'**
  String get thankReviewerForFeedback;

  /// No description provided for @showWillingnessToImprove.
  ///
  /// In en, this message translates to:
  /// **'• Show willingness to improve'**
  String get showWillingnessToImprove;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @pleaseEnterReply.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reply'**
  String get pleaseEnterReply;

  /// No description provided for @replyMinLength.
  ///
  /// In en, this message translates to:
  /// **'Reply should be at least 10 characters'**
  String get replyMinLength;

  /// No description provided for @replyPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Reply posted successfully'**
  String get replyPostedSuccess;

  /// No description provided for @errorPostingReply.
  ///
  /// In en, this message translates to:
  /// **'Error posting reply'**
  String get errorPostingReply;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRating;

  /// No description provided for @totalReviews.
  ///
  /// In en, this message translates to:
  /// **'Total Reviews'**
  String get totalReviews;

  /// No description provided for @positiveRate.
  ///
  /// In en, this message translates to:
  /// **'Positive Rate'**
  String get positiveRate;

  /// No description provided for @categoryAverages.
  ///
  /// In en, this message translates to:
  /// **'Category Averages'**
  String get categoryAverages;

  /// No description provided for @interviewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Interview Calendar'**
  String get interviewCalendar;

  /// No description provided for @addInterview.
  ///
  /// In en, this message translates to:
  /// **'Add Interview'**
  String get addInterview;

  /// No description provided for @selectDayToViewInterviews.
  ///
  /// In en, this message translates to:
  /// **'Select a day to view interviews'**
  String get selectDayToViewInterviews;

  /// No description provided for @noInterviewsScheduledForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No interviews scheduled for this day'**
  String get noInterviewsScheduledForThisDay;

  /// No description provided for @noLink.
  ///
  /// In en, this message translates to:
  /// **'No link'**
  String get noLink;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @interviewDetails.
  ///
  /// In en, this message translates to:
  /// **'Interview Details'**
  String get interviewDetails;

  /// No description provided for @googleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get googleCalendar;

  /// No description provided for @downloadIcsFile.
  ///
  /// In en, this message translates to:
  /// **'Download .ics file'**
  String get downloadIcsFile;

  /// No description provided for @sendReminder.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get sendReminder;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @addFeedback.
  ///
  /// In en, this message translates to:
  /// **'Add Feedback'**
  String get addFeedback;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @invitationExpired.
  ///
  /// In en, this message translates to:
  /// **'This invitation has expired'**
  String get invitationExpired;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for'**
  String get scheduledFor;

  /// No description provided for @waitingForResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for response'**
  String get waitingForResponse;

  /// No description provided for @interviewCompleted.
  ///
  /// In en, this message translates to:
  /// **'Interview completed'**
  String get interviewCompleted;

  /// No description provided for @interviewDeclined.
  ///
  /// In en, this message translates to:
  /// **'Interview declined'**
  String get interviewDeclined;

  /// No description provided for @messageFrom.
  ///
  /// In en, this message translates to:
  /// **'Message from'**
  String get messageFrom;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation Sent'**
  String get invitationSent;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @interviewScheduled.
  ///
  /// In en, this message translates to:
  /// **'Interview Scheduled'**
  String get interviewScheduled;

  /// No description provided for @rescheduled.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled'**
  String get rescheduled;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @joinInterview.
  ///
  /// In en, this message translates to:
  /// **'Join Interview'**
  String get joinInterview;

  /// No description provided for @joinInterviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Click the button below to join the video interview.'**
  String get joinInterviewDescription;

  /// No description provided for @joinMeeting.
  ///
  /// In en, this message translates to:
  /// **'Join Meeting'**
  String get joinMeeting;

  /// No description provided for @interviewInvitation.
  ///
  /// In en, this message translates to:
  /// **'Interview Invitation'**
  String get interviewInvitation;

  /// No description provided for @proposedTime.
  ///
  /// In en, this message translates to:
  /// **'Proposed Time:'**
  String get proposedTime;

  /// No description provided for @availableTimes.
  ///
  /// In en, this message translates to:
  /// **'Available Times:'**
  String get availableTimes;

  /// No description provided for @addMessageOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a message (optional)'**
  String get addMessageOptional;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @acceptAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept & Confirm'**
  String get acceptAndConfirm;

  /// No description provided for @acceptSelectedTime.
  ///
  /// In en, this message translates to:
  /// **'Accept Selected Time'**
  String get acceptSelectedTime;

  /// No description provided for @pleaseSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a time'**
  String get pleaseSelectTime;

  /// No description provided for @completeInterview.
  ///
  /// In en, this message translates to:
  /// **'Complete Interview'**
  String get completeInterview;

  /// No description provided for @completeInterviewDescription.
  ///
  /// In en, this message translates to:
  /// **'After the interview, add your notes and feedback.'**
  String get completeInterviewDescription;

  /// No description provided for @meetingNotes.
  ///
  /// In en, this message translates to:
  /// **'Meeting Notes'**
  String get meetingNotes;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @declineInterview.
  ///
  /// In en, this message translates to:
  /// **'Decline Interview'**
  String get declineInterview;

  /// No description provided for @declineInterviewConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this interview invitation?'**
  String get declineInterviewConfirmation;

  /// No description provided for @interviewAccepted.
  ///
  /// In en, this message translates to:
  /// **'Interview accepted!'**
  String get interviewAccepted;

  /// No description provided for @errorAcceptingInterview.
  ///
  /// In en, this message translates to:
  /// **'Error accepting interview'**
  String get errorAcceptingInterview;

  /// No description provided for @interviewDeclinedMsg.
  ///
  /// In en, this message translates to:
  /// **'Interview declined'**
  String get interviewDeclinedMsg;

  /// No description provided for @errorDecliningInterview.
  ///
  /// In en, this message translates to:
  /// **'Error declining interview'**
  String get errorDecliningInterview;

  /// No description provided for @reasonForRescheduling.
  ///
  /// In en, this message translates to:
  /// **'Reason for rescheduling?'**
  String get reasonForRescheduling;

  /// No description provided for @interviewRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Interview rescheduled'**
  String get interviewRescheduled;

  /// No description provided for @errorRescheduling.
  ///
  /// In en, this message translates to:
  /// **'Error rescheduling'**
  String get errorRescheduling;

  /// No description provided for @reasonForCancellation.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation?'**
  String get reasonForCancellation;

  /// No description provided for @interviewCancelled.
  ///
  /// In en, this message translates to:
  /// **'Interview cancelled'**
  String get interviewCancelled;

  /// No description provided for @errorCancelling.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling'**
  String get errorCancelling;

  /// No description provided for @pleaseProvideReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason...'**
  String get pleaseProvideReason;

  /// No description provided for @addNotesAboutInterview.
  ///
  /// In en, this message translates to:
  /// **'Add notes about the interview:'**
  String get addNotesAboutInterview;

  /// No description provided for @meetingNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Meeting notes...'**
  String get meetingNotesHint;

  /// No description provided for @feedbackOptional.
  ///
  /// In en, this message translates to:
  /// **'Feedback (optional):'**
  String get feedbackOptional;

  /// No description provided for @additionalFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional feedback...'**
  String get additionalFeedbackHint;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @errorCompletingInterview.
  ///
  /// In en, this message translates to:
  /// **'Error completing interview'**
  String get errorCompletingInterview;

  /// No description provided for @calendarFileDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Calendar file downloaded'**
  String get calendarFileDownloaded;

  /// No description provided for @addedToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Added to calendar successfully!'**
  String get addedToCalendar;

  /// No description provided for @errorAddingToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Error adding to calendar'**
  String get errorAddingToCalendar;

  /// No description provided for @reminderSent.
  ///
  /// In en, this message translates to:
  /// **'Reminder sent successfully!'**
  String get reminderSent;

  /// No description provided for @errorSendingReminder.
  ///
  /// In en, this message translates to:
  /// **'Error sending reminder'**
  String get errorSendingReminder;

  /// No description provided for @interviewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Interview Analytics'**
  String get interviewAnalytics;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @totalInterviews.
  ///
  /// In en, this message translates to:
  /// **'Total Interviews'**
  String get totalInterviews;

  /// No description provided for @acceptanceRate.
  ///
  /// In en, this message translates to:
  /// **'Acceptance Rate'**
  String get acceptanceRate;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @avgResponse.
  ///
  /// In en, this message translates to:
  /// **'Avg Response'**
  String get avgResponse;

  /// No description provided for @interviewStatusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Interview Status Distribution'**
  String get interviewStatusDistribution;

  /// No description provided for @avgResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Response Time'**
  String get avgResponseTime;

  /// No description provided for @fromInvitationSent.
  ///
  /// In en, this message translates to:
  /// **'from invitation sent'**
  String get fromInvitationSent;

  /// No description provided for @monthlyTrends.
  ///
  /// In en, this message translates to:
  /// **'Monthly Trends'**
  String get monthlyTrends;

  /// No description provided for @upcomingInterviews.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Interviews'**
  String get upcomingInterviews;

  /// No description provided for @noUpcomingInterviews.
  ///
  /// In en, this message translates to:
  /// **'No upcoming interviews scheduled'**
  String get noUpcomingInterviews;

  /// No description provided for @interviews.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get interviews;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String inDays(int count);

  /// No description provided for @onTimeRate.
  ///
  /// In en, this message translates to:
  /// **'On-Time Rate'**
  String get onTimeRate;

  /// No description provided for @ofCompleted.
  ///
  /// In en, this message translates to:
  /// **'of completed'**
  String get ofCompleted;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg Rating'**
  String get avgRating;

  /// No description provided for @successRate.
  ///
  /// In en, this message translates to:
  /// **'Success Rate'**
  String get successRate;

  /// No description provided for @acceptedToCompleted.
  ///
  /// In en, this message translates to:
  /// **'accepted → completed'**
  String get acceptedToCompleted;

  /// No description provided for @responseTimeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Response Time Distribution'**
  String get responseTimeDistribution;

  /// No description provided for @interviewRatings.
  ///
  /// In en, this message translates to:
  /// **'Interview Ratings'**
  String get interviewRatings;

  /// No description provided for @topPerformers.
  ///
  /// In en, this message translates to:
  /// **'Top Performers'**
  String get topPerformers;

  /// No description provided for @interviewsCompleted.
  ///
  /// In en, this message translates to:
  /// **'interviews completed'**
  String get interviewsCompleted;

  /// No description provided for @aiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// No description provided for @bestTimeToInterview.
  ///
  /// In en, this message translates to:
  /// **'Best Time to Interview'**
  String get bestTimeToInterview;

  /// No description provided for @bestTimeToInterviewClient.
  ///
  /// In en, this message translates to:
  /// **'Based on your history, freelancers are most responsive between 10 AM - 2 PM on weekdays.'**
  String get bestTimeToInterviewClient;

  /// No description provided for @bestTimeToInterviewFreelancer.
  ///
  /// In en, this message translates to:
  /// **'You respond fastest to interview invitations within 2 hours of receiving them.'**
  String get bestTimeToInterviewFreelancer;

  /// No description provided for @successRateClient.
  ///
  /// In en, this message translates to:
  /// **'Your interview to hire conversion rate is {rate}%. Keep up the good work!'**
  String successRateClient(int rate);

  /// No description provided for @successRateFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Your interview acceptance rate is {rate}%. Try responding faster to improve.'**
  String successRateFreelancer(int rate);

  /// No description provided for @optimalSchedule.
  ///
  /// In en, this message translates to:
  /// **'Optimal Schedule'**
  String get optimalSchedule;

  /// No description provided for @optimalScheduleClient.
  ///
  /// In en, this message translates to:
  /// **'Tuesday and Wednesday have the highest acceptance rates for interview invitations.'**
  String get optimalScheduleClient;

  /// No description provided for @optimalScheduleFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Interviews scheduled on Thursday have the highest completion rate.'**
  String get optimalScheduleFreelancer;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @recommendationClient1.
  ///
  /// In en, this message translates to:
  /// **'Your response rate is 85%. Try to respond within 24 hours for better results.'**
  String get recommendationClient1;

  /// No description provided for @recommendationClient2.
  ///
  /// In en, this message translates to:
  /// **'Schedule interviews between 10 AM - 2 PM for higher acceptance rates.'**
  String get recommendationClient2;

  /// No description provided for @recommendationClient3.
  ///
  /// In en, this message translates to:
  /// **'Send a reminder 1 hour before the interview to reduce no-shows.'**
  String get recommendationClient3;

  /// No description provided for @recommendationFreelancer1.
  ///
  /// In en, this message translates to:
  /// **'You respond within 4 hours on average. Keep up the good work!'**
  String get recommendationFreelancer1;

  /// No description provided for @recommendationFreelancer2.
  ///
  /// In en, this message translates to:
  /// **'Your acceptance rate is 75%. Try to respond to all invitations.'**
  String get recommendationFreelancer2;

  /// No description provided for @recommendationFreelancer3.
  ///
  /// In en, this message translates to:
  /// **'Prepare questions before the interview to make a better impression.'**
  String get recommendationFreelancer3;

  /// No description provided for @proTips.
  ///
  /// In en, this message translates to:
  /// **'Pro Tips'**
  String get proTips;

  /// No description provided for @proTipsContent.
  ///
  /// In en, this message translates to:
  /// **'• Send interview invitations within 24 hours of receiving a proposal\n• Always confirm the interview time 1 day in advance\n• Prepare specific questions before the interview\n• Take notes during the interview for better evaluation\n• Follow up within 48 hours after the interview'**
  String get proTipsContent;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at'**
  String get todayAt;

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at'**
  String get yesterdayAt;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @errorLoadingInterviews.
  ///
  /// In en, this message translates to:
  /// **'Error loading interviews'**
  String get errorLoadingInterviews;

  /// No description provided for @noInterviewInvitationsSent.
  ///
  /// In en, this message translates to:
  /// **'No interview invitations sent'**
  String get noInterviewInvitationsSent;

  /// No description provided for @noInterviewInvitationsReceived.
  ///
  /// In en, this message translates to:
  /// **'No interview invitations received'**
  String get noInterviewInvitationsReceived;

  /// No description provided for @inviteFreelancersToInterview.
  ///
  /// In en, this message translates to:
  /// **'Invite freelancers to interview before hiring'**
  String get inviteFreelancersToInterview;

  /// No description provided for @interviewsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'When clients invite you for interviews, they will appear here'**
  String get interviewsWillAppearHere;

  /// No description provided for @browseYourProjects.
  ///
  /// In en, this message translates to:
  /// **'Browse Your Projects'**
  String get browseYourProjects;

  /// No description provided for @with_.
  ///
  /// In en, this message translates to:
  /// **'with'**
  String get with_;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @interviewFeedback.
  ///
  /// In en, this message translates to:
  /// **'Interview Feedback'**
  String get interviewFeedback;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps {name} improve and helps other clients make informed decisions.'**
  String feedbackDescription(String name);

  /// No description provided for @overallRating.
  ///
  /// In en, this message translates to:
  /// **'Overall Rating'**
  String get overallRating;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent! 🌟'**
  String get excellent;

  /// No description provided for @veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good! 👍'**
  String get veryGood;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good 👌'**
  String get good;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair 😐'**
  String get fair;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor 😞'**
  String get poor;

  /// No description provided for @detailedRatings.
  ///
  /// In en, this message translates to:
  /// **'Detailed Ratings'**
  String get detailedRatings;

  /// No description provided for @professionalism.
  ///
  /// In en, this message translates to:
  /// **'Professionalism'**
  String get professionalism;

  /// No description provided for @technicalSkills.
  ///
  /// In en, this message translates to:
  /// **'Technical Skills'**
  String get technicalSkills;

  /// No description provided for @punctuality.
  ///
  /// In en, this message translates to:
  /// **'Punctuality'**
  String get punctuality;

  /// No description provided for @ratingLabelProfessionalism.
  ///
  /// In en, this message translates to:
  /// **'Professionalism'**
  String get ratingLabelProfessionalism;

  /// No description provided for @ratingLabelCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get ratingLabelCommunication;

  /// No description provided for @ratingLabelTechnicalSkills.
  ///
  /// In en, this message translates to:
  /// **'Technical Skills'**
  String get ratingLabelTechnicalSkills;

  /// No description provided for @ratingLabelPunctuality.
  ///
  /// In en, this message translates to:
  /// **'Punctuality'**
  String get ratingLabelPunctuality;

  /// No description provided for @whatWentWell.
  ///
  /// In en, this message translates to:
  /// **'What went well?'**
  String get whatWentWell;

  /// No description provided for @whatWentWellHint.
  ///
  /// In en, this message translates to:
  /// **'Share what you liked about the interview...'**
  String get whatWentWellHint;

  /// No description provided for @whatCouldBeImproved.
  ///
  /// In en, this message translates to:
  /// **'What could be improved?'**
  String get whatCouldBeImproved;

  /// No description provided for @whatCouldBeImprovedHint.
  ///
  /// In en, this message translates to:
  /// **'Constructive feedback for improvement...'**
  String get whatCouldBeImprovedHint;

  /// No description provided for @wouldYouHireAgain.
  ///
  /// In en, this message translates to:
  /// **'Would you hire this freelancer again?'**
  String get wouldYouHireAgain;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// No description provided for @thankYouForFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouForFeedback;

  /// No description provided for @errorSubmittingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Error submitting feedback'**
  String get errorSubmittingFeedback;

  /// No description provided for @interviewQuestionLibrary.
  ///
  /// In en, this message translates to:
  /// **'Interview Question Library'**
  String get interviewQuestionLibrary;

  /// No description provided for @technicalQuestions.
  ///
  /// In en, this message translates to:
  /// **'Technical Questions'**
  String get technicalQuestions;

  /// No description provided for @portfolioReview.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Review'**
  String get portfolioReview;

  /// No description provided for @softSkills.
  ///
  /// In en, this message translates to:
  /// **'Soft Skills'**
  String get softSkills;

  /// No description provided for @culturalFit.
  ///
  /// In en, this message translates to:
  /// **'Cultural Fit'**
  String get culturalFit;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @tipStarMethod.
  ///
  /// In en, this message translates to:
  /// **'Use the STAR method (Situation, Task, Action, Result) to structure your answer.'**
  String get tipStarMethod;

  /// No description provided for @tipChallenge.
  ///
  /// In en, this message translates to:
  /// **'Focus on the problem-solving process and what you learned.'**
  String get tipChallenge;

  /// No description provided for @tipDeadline.
  ///
  /// In en, this message translates to:
  /// **'Show your time management skills and ability to prioritize.'**
  String get tipDeadline;

  /// No description provided for @tipGeneral.
  ///
  /// In en, this message translates to:
  /// **'Be honest and provide specific examples from your experience.'**
  String get tipGeneral;

  /// No description provided for @questionCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Question copied to clipboard!'**
  String get questionCopiedToClipboard;

  /// No description provided for @shareFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share feature coming soon!'**
  String get shareFeatureComingSoon;

  /// No description provided for @searchQuestions.
  ///
  /// In en, this message translates to:
  /// **'Search Questions'**
  String get searchQuestions;

  /// No description provided for @searchByKeyword.
  ///
  /// In en, this message translates to:
  /// **'Search by keyword...'**
  String get searchByKeyword;

  /// No description provided for @randomQuestionForYou.
  ///
  /// In en, this message translates to:
  /// **'Random Question for You'**
  String get randomQuestionForYou;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @randomQuestion.
  ///
  /// In en, this message translates to:
  /// **'Random Question'**
  String get randomQuestion;

  /// No description provided for @noQuestionsFound.
  ///
  /// In en, this message translates to:
  /// **'No questions found'**
  String get noQuestionsFound;

  /// No description provided for @tipsForAnswering.
  ///
  /// In en, this message translates to:
  /// **'💡 Tips for answering:'**
  String get tipsForAnswering;

  /// No description provided for @copyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Copy question'**
  String get copyQuestion;

  /// No description provided for @saveToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Save to favorites'**
  String get saveToFavorites;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get completePayment;

  /// No description provided for @securePayment.
  ///
  /// In en, this message translates to:
  /// **'Secure Payment'**
  String get securePayment;

  /// No description provided for @paymentHeldInEscrow.
  ///
  /// In en, this message translates to:
  /// **'Your payment will be held in escrow until the project is completed.'**
  String get paymentHeldInEscrow;

  /// No description provided for @contractTotal.
  ///
  /// In en, this message translates to:
  /// **'Contract total'**
  String get contractTotal;

  /// No description provided for @couponDiscount.
  ///
  /// In en, this message translates to:
  /// **'Coupon discount'**
  String get couponDiscount;

  /// No description provided for @chargedNowEscrow.
  ///
  /// In en, this message translates to:
  /// **'Charged now (escrow)'**
  String get chargedNowEscrow;

  /// No description provided for @commissionOnRelease.
  ///
  /// In en, this message translates to:
  /// **'Commission (on release)'**
  String get commissionOnRelease;

  /// No description provided for @estFee.
  ///
  /// In en, this message translates to:
  /// **'est. fee'**
  String get estFee;

  /// No description provided for @paymentSecureDescription.
  ///
  /// In en, this message translates to:
  /// **'Your payment is secure and will only be released when you approve each milestone.'**
  String get paymentSecureDescription;

  /// No description provided for @stripeWebRedirect.
  ///
  /// In en, this message translates to:
  /// **'You will be redirected to Stripe secure checkout page.'**
  String get stripeWebRedirect;

  /// No description provided for @stripeInAppPayment.
  ///
  /// In en, this message translates to:
  /// **'Secure in-app payment with Stripe.'**
  String get stripeInAppPayment;

  /// No description provided for @payWithStripe.
  ///
  /// In en, this message translates to:
  /// **'Pay with Stripe'**
  String get payWithStripe;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @confirmPaymentManual.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment (Manual)'**
  String get confirmPaymentManual;

  /// No description provided for @agreeToTermsByPaying.
  ///
  /// In en, this message translates to:
  /// **'By paying, you agree to our Terms of Service'**
  String get agreeToTermsByPaying;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'✅ Payment confirmed!'**
  String get paymentConfirmed;

  /// No description provided for @failedToConfirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to confirm payment'**
  String get failedToConfirmPayment;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'✅ Payment successful!'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @completePaymentInNewTab.
  ///
  /// In en, this message translates to:
  /// **'Complete payment in the new tab'**
  String get completePaymentInNewTab;

  /// No description provided for @completeSubscriptionPayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Subscription Payment'**
  String get completeSubscriptionPayment;

  /// No description provided for @subscriptionPayment.
  ///
  /// In en, this message translates to:
  /// **'Subscription Payment'**
  String get subscriptionPayment;

  /// No description provided for @subscriptionActivatedImmediately.
  ///
  /// In en, this message translates to:
  /// **'Your subscription will be activated immediately after payment.'**
  String get subscriptionActivatedImmediately;

  /// No description provided for @subscriptionPrice.
  ///
  /// In en, this message translates to:
  /// **'Subscription Price'**
  String get subscriptionPrice;

  /// No description provided for @subscriptionSecureDescription.
  ///
  /// In en, this message translates to:
  /// **'Your payment is secure and will grant you immediate access to all premium features.'**
  String get subscriptionSecureDescription;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @subscriptionPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'✅ Subscription payment confirmed!'**
  String get subscriptionPaymentConfirmed;

  /// No description provided for @failedToConfirmSubscriptionPayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to confirm subscription payment'**
  String get failedToConfirmSubscriptionPayment;

  /// No description provided for @subscriptionPaymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'✅ Subscription payment successful!'**
  String get subscriptionPaymentSuccessful;

  /// No description provided for @subscriptionPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Subscription payment failed'**
  String get subscriptionPaymentFailed;

  /// No description provided for @agreeToTermsBySubscribing.
  ///
  /// In en, this message translates to:
  /// **'By subscribing, you agree to our Terms of Service and Privacy Policy'**
  String get agreeToTermsBySubscribing;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @minBudget.
  ///
  /// In en, this message translates to:
  /// **'Min Budget'**
  String get minBudget;

  /// No description provided for @maxBudget.
  ///
  /// In en, this message translates to:
  /// **'Max Budget'**
  String get maxBudget;

  /// No description provided for @minDuration.
  ///
  /// In en, this message translates to:
  /// **'Min Duration'**
  String get minDuration;

  /// No description provided for @maxDuration.
  ///
  /// In en, this message translates to:
  /// **'Max Duration'**
  String get maxDuration;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

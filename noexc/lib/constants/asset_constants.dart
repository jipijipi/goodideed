/// Asset path constants for consistent asset referencing
/// This centralizes all asset paths to minimize merge conflicts
class AssetConstants {
  // Private constructor to prevent instantiation
  AssetConstants._();

  // ==================== ASSET DIRECTORIES ====================

  static const String _assetsRoot = 'assets/';
  static const String _sequencesPath = '${_assetsRoot}sequences/';
  static const String _variantsPath = '${_assetsRoot}variants/';
  static const String _debugPath = '${_assetsRoot}debug/';
  static const String _contentPath = '${_assetsRoot}content/';
  static const String _imagesPath = '${_assetsRoot}images/';
  static const String _iconsPath = '${_assetsRoot}icons/';
  static const String _fontsPath = '${_assetsRoot}fonts/';

  // ==================== SEQUENCE FILES ====================

  static const String welcomeSequence = '${_sequencesPath}welcome_seq.json';
  static const String onboardingSequence =
      '${_sequencesPath}onboarding_seq.json';
  static const String taskCheckingSequence =
      '${_sequencesPath}taskChecking_seq.json';
  static const String taskSettingSequence =
      '${_sequencesPath}taskSetting_seq.json';
  static const String sendoffSequence = '${_sequencesPath}sendoff_seq.json';
  static const String successSequence = '${_sequencesPath}success_seq.json';
  static const String failureSequence = '${_sequencesPath}failure_seq.json';
  static const String taskConfigSequence =
      '${_sequencesPath}task_config_seq.json';
  static const String taskConfigTestSequence =
      '${_sequencesPath}task_config_test_seq.json';
  static const String dayTrackingTestSequence =
      '${_sequencesPath}day_tracking_test_seq.json';

  // ==================== DEBUG FILES ====================

  static const String debugScenarios = '${_debugPath}scenarios.json';

  // ==================== CONTENT DIRECTORIES ====================

  static const String formattersContent = '${_contentPath}formatters/';
  static const String botContent = '${_contentPath}bot/';
  static const String userContent = '${_contentPath}user/';
  static const String systemContent = '${_contentPath}system/';

  // Bot content subdirectories
  static const String botIntroduce = '${botContent}introduce/';
  static const String botInform = '${botContent}inform/';
  static const String botAcknowledge = '${botContent}acknowledge/';
  static const String botRequest = '${botContent}request/';
  static const String botReact = '${botContent}react/';
  static const String botExplain = '${botContent}explain/';
  static const String botCelebrate = '${botContent}celebrate/';
  static const String botConsole = '${botContent}console/';
  static const String botWarn = '${botContent}warn/';
  static const String botSendoff = '${botContent}sendoff/';

  // User content subdirectories
  static const String userChoose = '${userContent}choose/';
  static const String userGreet = '${userContent}greet/';
  static const String userComment = '${userContent}comment/';
  static const String userProvide = '${userContent}provide/';

  // System content subdirectories
  static const String systemCheck = '${systemContent}check/';
  static const String systemSet = '${systemContent}set/';
  static const String systemReset = '${systemContent}reset/';

  // ==================== PLACEHOLDER IMAGES ====================

  static const String placeholderAvatar =
      '${_imagesPath}placeholder_avatar.png';
  static const String placeholderImage = '${_imagesPath}placeholder_image.png';
  static const String appLogo = '${_imagesPath}app_logo.png';
  static const String appIcon = '${_iconsPath}app_icon.png';

  // ==================== BRAND ASSETS ====================

  static const String brandLogo = '${_imagesPath}brand/logo.png';
  static const String brandLogoLight = '${_imagesPath}brand/logo_light.png';
  static const String brandLogoDark = '${_imagesPath}brand/logo_dark.png';
  static const String brandIcon = '${_iconsPath}brand/icon.png';

  // ==================== UI ASSETS ====================

  // Illustration assets
  static const String illustrationEmpty =
      '${_imagesPath}illustrations/empty_state.svg';
  static const String illustrationError =
      '${_imagesPath}illustrations/error_state.svg';
  static const String illustrationSuccess =
      '${_imagesPath}illustrations/success_state.svg';
  static const String illustrationOnboarding =
      '${_imagesPath}illustrations/onboarding.svg';

  // Background assets
  static const String backgroundPattern =
      '${_imagesPath}backgrounds/pattern.png';
  static const String backgroundGradient =
      '${_imagesPath}backgrounds/gradient.png';

  // Icon assets
  static const String iconChat = '${_iconsPath}chat.svg';
  static const String iconSettings = '${_iconsPath}settings.svg';
  static const String iconProfile = '${_iconsPath}profile.svg';
  static const String iconNotification = '${_iconsPath}notification.svg';

  // ==================== FONT ASSETS ====================

  static const String fontPrimary = '${_fontsPath}Roboto/';
  static const String fontDisplay = '${_fontsPath}RobotoSlab/';
  static const String fontMono = '${_fontsPath}RobotoMono/';

  // ==================== ASSET VALIDATION ====================

  /// Get all sequence file paths for validation
  static List<String> get allSequenceFiles => [
    welcomeSequence,
    onboardingSequence,
    taskCheckingSequence,
    taskSettingSequence,
    sendoffSequence,
    successSequence,
    failureSequence,
    taskConfigSequence,
    taskConfigTestSequence,
    dayTrackingTestSequence,
  ];

  /// Get all content directories for validation
  static List<String> get allContentDirectories => [
    formattersContent,
    botIntroduce,
    botInform,
    botAcknowledge,
    botRequest,
    botReact,
    botExplain,
    botCelebrate,
    botConsole,
    botWarn,
    botSendoff,
    userChoose,
    userGreet,
    userComment,
    userProvide,
    systemCheck,
    systemSet,
    systemReset,
  ];

  /// Get all required asset directories
  static List<String> get allAssetDirectories => [
    _sequencesPath,
    _variantsPath,
    _debugPath,
    _contentPath,
    _imagesPath,
    _iconsPath,
    _fontsPath,
    ...allContentDirectories,
  ];
}

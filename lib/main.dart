import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'version.dart';

class AppConstants {
  static const String appName = 'Countdown';
  static const String packageName = 'com.death.countdown';
  static const String version = appVersion;
  static const String developer = 'ChidcGithub';
  static const String developerDevMode = 'Death God';
  static const String githubUrl = 'https://github.com/ChidcGithub/CountDown';
  
  static const int minAge = 60;
  static const int maxAge = 100;
  static const int versionTapCount = 3;
  static const int titleTapCount = 5;
}

class StorageKeys {
  static const String hasSeenWelcome = 'hasSeenWelcome';
  static const String hasShownRecovery = 'hasShownRecovery';
  static const String deviceId = 'deviceId';
  static const String username = 'username';
  static const String birthDate = 'birthDate';
  static const String deathDate = 'deathDate';
  static const String devModeVersionClicks = 'devModeVersionClicks';
  static const String devModeTitleClicks = 'devModeTitleClicks';
}

class CountdownData {
  final String username;
  final DateTime birthDate;
  final DateTime deathDate;

  CountdownData({
    required this.username,
    required this.birthDate,
    required this.deathDate,
  });

  Duration get _diff {
    final diff = deathDate.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  int get years => _diff.inDays ~/ 365;
  int get months => (_diff.inDays % 365) ~/ 30;
  int get days => (_diff.inDays % 365) % 30;
  int get hours => _diff.inHours % 24;
  int get minutes => _diff.inMinutes % 60;
  int get seconds => _diff.inSeconds % 60;
  int get milliseconds => _diff.inMilliseconds % 1000;
}

class SearchUser {
  final String username;
  DateTime deathDate;

  SearchUser({required this.username, required this.deathDate});

  String get countdownString {
    final now = DateTime.now();
    final diff = deathDate.difference(now);
    if (diff.isNegative) return 'EXPIRED';
    
    final years = diff.inDays ~/ 365;
    final months = (diff.inDays % 365) ~/ 30;
    final days = (diff.inDays % 365) % 30;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    final milliseconds = diff.inMilliseconds % 1000;
    
    return '${years}Y ${months}M ${days}D ${hours}h ${minutes}m ${seconds}s ${milliseconds}ms';
  }

  Map<String, dynamic> toMap() => {'username': username, 'deathDate': deathDate.toIso8601String()};

  static SearchUser fromMap(Map<String, dynamic> map) => SearchUser(
    username: map['username'],
    deathDate: DateTime.parse(map['deathDate']),
  );
}

class StorageService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<String?> getDeviceId() async {
    final p = await prefs;
    String? id = p.getString(StorageKeys.deviceId);
    if (id == null) {
      id = const Uuid().v4();
      await p.setString(StorageKeys.deviceId, id);
    }
    return id;
  }

  static Future<CountdownData?> loadUserData() async {
    final p = await prefs;
    final username = p.getString(StorageKeys.username);
    final birthDateStr = p.getString(StorageKeys.birthDate);
    final deathDateStr = p.getString(StorageKeys.deathDate);

    if (username != null && birthDateStr != null && deathDateStr != null) {
      return CountdownData(
        username: username,
        birthDate: DateTime.parse(birthDateStr),
        deathDate: DateTime.parse(deathDateStr),
      );
    }
    return null;
  }

  static Future<bool> hasSeenWelcome() async {
    final p = await prefs;
    return p.getBool(StorageKeys.hasSeenWelcome) ?? false;
  }

  static Future<void> setHasSeenWelcome(bool value) async {
    final p = await prefs;
    await p.setBool(StorageKeys.hasSeenWelcome, value);
  }

  static Future<bool> hasShownRecovery() async {
    final p = await prefs;
    return p.getBool(StorageKeys.hasShownRecovery) ?? false;
  }

  static Future<void> setHasShownRecovery(bool value) async {
    final p = await prefs;
    await p.setBool(StorageKeys.hasShownRecovery, value);
  }

  static Future<void> saveUserData(String username, DateTime birthDate, DateTime deathDate) async {
    final p = await prefs;
    await p.setString(StorageKeys.username, username);
    await p.setString(StorageKeys.birthDate, birthDate.toIso8601String());
    await p.setString(StorageKeys.deathDate, deathDate.toIso8601String());
  }

  static Future<int> getDevModeVersionClicks() async {
    final p = await prefs;
    return p.getInt(StorageKeys.devModeVersionClicks) ?? 0;
  }

  static Future<int> getDevModeTitleClicks() async {
    final p = await prefs;
    return p.getInt(StorageKeys.devModeTitleClicks) ?? 0;
  }

  static Future<void> setDevModeVersionClicks(int count) async {
    final p = await prefs;
    await p.setInt(StorageKeys.devModeVersionClicks, count);
  }

  static Future<void> setDevModeTitleClicks(int count) async {
    final p = await prefs;
    await p.setInt(StorageKeys.devModeTitleClicks, count);
  }

  static Future<void> clearAllData() async {
    final p = await prefs;
    await p.clear();
  }
}

DateTime calculateDeathDate(String username, DateTime birthDate, String deviceId) {
  final combined = '$username:${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}:$deviceId';
  var hash = 0;
  for (var i = 0; i < combined.length; i++) {
    hash = ((hash << 5) - hash) + combined.codeUnitAt(i);
    hash = hash & 0xFFFFFFFF;
  }
  final age = (hash % (AppConstants.maxAge - AppConstants.minAge)) + AppConstants.minAge;
  final hash2 = (hash >> 10) & 0xFFFFFF;
  final milliseconds = hash % 1000;
  final totalSeconds = hash2 % (24 * 60 * 60);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  return DateTime(birthDate.year + age, birthDate.month, birthDate.day, hours, minutes, seconds, milliseconds);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CountdownApp());
}

class CountdownApp extends StatelessWidget {
  const CountdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFFF0000);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const InitialLoader(),
    );
  }
}

class InitialLoader extends StatefulWidget {
  const InitialLoader({super.key});

  @override
  State<InitialLoader> createState() => _InitialLoaderState();
}

class _InitialLoaderState extends State<InitialLoader> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    final userData = await StorageService.loadUserData();
    if (!mounted) return;

    if (userData != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SplashScreen()));
    } else {
      final hasSeenWelcome = await StorageService.hasSeenWelcome();
      if (hasSeenWelcome) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserSetupScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.red)),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  bool _isRecovery = false;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _checkAndNavigate();
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _triggerRecoveryEffect() async {
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.vibrate();
      _flashController.forward().then((_) => _flashController.reverse());
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _checkAndNavigate() async {
    final userData = await StorageService.loadUserData();
    final hasShownRecovery = await StorageService.hasShownRecovery();
    final isRecovery = userData != null && !hasShownRecovery;

    if (isRecovery) {
      setState(() => _isRecovery = true);
      _triggerRecoveryEffect();
      await StorageService.setHasShownRecovery(true);
    }

    await Future.delayed(Duration(seconds: isRecovery ? 3 : 2));
    if (!mounted) return;

    if (userData != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainCountdownScreen(data: userData)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        final isFlashing = _flashController.value > 0.5;
        return Scaffold(
          backgroundColor: isFlashing ? Colors.red : Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isRecovery ? Icons.restore : Icons.hourglass_bottom, size: 80, color: isFlashing ? Colors.black : Colors.red),
                const SizedBox(height: 20),
                Text(
                  _isRecovery ? 'COUNTDOWN RESTORED' : 'COUNTDOWN',
                  style: TextStyle(fontSize: _isRecovery ? 28 : 40, fontWeight: FontWeight.w900, color: isFlashing ? Colors.black : Colors.red, letterSpacing: 10),
                ),
                if (_isRecovery) ...[
                  const SizedBox(height: 20),
                  Text('Your countdown has been recovered', style: TextStyle(fontSize: 16, color: isFlashing ? Colors.black54 : Colors.white54)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
              const SizedBox(height: 30),
              const Text('JUST FOR FUN', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 10),
              const Text('Do not take this seriously', style: TextStyle(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 40),
              const Text('This is purely for entertainment purposes only.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
              const Spacer(),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.red.shade800), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('User Agreement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FullAgreementScreen())),
                            child: const Text('View Full', style: TextStyle(color: Colors.red, fontSize: 14)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'IMPORTANT NOTICE\n\n'
                                'Please read this User Agreement carefully before using this application.\n\n'
                                '1. ENTERTAINMENT PURPOSE ONLY\n'
                                "This application is designed solely for entertainment purposes. The countdown timer displayed is a fictional simulation and should not be interpreted as any form of prediction, prophecy, or factual information about an individual's lifespan.\n\n"
                                '2. NO REAL DATA USED\n'
                                'The countdown calculation is based on a deterministic algorithm that combines username, birth date, and device identification.\n\n'
                                '3. NO LIABILITY\n'
                                'The developer shall not be held liable for any psychological, emotional, or behavioral changes that may occur as a result of using this application.\n\n'
                                '4. FORCE MAJEURE CLAUSE\n'
                                "If you make life decisions based on this application's countdown and experience unexpected consequences, such events shall be considered force majeure.\n\n"
                                '5. DATA PRIVACY\n'
                                'This application does not collect, store, or transmit any personal information to external servers.\n\n'
                                '6. NO NETWORK COMMUNICATION\n'
                                'This application does not connect to the internet for any purpose.\n\n'
                                '7. USER RESPONSIBILITY\n'
                                'You acknowledge that you are of legal age to use this application or have obtained parental/guardian consent.\n\n'
                                '8. MODIFICATION OF TERMS\n'
                                'The developer reserves the right to modify this agreement at any time.\n\n'
                                '9. INTELLECTUAL PROPERTY\n'
                                'All content within this application is the intellectual property of the developer.\n\n'
                                '10. GOVERNING LAW\n'
                                'This agreement shall be governed by applicable laws.\n\n'
                                '11. ADDITIONAL INFORMATION\n'
                                'For more information, please visit our GitHub repository:\n'
                                'https://github.com/ChidcGithub/CountDown\n\n'
                                'By checking the box below, you acknowledge that you have read, understood, and agree to be bound by all terms and conditions.',
                                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(value: agreed, onChanged: (v) => setState(() => agreed = v ?? false), activeColor: Colors.red),
                          const Expanded(child: Text('I have read and agree to the terms and conditions', style: TextStyle(color: Colors.white, fontSize: 12))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: agreed ? () async {
                    final navigator = Navigator.of(context);
                    await StorageService.setHasSeenWelcome(true);
                    if (!mounted) return;
                    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const UserSetupScreen()));
                  } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, disabledBackgroundColor: Colors.grey.shade800),
                  child: const Text('CONTINUE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class FullAgreementScreen extends StatelessWidget {
  const FullAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('User Agreement', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.red),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''COUNTDOWN APPLICATION - COMPREHENSIVE USER AGREEMENT\n\n'
          'Last Updated: 2026\n\n'
          'IMPORTANT LEGAL NOTICE\n\n'
          'PLEASE READ THIS AGREEMENT CAREFULLY BEFORE USING THIS APPLICATION. THIS IS A LEGALLY BINDING AGREEMENT BETWEEN YOU AND THE DEVELOPER. BY ACCESSING, DOWNLOADING, OR USING THIS APPLICATION, YOU ACKNOWLEDGE THAT YOU HAVE READ, UNDERSTOOD, AND AGREE TO BE BOUND BY ALL TERMS AND CONDITIONS CONTAINED HEREIN. IF YOU DO NOT AGREE TO THESE TERMS, DO NOT USE THIS APPLICATION.\n\n'
          'SECTION 1: NATURE OF APPLICATION\n\n'
          '1.1 This application, named "Countdown," is a digital entertainment product designed solely for recreational and amusement purposes. The primary function of this application is to generate and display a simulated countdown timer based on user-provided information including but not limited to username, date of birth, and device identification data.\n\n'
          "1.2 The countdown timer displayed by this application is a FICTIONAL AND FANTASY-BASED simulation. It does not represent, predict, forecast, or in any manner relate to the actual lifespan, mortality, or any aspect of the user's real-life expectancy. The developer explicitly states that the mathematical algorithm used to generate the countdown is a randomized deterministic function and bears absolutely no correlation to medical science, actuarial data, or any form of life expectancy calculation.\n\n"
          "1.3 This application is not intended for, and should not be used for, making any life decisions, financial planning, health-related choices, or any decisions that may affect the user's physical or mental well-being. The user acknowledges that any interpretation of the countdown beyond entertainment is wholly unreasonable and unwarranted.\n\n"
          'SECTION 2: DISCLAIMER OF WARRANTIES\n\n'
          '2.1 THIS APPLICATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. THE DEVELOPER DOES NOT WARRANT THAT THE APPLICATION WILL MEET YOUR REQUIREMENTS, BE UNINTERRUPTED, TIMELY, SECURE, OR ERROR-FREE.\n\n'
          '2.2 THE DEVELOPER EXPRESSLY DISCLAIMS ANY AND ALL LIABILITY FOR THE ACCURACY, COMPLETENESS, LEGALITY, RELIABILITY, OR USEFULNESS OF ANY INFORMATION DISPLAYED BY THE APPLICATION. THE COUNTDOWN TIMER IS NOT BASED ON ANY SCIENTIFIC, MEDICAL, STATISTICAL, OR EMPIRICAL DATA AND SHOULD NOT BE TREATED AS SUCH.\n\n'
          '2.3 THE USER UNDERSTANDS AND ACKNOWLEDGES THAT THE APPLICATION MAY CONTAIN BUGS, ERRORS, OR INACCURACIES. THE DEVELOPER MAKES NO REPRESENTATIONS ABOUT THE SUITABILITY OF THE INFORMATION CONTAINED IN THIS APPLICATION FOR ANY PURPOSE.\n\n'
          'SECTION 3: LIMITATION OF LIABILITY\n\n'
          '3.1 IN NO EVENT SHALL THE DEVELOPER BE LIABLE TO YOU OR ANY THIRD PARTY FOR ANY INDIRECT, INCIDENTAL, CONSEQUENTIAL, SPECIAL, EXEMPLARY, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO, DAMAGES FOR LOSS OF PROFITS, GOODWILL, USE, DATA, OR OTHER INTANGIBLE LOSSES, RESULTING FROM:\n\n'
          '(a) YOUR USE OR INABILITY TO USE THE APPLICATION;\n\n'
          '(b) ANY UNAUTHORIZED ACCESS TO OR USE OF OUR SERVERS AND/OR ANY PERSONAL INFORMATION STORED THEREIN;\n\n'
          '(c) ANY INTERRUPTION OR CESSATION OF TRANSMISSION TO OR FROM THE APPLICATION;\n\n'
          '(d) ANY BUGS, VIRUSES, TROJAN HORSES, OR THE LIKE THAT MAY BE TRANSMITTED TO OR THROUGH THE APPLICATION;\n\n'
          '(e) ANY ERRORS, INACCURACIES, OR OMISSIONS IN ANY CONTENT OR INFORMATION.\n\n'
          "3.2 NOTWITHSTANDING ANYTHING TO THE CONTRARY CONTAINED HEREIN, THE DEVELOPER'S LIABILITY TO YOU FOR ANY CAUSE WHATSOEVER AND REGARDLESS OF THE FORM OF THE ACTION, WILL AT ALL TIMES BE LIMITED TO THE AMOUNT PAID, IF ANY, BY YOU TO THE DEVELOPER FOR THE APPLICATION DURING THE TWELVE (12) MONTHS PRECEDING THE CAUSE OF ACTION.\n\n"
          '3.3 THE USER SPECIFICALLY ACKNOWLEDGES THAT THE DEVELOPER SHALL NOT BE LIABLE FOR ANY DEFAMATORY, OFFENSIVE, OR ILLEGAL CONDUCT OF ANY USER OR THIRD PARTY AND THAT THE RISK OF HARM OR DAMAGE FROM THE FOREGOING RESTS ENTIRELY WITH YOU.\n\n'
          'SECTION 4: FORCE MAJEURE\n\n'
          '4.1 THE DEVELOPER SHALL NOT BE LIABLE FOR ANY FAILURE OR DELAY IN PERFORMING ITS OBLIGATIONS UNDER THIS AGREEMENT WHERE SUCH FAILURE OR DELAY RESULTS FROM ANY CAUSE THAT IS BEYOND THE REASONABLE CONTROL OF THE DEVELOPER, INCLUDING BUT NOT LIMITED TO: ACTS OF GOD, NATURAL DISASTERS, WAR, TERRORISM, RIOTS, EMBARGOES, ACTS OF CIVIL OR MILITARY AUTHORITIES, FIRE, FLOODS, ACCIDENTS, STRIKES, OR SHORTAGES OF TRANSPORTATION, FACILITIES, FUEL, ENERGY, LABOR, OR MATERIALS.\n\n'
          '4.2 IF THE USER MAKES ANY LIFE DECISIONS, INCLUDING BUT NOT LIMITED TO FINANCIAL INVESTMENTS, HEALTHCARE DECISIONS, CAREER CHANGES, OR RELATIONSHIP DECISIONS, BASED ON OR INFLUENCED BY THE COUNTDOWN TIMER DISPLAYED BY THIS APPLICATION, ANY AND ALL CONSEQUENCES RESULTING FROM SUCH DECISIONS SHALL BE CONSIDERED FORCE MAJEURE. THE DEVELOPER EXPRESSLY DISCLAIMS ANY RESPONSIBILITY FOR ANY SUCH DECISIONS AND THEIR OUTCOMES.\n\n'
          'SECTION 5: USER REPRESENTATIONS AND ACKNOWLEDGMENTS\n\n'
          '5.1 BY USING THIS APPLICATION, YOU REPRESENT AND WARRANT THAT:\n\n'
          '(a) YOU ARE AT LEAST 18 YEARS OF AGE OR HAVE REACHED THE AGE OF MAJORITY IN YOUR JURISDICTION, OR HAVE THE LEGAL CAPACITY TO ENTER INTO A BINDING AGREEMENT;\n\n'
          '(b) IF YOU ARE UNDER THE AGE OF MAJORITY, YOU HAVE OBTAINED PARENTAL OR LEGAL GUARDIAN CONSENT TO USE THIS APPLICATION;\n\n'
          '(c) YOU HAVE THE RIGHT, AUTHORITY, AND CAPACITY TO ENTER INTO THIS AGREEMENT AND TO ABIDE BY ALL TERMS AND CONDITIONS;\n\n'
          '(d) YOU WILL USE THIS APPLICATION ONLY FOR LAWFUL PURPOSES AND IN ACCORDANCE WITH THIS AGREEMENT;\n\n'
          '(e) YOU UNDERSTAND THAT THE APPLICATION IS FOR ENTERTAINMENT ONLY AND THE COUNTDOWN TIMER IS NOT BASED ON REAL DATA.\n\n'
          '5.2 YOU ACKNOWLEDGE THAT:\n\n'
          '(a) THE APPLICATION IS NOT A TOY FOR CHILDREN AND MAY CONTAIN CONTENT THAT IS INAPPROPRIATE FOR MINORS;\n\n'
          '(b) YOUR USE OF THE APPLICATION IS AT YOUR SOLE RISK;\n\n'
          '(c) ANY INFORMATION GENERATED BY THE APPLICATION HAS NO REAL-WORLD MEANING OR SIGNIFICANCE;\n\n'
          '(d) THE DEVELOPER HAS NO OBLIGATION TO VERIFY THE IDENTITY OF ANY USER OR THE TRUTHFULNESS OF ANY INFORMATION PROVIDED.\n\n'
          'SECTION 6: DATA COLLECTION AND PRIVACY\n\n'
          '6.1 THIS APPLICATION COLLECTS AND STORES DATA LOCALLY ON YOUR DEVICE ONLY. NO PERSONAL INFORMATION IS TRANSMITTED TO ANY EXTERNAL SERVERS, CLOUD SERVICES, OR THIRD PARTIES.\n\n'
          '6.2 THE APPLICATION MAY GENERATE A UNIQUE DEVICE IDENTIFIER FOR THE PURPOSE OF LOCAL DATA STORAGE AND PERSISTENCE. THIS IDENTIFIER IS USED SOLELY TO MAINTAIN USER SETTINGS AND PREFERENCES AND IS NEVER TRANSMITTED OFF YOUR DEVICE.\n\n'
          '6.3 THE APPLICATION DOES NOT:\n\n'
          '(a) COLLECT PERSONAL INFORMATION SUCH AS NAME, ADDRESS, PHONE NUMBER, OR EMAIL ADDRESS (EXCEPT AS VOLUNTARILY PROVIDED BY THE USER FOR LOCAL STORAGE);\n\n'
          '(b) TRACK USER LOCATION OR ACCESS GPS DATA;\n\n'
          '(c) ACCESS YOUR CONTACTS, PHOTOS, OR OTHER FILES;\n\n'
          '(d) RECORD AUDIO OR VIDEO;\n\n'
          '(e) SEND NOTIFICATIONS FOR NON-APP-RELATED PURPOSES;\n\n'
          '(f) CONNECT TO THE INTERNET FOR ANY PURPOSE INCLUDING BUT NOT LIMITED TO DATA SYNC, ANALYTICS, ADVERTISING, OR CRASH REPORTING.\n\n'
          '6.4 NOTWITHSTANDING THE FOREGOING, THE DEVELOPER RESERVES THE RIGHT TO DISCLOSE PERSONAL INFORMATION AS REQUIRED BY LAW AND IN THE GOOD FAITH BELIEF THAT SUCH DISCLOSURE IS NECESSARY TO COMPLY WITH A JUDICIAL PROCEEDING, COURT ORDER, OR LEGAL PROCESS.\n\n'
          'SECTION 7: INTELLECTUAL PROPERTY\n\n'
          '7.1 ALL CONTENT, FEATURES, FUNCTIONALITIES, AND MATERIALS PRESENT IN THIS APPLICATION, INCLUDING BUT NOT LIMITED TO TEXT, GRAPHICS, LOGOS, IMAGES, AUDIO, VIDEO, SOFTWARE, AND CODE, ARE THE EXCLUSIVE PROPERTY OF THE DEVELOPER AND ARE PROTECTED BY INTERNATIONAL COPYRIGHT, PATENT, TRADEMARK, AND OTHER INTELLECTUAL PROPERTY LAWS.\n\n'
          '7.2 YOU MAY NOT COPY, MODIFY, DISTRIBUTE, SELL, LEASE, RENT, OR IN ANY MANNER EXPLOIT ANY PART OF THIS APPLICATION WITHOUT THE EXPRESS WRITTEN CONSENT OF THE DEVELOPER.\n\n'
          '7.3 THE APPLICATION NAME, LOGO, AND ALL RELATED TRADEMARKS, SERVICE MARKS, AND TRADE DRESS ARE THE PROPERTY OF THE DEVELOPER. YOU ARE PROHIBITED FROM USING THESE MARKS WITHOUT PRIOR WRITTEN PERMISSION.\n\n'
          '7.4 ANY FEEDBACK, SUGGESTIONS, IDEAS, OR ENHANCEMENTS YOU PROVIDE REGARDING THE APPLICATION SHALL BE THE SOLE PROPERTY OF THE DEVELOPER, AND YOU HEREBY ASSIGN ALL RIGHTS, TITLE, AND INTEREST IN SUCH FEEDBACK TO THE DEVELOPER.\n\n'
          'SECTION 8: PROHIBITED CONDUCT\n\n'
          '8.1 YOU AGREE NOT TO USE THE APPLICATION TO:\n\n'
          '(a) ENGAGE IN ANY UNLAWFUL ACTIVITY OR INFRINGE UPON THE RIGHTS OF OTHERS;\n\n'
          '(b) GENERATE OR DISTRIBUTE MALICIOUS CODE, VIRUSES, OR OTHER HARMFUL SOFTWARE;\n\n'
          "(c) ATTEMPT TO GAIN UNAUTHORIZED ACCESS TO ANY SYSTEMS, NETWORKS, OR DATA;\n\n"
          "(d) INTERFERE WITH OR DISRUPT THE APPLICATION'S OPERATION;\n\n"
          '(e) IMITATE OR COPY THE APPLICATION OR ITS FUNCTIONALITIES FOR COMMERCIAL PURPOSES;\n\n'
          '(f) USE THE APPLICATION IN A MANNER THAT COULD DAMAGE, DISABLE, OVERBURDEN, OR IMPAIR THE APPLICATION OR ANY SERVER OR NETWORK;\n\n'
          '(g) REVERSE ENGINEER, DECOMPILE, DISASSEMBLE, OR OTHERWISE ATTEMPT TO DERIVE THE SOURCE CODE OF THE APPLICATION;\n\n'
          '(h) REMOVE, ALTER, OR OBFUSCATE ANY PROPRIETARY NOTICES OR LABELS ON THE APPLICATION.\n\n'
          '8.2 VIOLATION OF THIS SECTION MAY RESULT IN IMMEDIATE TERMINATION OF YOUR RIGHT TO USE THE APPLICATION AND MAY SUBJECT YOU TO CIVIL AND/OR CRIMINAL LIABILITY.\n\n'
          'SECTION 9: THIRD-PARTY SERVICES AND CONTENT\n\n'
          '9.1 THE APPLICATION MAY CONTAIN LINKS TO THIRD-PARTY WEBSITES, SERVICES, OR RESOURCES THAT ARE NOT OWNED OR CONTROLLED BY THE DEVELOPER. THE DEVELOPER HAS NO CONTROL OVER, AND ASSUMES NO RESPONSIBILITY FOR, THE CONTENT, PRIVACY POLICIES, OR PRACTICES OF ANY THIRD-PARTY WEBSITES OR SERVICES.\n\n'
          '9.2 YOU ACKNOWLEDGE AND AGREE THAT THE DEVELOPER SHALL NOT BE RESPONSIBLE OR LIABLE FOR ANY LOSS OR DAMAGE CAUSED OR ALLEGED TO BE CAUSED BY OR IN CONNECTION WITH YOUR USE OF OR RELIANCE ON ANY SUCH THIRD-PARTY CONTENT, GOODS, OR SERVICES.\n\n'
          '9.3 YOUR INTERACTION WITH ANY THIRD-PARTY SERVICE IS SOLELY BETWEEN YOU AND THE THIRD PARTY. YOU SHOULD REVIEW THE TERMS AND POLICIES OF ANY THIRD-PARTY SERVICE YOU USE.\n\n'
          'SECTION 10: MODIFICATION AND TERMINATION\n\n'
          '10.1 THE DEVELOPER RESERVES THE RIGHT, AT ITS SOLE DISCRETION, TO MODIFY, SUSPEND, OR DISCONTINUE THE APPLICATION OR ANY PART THEREOF, WITH OR WITHOUT NOTICE, AT ANY TIME AND WITHOUT LIABILITY TO YOU.\n\n'
          '10.2 THE DEVELOPER RESERVES THE RIGHT TO MODIFY THIS AGREEMENT AT ANY TIME. SUCH MODIFICATIONS SHALL BECOME EFFECTIVE IMMEDIATELY UPON POSTING. YOUR CONTINUED USE OF THE APPLICATION AFTER ANY SUCH MODIFICATIONS CONSTITUTES YOUR ACCEPTANCE OF THE MODIFIED AGREEMENT.\n\n'
          '10.3 YOU MAY TERMINATE THIS AGREEMENT AT ANY TIME BY CEASING TO USE THE APPLICATION AND UNINSTALLING IT FROM YOUR DEVICE.\n\n'
          '10.4 UPON TERMINATION OF THIS AGREEMENT, ALL PROVISIONS THAT BY THEIR NATURE SHOULD SURVIVE TERMINATION SHALL SURVIVE, INCLUDING BUT NOT LIMITED TO: OWNERSHIP PROVISIONS, DISCLAIMER OF WARRANTIES, LIMITATION OF LIABILITY, INDEMNIFICATION, AND INTELLECTUAL PROPERTY RIGHTS.\n\n'
          'SECTION 11: INDEMNIFICATION\n\n'
          "11.1 YOU AGREE TO INDEMNIFY, DEFEND, AND HOLD HARMLESS THE DEVELOPER AND ITS OFFICERS, DIRECTORS, EMPLOYEES, AGENTS, AND AFFILIATES FROM AND AGAINST ANY AND ALL CLAIMS, DAMAGES, LOSSES, LIABILITIES, COSTS, AND EXPENSES (INCLUDING REASONABLE ATTORNEYS' FEES) ARISING OUT OF OR RELATING TO:\n\n"
          '(a) YOUR USE OF THE APPLICATION;\n\n'
          '(b) YOUR VIOLATION OF THIS AGREEMENT;\n\n'
          '(c) YOUR VIOLATION OF ANY RIGHTS OF A THIRD PARTY;\n\n'
          '(d) YOUR CONDUCT THAT COULD LEAD TO THE APPLICATION BEING DAMAGED, INTERRUPTED, OR OTHERWISE AFFECTED.\n\n'
          '11.2 THE DEVELOPER RESERVES THE RIGHT, AT ITS OWN EXPENSE, TO ASSUME THE EXCLUSIVE DEFENSE AND CONTROL OF ANY MATTER OTHERWISE SUBJECT TO INDEMNIFICATION BY YOU, IN WHICH CASE YOU SHALL COOPERATE WITH THE DEVELOPER IN ASSERTING ANY AVAILABLE DEFENSES.\n\n'
          'SECTION 12: GOVERNING LAW AND DISPUTE RESOLUTION\n\n'
          '12.1 THIS AGREEMENT SHALL BE GOVERNED BY AND CONSTRUED IN ACCORDANCE WITH THE LAWS OF THE JURISDICTION DETERMINED BY THE DEVELOPER, WITHOUT REGARD TO ITS CONFLICT OF LAW PROVISIONS.\n\n'
          '12.2 ANY DISPUTE ARISING OUT OF OR RELATING TO THIS AGREEMENT SHALL BE SUBJECT TO THE EXCLUSIVE JURISDICTION OF THE COURTS LOCATED IN THE aforemenTIONED JURISDICTION, AND YOU HEREBY CONSENT TO THE PERSONAL JURISDICTION OF SUCH COURTS.\n\n'
          '12.3 YOU WAIVE ANY OBJECTION TO THE LAYING OF VENUE OF ANY SUCH LITIGATION IN SUCH COURTS AND ANY CLAIM THAT SUCH COURTS ARE AN INCONVENIENT FORUM.\n\n'
          'SECTION 13: MISCELLANEOUS PROVISIONS\n\n'
          '13.1 ENTIRE AGREEMENT. THIS AGREEMENT CONSTITUTES THE ENTIRE AGREEMENT BETWEEN YOU AND THE DEVELOPER REGARDING YOUR USE OF THE APPLICATION AND SUPERSEDES ALL PRIOR OR CONTEMPORANEOUS COMMUNICATIONS, REPRESENTATIONS, OR AGREEMENTS, WHETHER ORAL OR WRITTEN.\n\n'
          '13.2 SEVERABILITY. IF ANY PROVISION OF THIS AGREEMENT IS FOUND TO BE UNENFORCEABLE OR INVALID, SUCH PROVISION SHALL BE LIMITED OR ELIMINATED TO THE MINIMUM EXTENT NECESSARY SO THAT THIS AGREEMENT SHALL OTHERWISE REMAIN IN FULL FORCE AND EFFECT.\n\n'
          '13.3 WAIVER. THE FAILURE OF THE DEVELOPER TO EXERCISE OR ENFORCE ANY RIGHT OR PROVISION OF THIS AGREEMENT SHALL NOT CONSTITUTE A WAIVER OF SUCH RIGHT OR PROVISION.\n\n'
          '13.4 ASSIGNMENT. YOU MAY NOT ASSIGN OR TRANSFER THIS AGREEMENT OR ANY RIGHTS OR OBLIGATIONS HEREUNDER WITHOUT THE PRIOR WRITTEN CONSENT OF THE DEVELOPER. THE DEVELOPER MAY ASSIGN THIS AGREEMENT WITHOUT RESTRICTION.\n\n'
          '13.5 HEADINGS. SECTION HEADINGS ARE FOR CONVENIENCE ONLY AND SHALL NOT AFFECT THE INTERPRETATION OF THIS AGREEMENT.\n\n'
          '13.6 SURVIVAL. ALL PROVISIONS THAT BY THEIR NATURE SHOULD SURVIVE TERMINATION OF THIS AGREEMENT SHALL SURVIVE, INCLUDING BUT NOT LIMITED TO OWNERSHIP PROVISIONS, DISCLAIMERS, LIMITATIONS OF LIABILITY, INDEMNIFICATION, AND INTELLECTUAL PROPERTY RIGHTS.\n\n'
          'SECTION 14: ACKNOWLEDGMENT\n\n'
          '14.1 BY CLICKING "AGREE" OR BY ACCESSING OR USING THE APPLICATION, YOU ACKNOWLEDGE THAT YOU HAVE READ THIS AGREEMENT, UNDERSTAND IT, AND AGREE TO BE BOUND BY ITS TERMS AND CONDITIONS. YOU FURTHER ACKNOWLEDGE THAT THIS AGREEMENT IS THE COMPLETE AND EXCLUSIVE STATEMENT OF THE AGREEMENT BETWEEN YOU AND THE DEVELOPER AND SUPERSEDES ALL PROPOSALS OR PRIOR AGREEMENTS, ORAL OR WRITTEN, AND ANY OTHER COMMUNICATIONS BETWEEN YOU AND THE DEVELOPER RELATING TO THE SUBJECT MATTER OF THIS AGREEMENT.\n\n'
          '14.2 YOU ACKNOWLEDGE THAT YOU HAVE HAD THE OPPORTUNITY TO SEEK INDEPENDENT LEGAL ADVICE BEFORE AGREEING TO THIS TERMS AND CONDITIONS.\n\n'
          'SECTION 15: CONTACT INFORMATION\n\n'
          'FOR ANY QUESTIONS, CONCERNS, OR REQUESTS REGARDING THIS AGREEMENT OR THE APPLICATION, PLEASE VISIT OUR GITHUB REPOSITORY AT https://github.com/ChidcGithub/CountDown.\n\n'
          'BY PROCEEDING, YOU ACKNOWLEDGE THAT YOU HAVE READ AND UNDERSTOOD THIS ENTIRE AGREEMENT AND AGREE TO BE BOUND BY ALL OF ITS TERMS AND CONDITIONS.''',
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.8),
        ),
      ),
    );
  }
}

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _nameController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _nameController.text.isNotEmpty && _selectedDate != null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Setup', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 40),
              const Text('Enter Your Name', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800), borderRadius: BorderRadius.circular(8)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 30),
              const Text('Select Your Birth Date', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(data: ThemeData.dark(useMaterial3: true), child: child!),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.red.shade800), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}' : 'Select Date',
                        style: TextStyle(color: _selectedDate != null ? Colors.white : Colors.grey.shade600, fontSize: 18),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.red),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isValid ? () async {
                    final navigator = Navigator.of(context);
                    final deviceId = (await StorageService.getDeviceId())!;
                    final deathDate = calculateDeathDate(_nameController.text, _selectedDate!, deviceId);
                    await StorageService.saveUserData(_nameController.text, _selectedDate!, deathDate);
                    if (!mounted) return;
                    navigator.pushReplacement(MaterialPageRoute(builder: (_) => MainCountdownScreen(data: CountdownData(username: _nameController.text, birthDate: _selectedDate!, deathDate: deathDate))));
                  } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, disabledBackgroundColor: Colors.grey.shade800),
                  child: const Text('START', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class MainCountdownScreen extends StatefulWidget {
  final CountdownData data;
  const MainCountdownScreen({super.key, required this.data});

  @override
  State<MainCountdownScreen> createState() => _MainCountdownScreenState();
}

class _MainCountdownScreenState extends State<MainCountdownScreen> {
  int _clickCount = 0;
  DateTime? _lastClickTime;
  bool _showSettings = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!).inMilliseconds < 500) {
      _clickCount++;
    } else {
      _clickCount = 1;
    }
    _lastClickTime = now;
    if (_clickCount >= 5) setState(() => _showSettings = true);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final years = data.years;
    final months = data.months;
    final days = data.days;
    final hours = data.hours;
    final minutes = data.minutes;
    final seconds = data.seconds;
    
    int grayFromIndex = 6;
    if (years <= 0) grayFromIndex = 0;
    if (years <= 0 && months <= 0) grayFromIndex = 1;
    if (years <= 0 && months <= 0 && days <= 0) grayFromIndex = 2;
    if (years <= 0 && months <= 0 && days <= 0 && hours <= 0) grayFromIndex = 3;
    if (years <= 0 && months <= 0 && days <= 0 && hours <= 0 && minutes <= 0) grayFromIndex = 4;
    if (years <= 0 && months <= 0 && days <= 0 && hours <= 0 && minutes <= 0 && seconds <= 0) grayFromIndex = 5;
    
    final items = [('YEAR', years, 0), ('MONTH', months, 1), ('DAY', days, 2), ('HOUR', hours, 3), ('MINUTE', minutes, 4), ('SECOND', seconds, 5)];
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(onTap: _handleTap, behavior: HitTestBehavior.opaque, child: Container(width: 100, height: 100, color: Colors.transparent)),
            Column(
              children: [
                const SizedBox(height: 20),
                Center(child: Text(data.username.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 4))),
                const SizedBox(height: 10),
                Text('BORN: ${data.birthDate.year}-${data.birthDate.month.toString().padLeft(2, '0')}-${data.birthDate.day.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                ...items.map((item) => _CountdownRow(label: item.$1, value: item.$2, isZero: item.$3 >= grayFromIndex)),
                const Spacer(),
              ],
            ),
            if (_showSettings)
              Positioned(
                top: 0,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(icon: const Icon(Icons.settings, color: Colors.red, size: 32), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountdownRow extends StatelessWidget {
  final String label;
  final int value;
  final bool isZero;
  const _CountdownRow({required this.label, required this.value, required this.isZero});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = (screenWidth * 0.28).clamp(60.0, 140.0);
    final labelFontSize = (screenWidth * 0.04).clamp(14.0, 22.0);
    return SizedBox(
      height: screenHeight / 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: screenWidth * 0.5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: isZero ? Colors.grey : Colors.red,
                  height: 1,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          SizedBox(
            width: screenWidth * 0.15,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: isZero ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _versionClicks = 0;
  int _titleClicks = 0;
  bool _devMode = false;

  @override
  void initState() {
    super.initState();
    _loadClickCounts();
  }

  Future<void> _loadClickCounts() async {
    _versionClicks = await StorageService.getDevModeVersionClicks();
    _titleClicks = await StorageService.getDevModeTitleClicks();
  }

  void _enableDevMode() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const _DevModeRedScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ));
      }
    });
  }

  void _checkDevMode() {
    if (_versionClicks >= AppConstants.versionTapCount && _titleClicks >= AppConstants.titleTapCount && !_devMode) {
      setState(() => _devMode = true);
      StorageService.setDevModeVersionClicks(0);
      StorageService.setDevModeTitleClicks(0);
      _enableDevMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: GestureDetector(
          onTap: () async {
            _titleClicks++;
            await StorageService.setDevModeTitleClicks(_titleClicks);
            _checkDevMode();
          },
          child: const Text('Settings', style: TextStyle(color: Colors.white)),
        ),
        iconTheme: const IconThemeData(color: Colors.red),
      ),
      body: ListView(
        children: [
          _buildItem('Package Name', AppConstants.packageName),
          _buildItem('Version', AppConstants.version, onTap: () async {
            _versionClicks++;
            await StorageService.setDevModeVersionClicks(_versionClicks);
            _checkDevMode();
          }),
          _buildItem('Developer', _devMode ? AppConstants.developerDevMode : AppConstants.developer, onTap: () async {
            final url = Uri.parse(AppConstants.githubUrl);
            if (await canLaunchUrl(url)) await launchUrl(url);
          }),
          if (_devMode) ...[
            const Divider(color: Colors.red),
            ListTile(title: const Text('Search Users', style: TextStyle(color: Colors.red)), trailing: const Icon(Icons.search, color: Colors.red), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchUsersScreen()))),
            ListTile(
              title: const Text('Delete All Data', style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: () async {
                final navigator = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey.shade900,
                    title: const Text('Delete All Data?', style: TextStyle(color: Colors.white)),
                    content: const Text('This will delete all local data including your countdown and settings. This action cannot be undone.', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await StorageService.clearAllData();
                  if (!mounted) return;
                  navigator.popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(String title, String value, {VoidCallback? onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      subtitle: Text(value, style: TextStyle(color: onTap != null ? Colors.red : Colors.white, fontWeight: onTap != null ? FontWeight.bold : FontWeight.normal)),
      onTap: onTap,
    );
  }
}

class _DevModeRedScreen extends StatefulWidget {
  const _DevModeRedScreen();

  @override
  State<_DevModeRedScreen> createState() => _DevModeRedScreenState();
}

class _DevModeRedScreenState extends State<_DevModeRedScreen> {
  @override
  void initState() {
    super.initState();
    _showDevModeMessage();
  }

  void _showDevModeMessage() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Developer mode enabled'), backgroundColor: Colors.red));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, color: Colors.black, size: 80),
            const SizedBox(height: 20),
            const Text('DEVELOPER MODE', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});
  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  // ==================== 静态数据 ====================
  static const int _pageSize = 30;
  
  final List<String> _firstNames = [
    'James', 'Mary', 'Robert', 'Patricia', 'John', 'Jennifer', 'Michael', 'Linda', 'David', 'Elizabeth',
    'William', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Charles', 'Karen',
    'Christopher', 'Nancy', 'Daniel', 'Lisa', 'Matthew', 'Betty', 'Anthony', 'Margaret', 'Mark', 'Sandra',
    'Donald', 'Ashley', 'Steven', 'Kimberly', 'Paul', 'Emily', 'Andrew', 'Donna', 'Joshua', 'Michelle',
    'Kenneth', 'Dorothy', 'Kevin', 'Carol', 'Brian', 'Amanda', 'George', 'Melissa', 'Timothy', 'Deborah',
    'Edward', 'Stephanie', 'Ronald', 'Rebecca', 'Jason', 'Sharon', 'Jeffrey', 'Laura', 'Ryan', 'Cynthia',
    'Jacob', 'Kathleen', 'Gary', 'Amy', 'Nicholas', 'Angela', 'Eric', 'Shirley', 'Jonathan', 'Anna',
    'Stephen', 'Brenda', 'Larry', 'Pamela', 'Justin', 'Emma', 'Scott', 'Nicole', 'Brandon', 'Helen',
    'Benjamin', 'Samantha', 'Samuel', 'Katherine', 'Raymond', 'Christine', 'Gregory', 'Debra', 'Frank', 'Rachel',
    'Alexander', 'Carolyn', 'Patrick', 'Janet', 'Jack', 'Catherine', 'Dennis', 'Maria', 'Jerry', 'Heather',
    'Tyler', ' Abigail', 'Adam', 'Adriana', 'Adrian', 'Aiden', 'Alan', 'Alec', 'Alexa', 'Alice',
    'Alicia', 'Allen', 'Amber', 'Andre', 'Andrea', 'Angel', 'Angelina', 'Angie', 'Anita', 'Ann',
    'Anna', 'Anne', 'Annie', 'Anthony', 'Antonio', 'Ariana', 'Ariel', 'Arthur', 'Ashlee', 'Ashley',
    'Audrey', 'Austin', 'Autumn', 'Ava', 'Bailey', 'Ben', 'Beverly', 'Bill', 'Billy', 'Blake',
    'Bob', 'Bobby', 'Bonnie', 'Brad', 'Bradley', 'Brady', 'Brandi', 'Brandon', 'Brandy', 'Brayden',
    'Breanna', 'Brent', 'Brett', 'Brian', 'Brooke', 'Bruce', 'Bryan', 'Bryce', 'Caleb', 'Calvin',
    'Cameron', 'Candice', 'Carla', 'Carlos', 'Carol', 'Caroline', 'Carolyn', 'Carrie', 'Casey', 'Cassandra',
    'Cassidy', 'Catherine', 'Cathy', 'Charlene', 'Charles', 'Charlie', 'Charlotte', 'Chelsea', 'Chelsey', 'Cheryl',
    'Cheyenne', 'Chris', 'Christian', 'Christina', 'Christine', 'Christopher', 'Christy', 'Cindy', 'Claire',
    'Clara', 'Clarence', 'Clayton', 'Clifford', 'Colleen', 'Colin', 'Collin', 'Colton', 'Connor', 'Corey',
    'Cory', 'Courtney', 'Craig', 'Cristina', 'Crystal', 'Cynthia', 'Dakota', 'Dale', 'Dalton', 'Damon',
    'Dan', 'Dana', 'Daniel', 'Danielle', 'Danny', 'Darin', 'Darius', 'Dave', 'David', 'Dawn'
  ];

  final List<String> _lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
    'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
    'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson',
    'Walker', 'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores',
    'Green', 'Adams', 'Nelson', 'Baker', 'Hall', 'Rivera', 'Campbell', 'Mitchell', 'Carter', 'Roberts'
  ];

  final Set<String> _excludedNames = {'admin', 'root', 'administrator', 'system', 'superuser', 'test', 'guest', 'user', 'moderator', 'owner'};

  // ==================== 控制器 ====================
  final _searchController = TextEditingController();
  final _editController = TextEditingController();
  final _scrollController = ScrollController();

  // ==================== 状态变量 ====================
  bool _loading = true;
  bool _loadingMore = false;
  bool _isLoadingMoreScheduled = false;
  
  // 用户列表
  final List<SearchUser> _users = [];
  List<SearchUser> _filteredUsers = [];
  
  // 当前用户信息
  String _currentUsername = '';
  SearchUser? _currentUser;
  int? _currentUserIndex;

  // ==================== 生命周期 ====================
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCurrentUser();
    _generateInitialUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _editController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==================== 数据加载 ====================
  Future<void> _loadCurrentUser() async {
    final userData = await StorageService.loadUserData();
    if (userData != null && mounted) {
      setState(() {
        _currentUsername = userData.username;
        _currentUser = SearchUser(
          username: userData.username,
          deathDate: userData.deathDate,
        );
      });
    }
  }

  void _generateInitialUsers() {
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 2), () {
      _generateMoreUsers();
      if (mounted) setState(() => _loading = false);
    });
  }

  // ==================== 用户生成 ====================
  SearchUser _generateRandomUser() {
    final random = Random();
    String username;
    
    // 生成唯一用户名
    do {
      final first = _firstNames[random.nextInt(_firstNames.length)];
      final last = _lastNames[random.nextInt(_lastNames.length)];
      username = '$first$last${random.nextInt(999)}';
    } while (_excludedNames.contains(username.toLowerCase()) || _users.any((u) => u.username == username));
    
    // 生成随机死亡日期
    final now = DateTime.now();
    final deathDate = DateTime(
      now.year + random.nextInt(50) + 20,
      random.nextInt(12) + 1,
      random.nextInt(28) + 1,
      random.nextInt(24),
      random.nextInt(60),
      random.nextInt(60),
      random.nextInt(1000),
    );
    
    return SearchUser(username: username, deathDate: deathDate);
  }

  void _addRandomUser() {
    final newUser = _generateRandomUser();
    _users.insert(0, newUser);
    _updateFilteredUsers();
    
    // 滚动到顶部
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _generateMoreUsers() {
    final random = Random();
    final newUsers = <SearchUser>[];
    
    for (int i = 0; i < _pageSize; i++) {
      String username;
      do {
        final first = _firstNames[random.nextInt(_firstNames.length)];
        final last = _lastNames[random.nextInt(_lastNames.length)];
        username = '$first$last';
      } while (_excludedNames.contains(username.toLowerCase()) || _users.any((u) => u.username == username));
      
      final now = DateTime.now();
      final deathDate = DateTime(
        now.year + random.nextInt(50) + 20,
        random.nextInt(12) + 1,
        random.nextInt(28) + 1,
        random.nextInt(24),
        random.nextInt(60),
        random.nextInt(60),
        random.nextInt(1000),
      );
      
      newUsers.add(SearchUser(username: username, deathDate: deathDate));
    }
    
    _users.addAll(newUsers);
    _updateFilteredUsers();
  }

  // ==================== 搜索逻辑 ====================
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && !_loading && !_isLoadingMoreScheduled) {
        _isLoadingMoreScheduled = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          _isLoadingMoreScheduled = false;
          if (!_loadingMore && !_loading && mounted) {
            _loadingMore = true;
            Future.delayed(const Duration(milliseconds: 300), () {
              _generateMoreUsers();
              if (mounted) _loadingMore = false;
            });
          }
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _updateFilteredUsers();
  }

  void _updateFilteredUsers() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      // 无搜索词：显示所有用户（不包含当前用户）
      _filteredUsers = List.from(_users);
      _currentUserIndex = null;
    } else {
      // 有搜索词：过滤匹配的用户
      _filteredUsers = _users.where((u) => u.username.toLowerCase().contains(query)).toList();
      _currentUserIndex = null;
      
      // 检查当前用户是否在结果中
      for (int i = 0; i < _filteredUsers.length; i++) {
        if (_filteredUsers[i].username == _currentUsername) {
          _currentUserIndex = i;
          break;
        }
      }
      
      // 如果当前用户匹配搜索词且不在列表中，添加到开头
      if (_currentUserIndex == null && _currentUser != null) {
        if (_currentUsername.toLowerCase().contains(query)) {
          _filteredUsers.insert(0, _currentUser!);
          _currentUserIndex = 0;
        }
      }
    }
  }

  void _scrollToCurrentUser() {
    if (_currentUserIndex != null && _currentUserIndex! < _filteredUsers.length) {
      _scrollController.animateTo(
        _currentUserIndex! * 72.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ==================== 同步功能 ====================
  void _syncToServer(SearchUser user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Colors.black,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Syncing to server...', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text('Uploading user data', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );

    // 模拟网络延迟
    await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(1500)));

    if (!mounted) return;
    Navigator.pop(context);

    // 生成随机生日并保存
    final rand = Random();
    final birthDate = DateTime.now().subtract(Duration(days: 365 * 20 + rand.nextInt(365 * 50)));
    await StorageService.saveUserData(user.username, birthDate, user.deathDate);
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Sync Complete', style: TextStyle(color: Colors.white))]),
        content: Text("${user.username}'s countdown has been synced to your device", style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: Colors.red)))],
      ),
    );
  }

  // ==================== 编辑功能 ====================
  void _showEditDialog(SearchUser user) {
    final diff = user.deathDate.difference(DateTime.now());
    _editController.text = '${diff.inDays ~/ 365}Y ${(diff.inDays % 365) ~/ 30}M ${(diff.inDays % 365) % 30}D ${diff.inHours % 24}h ${diff.inMinutes % 60}m ${diff.inSeconds % 60}s';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text("Edit ${user.username}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Format: [Years]Y [Months]M [Days]D [Hours]h [Minutes]m [Seconds]s', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: _editController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '30Y 6M 15D 12h 30m 45s',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () {
              final regex = RegExp(r'^(\d+)Y\s*(\d+)M\s*(\d+)D\s*(\d+)h\s*(\d+)m\s*(\d+)s$');
              final match = regex.firstMatch(_editController.text.trim());
              if (match != null) {
                final years = int.parse(match.group(1)!);
                final months = int.parse(match.group(2)!);
                final days = int.parse(match.group(3)!);
                final hours = int.parse(match.group(4)!);
                final minutes = int.parse(match.group(5)!);
                final seconds = int.parse(match.group(6)!);
                final newDeathDate = DateTime.now().add(Duration(days: years * 365 + months * 30 + days, hours: hours, minutes: minutes, seconds: seconds));
                setState(() => user.deathDate = newDeathDate);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid format'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ==================== 构建界面 ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Search Users', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.red),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.red), onPressed: _addRandomUser, tooltip: 'Add random user'),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search username...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      prefixIcon: const Icon(Icons.search, color: Colors.red),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800), borderRadius: BorderRadius.circular(8)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                // 定位按钮 - 仅在搜索当前用户时显示
                if (_searchController.text.isNotEmpty && _currentUserIndex != null) ...[
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.my_location, color: Colors.red), onPressed: _scrollToCurrentUser, tooltip: 'Locate your username'),
                ],
              ],
            ),
          ),
          
          // 用户列表
          if (_loading)
            const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Colors.red), SizedBox(height: 16), Text('Reading cloud data...', style: TextStyle(color: Colors.white70))])))
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _filteredUsers.length + (_loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _filteredUsers.length) return const Center(child: CircularProgressIndicator(color: Colors.red));
                  
                  final user = _filteredUsers[index];
                  final isCurrentUser = user.username == _currentUsername;
                  
                  return ListTile(
                    tileColor: isCurrentUser ? Colors.red.withValues(alpha: 0.2) : null,
                    title: Row(
                      children: [
                        Text(user.username, style: TextStyle(color: isCurrentUser ? Colors.red : Colors.white, fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal)),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                            child: const Text('YOU', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(user.countdownString, style: const TextStyle(color: Colors.red)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.cloud_upload, color: Colors.red), onPressed: () => _syncToServer(user), tooltip: 'Sync to Server'),
                        IconButton(icon: const Icon(Icons.edit, color: Colors.red), onPressed: () => _showEditDialog(user)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
}

DateTime calculateDeathDate(String username, DateTime birthDate, String deviceId) {
  final combined = '$username:${birthDate.toIso8601String()}:$deviceId';
  var hash = 0;
  for (var i = 0; i < combined.length; i++) {
    hash = ((hash << 5) - hash) + combined.codeUnitAt(i);
    hash = hash & 0xFFFFFFFF;
  }
  final age = (hash % (AppConstants.maxAge - AppConstants.minAge)) + AppConstants.minAge;
  return birthDate.add(Duration(days: 365 * age));
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CountdownApp());
}

class CountdownApp extends StatelessWidget {
  const CountdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Colors.red, secondary: Colors.red),
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainCountdownScreen(data: userData)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
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
                      const Text('User Agreement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
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
                                'This application is designed solely for entertainment purposes. The countdown timer displayed is a fictional simulation and should not be interpreted as any form of prediction, prophecy, or factual information about an individual\'s lifespan.\n\n'
                                '2. NO REAL DATA USED\n'
                                'The countdown calculation is based on a deterministic algorithm that combines username, birth date, and device identification.\n\n'
                                '3. NO LIABILITY\n'
                                'The developer shall not be held liable for any psychological, emotional, or behavioral changes that may occur as a result of using this application.\n\n'
                                '4. FORCE MAJEURE CLAUSE\n'
                                'If you make life decisions based on this application\'s countdown and experience unexpected consequences, such events shall be considered force majeure.\n\n'
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
                    builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Colors.red, surface: Colors.black)), child: child!),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              value.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GoogleFonts.orbitron().fontFamily,
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: isZero ? Colors.grey : Colors.red,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: GoogleFonts.orbitron().fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isZero ? Colors.grey.shade600 : Colors.grey.shade400,
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
  final _searchController = TextEditingController();
  final _editController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  final List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _currentUsername = '';
  int? _currentUserIndex;
  Timer? _refreshTimer;
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
    'Alexander', 'Carolyn', 'Patrick', 'Janet', 'Jack', 'Catherine', 'Dennis', 'Maria', 'Jerry', 'Heather'
  ];

  final List<String> _lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
    'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
    'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson',
    'Walker', 'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores',
    'Green', 'Adams', 'Nelson', 'Baker', 'Hall', 'Rivera', 'Campbell', 'Mitchell', 'Carter', 'Roberts'
  ];

  final List<String> _excludedNames = ['admin', 'root', 'administrator', 'system', 'superuser', 'test', 'guest', 'user', 'moderator', 'owner'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCurrentUser();
    _generateUsers();
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadCurrentUser() async {
    final userData = await StorageService.loadUserData();
    if (userData != null && mounted) {
      setState(() => _currentUsername = userData.username);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _editController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && !_loading && !_isLoadingMoreScheduled) {
        _isLoadingMoreScheduled = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          _isLoadingMoreScheduled = false;
          if (!_loadingMore && !_loading && mounted) _loadMore();
        });
      }
    }
  }

  bool _isLoadingMoreScheduled = false;

  void _loadMore() {
    if (_loadingMore) return;
    _loadingMore = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _generateMoreUsers();
        _loadingMore = false;
      }
    });
  }

  void _generateMoreUsers() {
    final random = Random();
    final newUsers = List.generate(_pageSize, (_) {
      String username;
      do {
        final first = _firstNames[random.nextInt(_firstNames.length)];
        final last = _lastNames[random.nextInt(_lastNames.length)];
        username = '$first$last';
      } while (_excludedNames.contains(username.toLowerCase()) || _users.any((u) => u['username'] == username));
      
      final now = DateTime.now();
      final deathDate = DateTime(now.year + random.nextInt(50) + 20, random.nextInt(12) + 1, random.nextInt(28) + 1, random.nextInt(24), random.nextInt(60), random.nextInt(60), random.nextInt(1000));
      
      return {'username': username, 'deathDate': deathDate.toIso8601String()};
    });
    
    _users.addAll(newUsers);
    _updateFilteredUsers();
  }

  void _updateFilteredUsers() {
    if (_searchController.text.isEmpty) {
      _filteredUsers = List.from(_users);
      _currentUserIndex = null;
    } else {
      final query = _searchController.text.toLowerCase();
      _filteredUsers = _users.where((u) => u['username'].toString().toLowerCase().contains(query)).toList();
      _currentUserIndex = null;
      for (int i = 0; i < _filteredUsers.length; i++) {
        if (_filteredUsers[i]['username'] == _currentUsername) {
          _currentUserIndex = i;
          break;
        }
      }
    }
  }

  void _scrollToCurrentUser() {
    if (_currentUserIndex != null && _currentUserIndex! < _filteredUsers.length) {
      _scrollController.animateTo(_currentUserIndex! * 72.0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      final idx = _users.indexWhere((u) => u['username'] == _currentUsername);
      if (idx != -1) {
        _scrollController.animateTo(idx * 72.0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  void _generateUsers() {
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 2), () {
      _generateMoreUsers();
      if (mounted) setState(() => _loading = false);
    });
  }

  String _calculateCountdownString(DateTime deathDate) {
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

  void _generateRandomUser() {
    final random = Random();
    String username;
    do {
      final first = _firstNames[random.nextInt(_firstNames.length)];
      final last = _lastNames[random.nextInt(_lastNames.length)];
      username = '$first$last${random.nextInt(999)}';
    } while (_excludedNames.contains(username.toLowerCase()) || _users.any((u) => u['username'] == username));
    
    final now = DateTime.now();
    final deathDate = DateTime(now.year + random.nextInt(50) + 20, random.nextInt(12) + 1, random.nextInt(28) + 1, random.nextInt(24), random.nextInt(60), random.nextInt(60), random.nextInt(1000));
    
    final newUser = {'username': username, 'deathDate': deathDate.toIso8601String()};
    _users.insert(0, newUser);
    _updateFilteredUsers();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _syncToServer(Map<String, dynamic> user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
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

    await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(1500)));

    if (!mounted) return;
    Navigator.pop(context);

    final deathDate = DateTime.parse(user['deathDate']);
    final now = DateTime.now();
    final rand = Random();
    final birthDate = now.subtract(Duration(days: 365 * 20 + rand.nextInt(365 * 50)));
    
    await StorageService.saveUserData(user['username'], birthDate, deathDate);
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Sync Complete', style: TextStyle(color: Colors.white))]),
        content: Text("${user['username']}'s countdown has been synced to your device", style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.red)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Search Users', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.red),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.red), onPressed: _generateRandomUser, tooltip: 'Add random user'),
        ],
      ),
      body: Column(
        children: [
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
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_searchController.text.isNotEmpty && _currentUserIndex != null) ...[
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.my_location, color: Colors.red), onPressed: _scrollToCurrentUser, tooltip: 'Locate your username'),
                ],
              ],
            ),
          ),
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
                  final isCurrentUser = user['username'] == _currentUsername;
                  final deathDate = DateTime.parse(user['deathDate']);
                  return ListTile(
                    tileColor: isCurrentUser ? Colors.red.withValues(alpha: 0.2) : null,
                    title: Row(
                      children: [
                        Text(user['username'], style: TextStyle(color: isCurrentUser ? Colors.red : Colors.white, fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal)),
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
                    subtitle: Text(_calculateCountdownString(deathDate), style: const TextStyle(color: Colors.red)),
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

  void _showEditDialog(Map<String, dynamic> user) {
    final deathDate = DateTime.parse(user['deathDate']);
    final now = DateTime.now();
    final diff = deathDate.difference(now);
    
    final years = diff.inDays ~/ 365;
    final months = (diff.inDays % 365) ~/ 30;
    final days = (diff.inDays % 365) % 30;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    
    _editController.text = '${years}Y ${months}M ${days}D ${hours}h ${minutes}m ${seconds}s';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text("Edit ${user['username']}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter countdown format:\n[Years]Y [Months]M [Days]D [Hours]h [Minutes]m [Seconds]s', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(controller: _editController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '30Y 6M 15D 12h 30m 45s', hintStyle: TextStyle(color: Colors.grey.shade600), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
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
                setState(() => user['deathDate'] = newDeathDate.toIso8601String());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server rejected your modification request'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class AppConstants {
  static const String appName = 'Countdown';
  static const String packageName = 'com.death.countdown';
  static const String version = '1.0.0';
  static const String developer = 'ChidcGithub';
  static const String developerDevMode = 'Death God';
  static const String githubUrl = 'https://github.com/ChidcGithub/CountDown';
  
  static const int minAge = 60;
  static const int maxAge = 100;
  static const int userCount = 50;
  static const int tapCountToShowSettings = 5;
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

  int get years => deathDate.difference(DateTime.now()).inDays ~/ 365;
  int get months => (deathDate.difference(DateTime.now()).inDays % 365) ~/ 30;
  int get days => (deathDate.difference(DateTime.now()).inDays % 365) % 30;
  int get hours => deathDate.difference(DateTime.now()).inHours % 24;
  int get minutes => deathDate.difference(DateTime.now()).inMinutes % 60;
  int get seconds => deathDate.difference(DateTime.now()).inSeconds % 60;
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
        colorScheme: const ColorScheme.dark(
          primary: Colors.red,
          secondary: Colors.red,
        ),
      ),
      home: const SplashScreen(),
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
      final hasSeen = await StorageService.hasSeenWelcome();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => hasSeen ? const UserSetupScreen() : const WelcomeScreen()));
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
                                'This application is designed solely for entertainment purposes. The countdown timer displayed is a fictional simulation and should not be interpreted as any form of prediction, prophecy, or factual information about an individual\'s lifespan. The developer makes no claims regarding the accuracy of any displayed information.\n\n'
                                '2. NO REAL DATA USED\n'
                                'The countdown calculation is based on a deterministic algorithm that combines username, birth date, and device identification. This algorithm is not based on any medical, scientific, or statistical data. The result is randomly generated and has no connection to reality.\n\n'
                                '3. NO LIABILITY\n'
                                'The developer shall not be held liable for any psychological, emotional, or behavioral changes that may occur as a result of using this application. If you find the content disturbing, please discontinue use immediately.\n\n'
                                '4. FORCE MAJEURE CLAUSE\n'
                                'If you make life decisions based on this application\'s countdown and experience unexpected consequences, such events shall be considered force majeure. The developer assumes no responsibility for any such occurrences.\n\n'
                                '5. DATA PRIVACY\n'
                                'This application does not collect, store, or transmit any personal information to external servers. All data remains local on your device. The application may generate a unique device identifier for local storage purposes only.\n\n'
                                '6. NO NETWORK COMMUNICATION\n'
                                'This application does not connect to the internet for any purpose, including but not limited to: data synchronization, analytics, advertising, or crash reporting.\n\n'
                                '7. USER RESPONSIBILITY\n'
                                'You acknowledge that you are of legal age to use this application or have obtained parental/guardian consent. You accept full responsibility for your use of this application.\n\n'
                                '8. MODIFICATION OF TERMS\n'
                                'The developer reserves the right to modify this agreement at any time without prior notice. Continued use of the application constitutes acceptance of any modified terms.\n\n'
                                '9. INTELLECTUAL PROPERTY\n'
                                'All content within this application, including but not limited to code, design, and documentation, is the intellectual property of the developer.\n\n'
                                '10. GOVERNING LAW\n'
                                'This agreement shall be governed by and construed in accordance with applicable laws.\n\n'
                                '11. ADDITIONAL INFORMATION\n'
                                'For more information, updates, and detailed documentation about this application, please visit our GitHub repository:\n'
                                'https://github.com/ChidcGithub/CountDown\n\n'
                                'By checking the box below, you acknowledge that you have read, understood, and agree to be bound by all terms and conditions outlined in this agreement.',
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
                    await StorageService.setHasSeenWelcome(true);
                    if (!mounted) return;
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserSetupScreen()));
                  } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, disabledBackgroundColor: Colors.grey.shade800, foregroundColor: Colors.white, disabledForegroundColor: Colors.grey),
                  child: Text('CONTINUE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: agreed ? Colors.white : Colors.grey)),
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
                    final deviceId = (await StorageService.getDeviceId())!;
                    final deathDate = calculateDeathDate(_nameController.text, _selectedDate!, deviceId);
                    await StorageService.saveUserData(_nameController.text, _selectedDate!, deathDate);
                    if (!mounted) return;
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainCountdownScreen(data: CountdownData(username: _nameController.text, birthDate: _selectedDate!, deathDate: deathDate))));
                  } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, disabledBackgroundColor: Colors.grey.shade800, foregroundColor: Colors.white, disabledForegroundColor: Colors.grey),
                  child: Text('START', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isValid ? Colors.white : Colors.grey)),
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
  Timer? _timer;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
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
    if (_clickCount >= AppConstants.tapCountToShowSettings) setState(() => _showSettings = true);
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
    else if (months <= 0) grayFromIndex = 1;
    else if (days <= 0) grayFromIndex = 2;
    else if (hours <= 0) grayFromIndex = 3;
    else if (minutes <= 0) grayFromIndex = 4;
    else if (seconds <= 0) grayFromIndex = 5;
    
    final items = [
      ('YEAR', years, 0),
      ('MONTH', months, 1),
      ('DAY', days, 2),
      ('HOUR', hours, 3),
      ('MINUTE', minutes, 4),
      ('SECOND', seconds, 5),
    ];
    
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
    final numberWidth = screenWidth * 0.55;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: numberWidth,
            child: Text(
              value.toString().padLeft(3, '0'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: isZero ? Colors.grey : Colors.red,
                height: 1,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: isZero ? Colors.grey.shade600 : Colors.red.shade300)),
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

  void _enableDevMode() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const _DevModeRedScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: GestureDetector(
          onTap: () {
            _titleClicks++;
            if (_devMode && _versionClicks >= AppConstants.versionTapCount && _titleClicks >= AppConstants.titleTapCount) {
              setState(() { _devMode = false; _versionClicks = 0; _titleClicks = 0; });
            }
          },
          child: const Text('Settings', style: TextStyle(color: Colors.white)),
        ),
        iconTheme: const IconThemeData(color: Colors.red),
      ),
      body: ListView(
        children: [
          _buildItem('Package Name', AppConstants.packageName),
          _buildItem('Version', AppConstants.version, onTap: () {
            _versionClicks++;
            if (_versionClicks >= AppConstants.versionTapCount && _titleClicks >= AppConstants.titleTapCount && !_devMode) {
              setState(() => _devMode = true);
              _enableDevMode();
            }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Developer mode enabled'),
            backgroundColor: Colors.red,
          ),
        );
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
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _generateUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _generateUsers() {
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 2), () {
      final random = Random();
      const firstNames = ['John', 'Alice', 'Bob', 'Emma', 'Charlie', 'Diana', 'Eve', 'Frank', 'Grace', 'Henry'];
      const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
      final generated = List.generate(AppConstants.userCount, (_) {
        final first = firstNames[random.nextInt(firstNames.length)];
        final last = lastNames[random.nextInt(lastNames.length)];
        return {'username': '$first$last', 'years': random.nextInt(50) + 20, 'months': random.nextInt(12), 'days': random.nextInt(30), 'hours': random.nextInt(24), 'minutes': random.nextInt(60), 'seconds': random.nextInt(60)};
      });
      if (mounted) setState(() { _users = generated; _loading = false; });
    });
  }

  List<Map<String, dynamic>> get _filtered => _searchController.text.isEmpty ? _users : _users.where((u) => u['username'].toString().toLowerCase().contains(_searchController.text.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('Search Users', style: TextStyle(color: Colors.white)), iconTheme: const IconThemeData(color: Colors.red)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
          if (_loading)
            const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Colors.red), SizedBox(height: 16), Text('Reading cloud data...', style: TextStyle(color: Colors.white70))])))
          else
            Expanded(child: ListView.builder(itemCount: _filtered.length, itemBuilder: (context, index) {
              final user = _filtered[index];
              return ListTile(
                title: Text(user['username'], style: const TextStyle(color: Colors.white)),
                subtitle: Text('${user['years']}Y ${user['months']}M ${user['days']}D ${user['hours']}h ${user['minutes']}m ${user['seconds']}s', style: const TextStyle(color: Colors.red)),
                trailing: const Icon(Icons.edit, color: Colors.red),
                onTap: () => _showEditDialog(user),
              );
            })),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> user) {
    _editController.text = '${user['years']}Y ${user['months']}M ${user['days']}D ${user['hours']}h ${user['minutes']}m ${user['seconds']}s';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text('Edit ${user['username']}', style: const TextStyle(color: Colors.white)),
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
                setState(() { user['years'] = int.parse(match.group(1)!); user['months'] = int.parse(match.group(2)!); user['days'] = int.parse(match.group(3)!); user['hours'] = int.parse(match.group(4)!); user['minutes'] = int.parse(match.group(5)!); user['seconds'] = int.parse(match.group(6)!); });
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

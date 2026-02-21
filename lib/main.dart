import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

String _generateUniqueId() {
  final uuid = const Uuid();
  return uuid.v4();
}

int _generateHash(String input) {
  var hash = 0;
  for (var i = 0; i < input.length; i++) {
    hash = ((hash << 5) - hash) + input.codeUnitAt(i);
    hash = hash & 0xFFFFFFFF;
  }
  return hash;
}

DateTime _calculateDeathDate(String username, DateTime birthDate, String deviceId) {
  final combined = '$username:${birthDate.toIso8601String()}:$deviceId';
  final hash = _generateHash(combined);
  final random = Random(hash);
  
  final age = random.nextInt(41) + 60;
  
  return birthDate.add(Duration(days: 365 * age));
}

Future<String> _getOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('deviceId');
  if (deviceId == null) {
    deviceId = _generateUniqueId();
    await prefs.setString('deviceId', deviceId);
  }
  return deviceId;
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
      title: 'Countdown',
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
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkFirstTime();
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

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final birthDate = prefs.getString('birthDate');
    final deathDate = prefs.getString('deathDate');
    final deviceId = prefs.getString('deviceId');
    final hasShownRecovery = prefs.getBool('hasShownRecovery') ?? false;
    
    final hasExistingData = username != null && birthDate != null && deathDate != null && deviceId != null;
    
    if (hasExistingData && !hasShownRecovery) {
      _isRecovery = true;
      _triggerRecoveryEffect();
      await prefs.setBool('hasShownRecovery', true);
    }
    
    await Future.delayed(Duration(seconds: _isRecovery ? 3 : 2));
    
    if (!mounted) return;
    
    if (hasExistingData) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainCountdownScreen(username: username, birthDate: birthDate, deathDate: deathDate)),
      );
    } else {
      final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
      if (hasSeenWelcome) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserSetupScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _flashController.value > 0.5 ? Colors.red : Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRecovery ? Icons.restore : Icons.hourglass_bottom, 
                  size: 80, 
                  color: _flashController.value > 0.5 ? Colors.black : Colors.red
                ),
                const SizedBox(height: 20),
                Text(
                  _isRecovery ? 'COUNTDOWN RESTORED' : 'COUNTDOWN',
                  style: TextStyle(
                    fontSize: _isRecovery ? 28 : 40,
                    fontWeight: FontWeight.w900,
                    color: _flashController.value > 0.5 ? Colors.black : Colors.red,
                    letterSpacing: 10,
                  ),
                ),
                if (_isRecovery) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Your countdown has been recovered',
                    style: TextStyle(
                      fontSize: 16,
                      color: _flashController.value > 0.5 ? Colors.black54 : Colors.white54,
                    ),
                  ),
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
              const SizedBox(height: 30),
              const Text(
                'JUST FOR FUN',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Do not take this seriously',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              const Text(
                'This is purely for entertainment purposes only.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade800),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'User Agreement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'By using this application, you agree to the following terms:\n\n'
                      '1. This application is for entertainment only.\n'
                      '2. The countdown displayed is not based on any real data.\n'
                      '3. If you change your fate due to this countdown, there may be force majeure factors.\n'
                      '4. This app does not upload any information to the internet, including crash reports.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: agreed,
                          onChanged: (v) => setState(() => agreed = v ?? false),
                          activeColor: Colors.red,
                        ),
                        const Expanded(
                          child: Text(
                            'I agree to the terms and conditions',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: agreed ? () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('hasSeenWelcome', true);
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const UserSetupScreen()),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey,
                  ),
                  child: Text(
                    'CONTINUE',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: agreed ? Colors.white : Colors.grey),
                  ),
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
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Setup',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Enter Your Name',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red.shade800),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Select Your Birth Date',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.red,
                            surface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade800),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                            : 'Select Date',
                        style: TextStyle(
                          color: _selectedDate != null ? Colors.white : Colors.grey.shade600,
                          fontSize: 18,
                        ),
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
                  onPressed: _nameController.text.isNotEmpty && _selectedDate != null
                      ? () async {
                          final prefs = await SharedPreferences.getInstance();
                          final deviceId = await _getOrCreateDeviceId();
                          
                          final deathDate = _calculateDeathDate(
                            _nameController.text,
                            _selectedDate!,
                            deviceId,
                          );
                          
                          await prefs.setString('username', _nameController.text);
                          await prefs.setString('birthDate', _selectedDate!.toIso8601String());
                          await prefs.setString('deathDate', deathDate.toIso8601String());
                          
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MainCountdownScreen(
                                username: _nameController.text,
                                birthDate: _selectedDate!.toIso8601String(),
                                deathDate: deathDate.toIso8601String(),
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey,
                  ),
                  child: Text(
                    'START',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _nameController.text.isNotEmpty && _selectedDate != null ? Colors.white : Colors.grey),
                  ),
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
  final String username;
  final String birthDate;
  final String deathDate;

  const MainCountdownScreen({
    super.key,
    required this.username,
    required this.birthDate,
    required this.deathDate,
  });

  @override
  State<MainCountdownScreen> createState() => _MainCountdownScreenState();
}

class _MainCountdownScreenState extends State<MainCountdownScreen> {
  int _clickCount = 0;
  DateTime? _lastClickTime;
  Timer? _timer;
  bool _showSettingsIcon = false;

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

  void _handleTopLeftClick() {
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!).inMilliseconds < 500) {
      _clickCount++;
    } else {
      _clickCount = 1;
    }
    _lastClickTime = now;

    if (_clickCount >= 5) {
      setState(() => _showSettingsIcon = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthDate = DateTime.parse(widget.birthDate);
    final deathDate = DateTime.parse(widget.deathDate);
    final now = DateTime.now();
    final difference = deathDate.difference(now);

    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;
    final days = (difference.inDays % 365) % 30;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    final items = [
      {'label': 'YEAR', 'value': years},
      {'label': 'MONTH', 'value': months},
      {'label': 'DAY', 'value': days},
      {'label': 'HOUR', 'value': hours},
      {'label': 'MINUTE', 'value': minutes},
      {'label': 'SECOND', 'value': seconds},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: _handleTopLeftClick,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.transparent,
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    widget.username.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'BORN: ${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                ...items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isZero = (item['value'] as int) <= 0;
                  return _CountdownRow(
                    label: item['label'] as String,
                    value: item['value'] as int,
                    isZero: isZero,
                  );
                }),
                const Spacer(),
              ],
            ),
            if (_showSettingsIcon)
              Positioned(
                top: 0,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.red, size: 32),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
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

  const _CountdownRow({
    required this.label,
    required this.value,
    required this.isZero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              value.toString().padLeft(3, '0'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 84,
                fontWeight: FontWeight.w900,
                color: isZero ? Colors.grey : Colors.red,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isZero ? Colors.grey.shade600 : Colors.red.shade300,
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
  int _versionClickCount = 0;
  int _titleClickCount = 0;
  bool _developerMode = false;
  bool _justEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: GestureDetector(
          onTap: () {
            _titleClickCount++;
            if (_developerMode && _versionClickCount >= 3 && _titleClickCount >= 5) {
              setState(() {
                _developerMode = false;
                _versionClickCount = 0;
                _titleClickCount = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Developer mode disabled')),
              );
            }
          },
          child: const Text(
            'Settings',
            style: TextStyle(color: Colors.white),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.red),
      ),
      body: ListView(
        children: [
          _buildItem('Package Name', 'com.death.countdown'),
          _buildItem(
            'Version',
            '1.0.0',
            onTap: () {
              _versionClickCount++;
              if (_versionClickCount >= 3 && _titleClickCount >= 5 && !_developerMode) {
                setState(() {
                  _developerMode = true;
                  _justEnabled = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Developer mode enabled')),
                );
              } else if (!_justEnabled && !_developerMode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tap Settings title ${5 - _titleClickCount} more times to enable developer mode')),
                );
              }
            },
          ),
          if (!_developerMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Tip: Tap Version 3 times + Settings title 5 times to enable developer mode',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          _buildItem(
            'Developer',
            _developerMode ? '死神' : 'ChidcGithub',
            onTap: () async {
              final url = Uri.parse('https://github.com/ChidcGithub/CountDown');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
          if (_developerMode) ...[
            const Divider(color: Colors.red),
            ListTile(
              title: const Text(
                'Search Users',
                style: TextStyle(color: Colors.red),
              ),
              trailing: const Icon(Icons.search, color: Colors.red),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
                );
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
      subtitle: Text(
        value,
        style: TextStyle(
          color: onTap != null ? Colors.red : Colors.white,
          fontWeight: onTap != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateUsers();
  }

  void _generateUsers() {
    setState(() => _loading = true);
    
    Future.delayed(const Duration(seconds: 2), () {
      final random = Random();
      final firstNames = ['John', 'Alice', 'Bob', 'Emma', 'Charlie', 'Diana', 'Eve', 'Frank', 'Grace', 'Henry'];
      final lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
      
      final List<Map<String, dynamic>> generatedUsers = [];
      for (int i = 0; i < 50; i++) {
        final firstName = firstNames[random.nextInt(firstNames.length)];
        final lastName = lastNames[random.nextInt(lastNames.length)];
        final years = random.nextInt(50) + 20;
        final months = random.nextInt(12);
        final days = random.nextInt(30);
        final hours = random.nextInt(24);
        final minutes = random.nextInt(60);
        final seconds = random.nextInt(60);
        
        generatedUsers.add({
          'username': '$firstName$lastName',
          'years': years,
          'months': months,
          'days': days,
          'hours': hours,
          'minutes': minutes,
          'seconds': seconds,
        });
      }
      
      if (mounted) {
        setState(() {
          _users = generatedUsers;
          _loading = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchController.text.isEmpty) return _users;
    return _users
        .where((u) => u['username'].toString().toLowerCase()
            .contains(_searchController.text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Search Users', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.red),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search username...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red.shade800),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Reading cloud data...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return ListTile(
                    title: Text(
                      user['username'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${user['years']}Y ${user['months']}M ${user['days']}D ${user['hours']}h ${user['minutes']}m ${user['seconds']}s',
                      style: const TextStyle(color: Colors.red),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.red),
                    onTap: () => _showEditDialog(user),
                  );
                },
              ),
            ),
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
        title: Text(
          'Edit ${user['username']}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter countdown format:\n[Years]Y [Months]M [Days]D [Hours]h [Minutes]m [Seconds]s',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _editController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '30Y 6M 15D 12h 30m 45s',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red.shade800),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              final regex = RegExp(r'^(\d+)Y\s*(\d+)M\s*(\d+)D\s*(\d+)h\s*(\d+)m\s*(\d+)s$');
              final match = regex.firstMatch(_editController.text.trim());
              
              if (match != null) {
                setState(() {
                  user['years'] = int.parse(match.group(1)!);
                  user['months'] = int.parse(match.group(2)!);
                  user['days'] = int.parse(match.group(3)!);
                  user['hours'] = int.parse(match.group(4)!);
                  user['minutes'] = int.parse(match.group(5)!);
                  user['seconds'] = int.parse(match.group(6)!);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Updated successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Server rejected your modification request'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

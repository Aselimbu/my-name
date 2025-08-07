import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_page.dart'; // Your login screen
import 'signup_page.dart'; // Optional, if you navigate manually

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC_nFWeCTFxvkz4B1TLP9hqNHoMsJGmWTA",
        authDomain: "weatherapp-setup.firebaseapp.com",
        projectId: "weatherapp-setup",
        storageBucket: "weatherapp-setup.firebasestorage.app",
        messagingSenderId: "238389692419",
        appId: "1:238389692419:web:98e897dbdf67f4bf882636",
        measurementId: "G-5FF968ZC09"
      )
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const WeatherPage(); // User is logged in
        } else {
          return const LoginPage(); // User is NOT logged in
        }
      },
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final String apiKey = 'bbc76d76cf351e4cd76e04e36e1b99eb';
  Map<String, dynamic>? weatherData;
  List<dynamic>? hourlyForecast;
  bool isLoading = false;
  String errorMessage = '';
  String currentTime = '';
  String currentDate = '';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _updateTime();
    _fadeController.forward();
  }

  void _updateTime() {
    setState(() {
      currentTime = DateFormat('HH:mm').format(DateTime.now());
      currentDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      weatherData = null;
      hourlyForecast = null;
    });

    final weatherUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
    final forecastUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric';

    try {
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (weatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(weatherResponse.body);
          hourlyForecast = jsonDecode(forecastResponse.body)['list']
              .take(4)
              .toList();
          _fadeController.reset();
          _fadeController.forward();
        });
      } else {
        setState(() {
          errorMessage = 'City not found! Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching weather. Check your connection.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.bolt;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.foggy;
      default:
        return Icons.cloud_queue;
    }
  }

  Widget buildWeatherInfo() {
    if (isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    if (errorMessage.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              errorMessage,
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    if (weatherData == null) {
      return Text(
        'Enter a city to see the weather! 🌍',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    double temp = weatherData!['main']['temp'];
    double tempMax = weatherData!['main']['temp_max'];
    double tempMin = weatherData!['main']['temp_min'];
    String cityName = weatherData!['name'];
    String weatherCondition = weatherData!['weather'][0]['main'];
    String description = weatherData!['weather'][0]['description'];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              cityName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description.capitalize(),
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              _getWeatherIcon(weatherCondition),
              color: Colors.yellowAccent,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              '${temp.toStringAsFixed(0)}°C',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Max: ${tempMax.toStringAsFixed(0)}°C',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Min: ${tempMin.toStringAsFixed(0)}°C',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => fetchWeather(_controller.text.trim()),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'Refresh',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ).copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.white.withOpacity(0.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged out successfully! 👋',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weather App',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentTime,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currentDate,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (value) => fetchWeather(value.trim()),
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Search city',
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                    hintText: 'Enter city name',
                    hintStyle: GoogleFonts.poppins(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          weatherData = null;
                          hourlyForecast = null;
                          errorMessage = '';
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: Center(child: buildWeatherInfo())),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hourly Forecast',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Today, $currentDate',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    hourlyForecast != null && hourlyForecast!.isNotEmpty
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: hourlyForecast!.asMap().entries.map((entry) {
                                var forecast = entry.value;
                                String time = DateFormat('HH:mm').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        forecast['dt'] * 1000));
                                String temp =
                                    '${forecast['main']['temp'].toStringAsFixed(0)}°C';
                                String condition = forecast['weather'][0]['main'];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: _buildHourlyForecast(time, temp, condition),
                                );
                              }).toList(),
                            ),
                          )
                        : Text(
                            'No forecast available',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(String time, String temp, String condition) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            time,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Icon(_getWeatherIcon(condition), color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(
            temp,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
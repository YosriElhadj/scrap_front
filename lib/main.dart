// main.dart - Enhanced UI
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'models/property.dart';
import 'screens/property_list_screen.dart';
import 'screens/valuation_screen.dart';
import 'screens/map_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart'; // New theme file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(LandValueApp());
}

class LandValueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Land Value Estimator',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: AppTheme.lightTheme, // Use custom theme
      darkTheme: AppTheme.darkTheme,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ApiService apiService = ApiService();
  Position? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';

  final List<Widget> _screens = [];
  
  @override
  void initState() {
    super.initState();
    _determinePosition();
  }
  
  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied.';
            _isLoading = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        
        // Initialize screens with current position
        _screens.clear();
        _screens.addAll([
          MapScreen(
            initialPosition: LatLng(position.latitude, position.longitude),
            apiService: apiService,
          ),
          PropertyListScreen(
            apiService: apiService,
            initialPosition: LatLng(position.latitude, position.longitude),
          ),
          ValuationScreen(
            apiService: apiService,
            initialPosition: LatLng(position.latitude, position.longitude),
          ),
        ]);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error determining position: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Enhanced loading screen
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.map,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 24),
                // App name
                Text(
                  'Land Value Estimator',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 40),
                // Loading indicator
                Container(
                  width: 200,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        backgroundColor: Colors.green.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading your location...',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
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
    
    // Enhanced error screen
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Location Access Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _determinePosition,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      'Grant Permission',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Enhanced main screen with bottom navigation
    return Scaffold(
      body: _screens.isNotEmpty ? _screens[_selectedIndex] : Container(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Properties',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calculate),
                label: 'Valuation',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey.shade600,
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
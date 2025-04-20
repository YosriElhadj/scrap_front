// main.dart
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
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.green[700],
        colorScheme: ColorScheme.dark(
          secondary: Colors.greenAccent,
        ),
      ),
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
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading your location...'),
            ],
          ),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 20),
              Text(_errorMessage),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _determinePosition,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: _screens.isNotEmpty ? _screens[_selectedIndex] : Container(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
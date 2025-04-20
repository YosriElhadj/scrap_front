// services/api_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/property.dart';
import '../models/valuation_result.dart';

class ApiService {
  final String baseUrl;
  
  ApiService() : baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.119:5000/api';
  
  // Get nearby properties
  Future<List<Property>> getNearbyProperties(LatLng position, {double radius = 5000, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/nearby?lat=${position.latitude}&lng=${position.longitude}&radius=$radius&limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load properties: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching nearby properties: $e');
      throw e;
    }
  }
  
  // Search properties by address
  Future<Map<String, dynamic>> searchProperties(String address) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/search?address=${Uri.encodeComponent(address)}'),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        final geocodedLocation = data['geocodedLocation'];
        final List<dynamic> propertiesJson = data['properties'];
        final properties = propertiesJson.map((json) => Property.fromJson(json)).toList();
        
        return {
          'geocodedLocation': geocodedLocation,
          'properties': properties,
        };
      } else {
        throw Exception('Failed to search properties: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching properties: $e');
      throw e;
    }
  }
  
  // Estimate land value
  Future<ValuationResult> estimateLandValue({
    required LatLng position,
    required double area,
    String zoning = 'residential',
    bool nearWater = false,
    bool roadAccess = true,
    bool utilities = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/valuation/estimate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lat': position.latitude,
          'lng': position.longitude,
          'area': area,
          'zoning': zoning,
          'features': {
            'nearWater': nearWater,
            'roadAccess': roadAccess,
            'utilities': utilities,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ValuationResult.fromJson(data);
      } else {
        throw Exception('Failed to estimate value: ${response.statusCode}');
      }
    } catch (e) {
      print('Error estimating land value: $e');
      throw e;
    }
  }
  
  // Initiate scraping for a location
  Future<Map<String, dynamic>> scrapeLandListings(String location) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scrape/listings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'location': location,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to initiate scraping: ${response.statusCode}');
      }
    } catch (e) {
      print('Error initiating scraping: $e');
      throw e;
    }
  }
}
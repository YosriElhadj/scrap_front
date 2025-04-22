// lib/services/api_service.dart - IMPROVED VERSION
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/property.dart';
import '../models/valuation_result.dart';

class ApiService {
  final String baseUrl;
  
  // Constructor with default value from .env or hardcoded fallback
  ApiService() : baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.87:5000/api';
  
  // Get nearby properties with improved error handling and fallbacks
  Future<List<Property>> getNearbyProperties(LatLng position, {double radius = 5000, int limit = 20}) async {
    try {
      print('Fetching nearby properties at: ${position.latitude}, ${position.longitude}');
      final url = '$baseUrl/properties/nearby?lat=${position.latitude}&lng=${position.longitude}&radius=$radius&limit=$limit';
      print('Request URL: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );
      
      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          // Check if response is empty
          if (response.body.isEmpty) {
            print('Warning: Empty response from API');
            return [];
          }
          
          // Try to parse as a JSON array
          final List<dynamic> jsonResponse = json.decode(response.body);
          print('Received ${jsonResponse.length} properties from API');
          
          if (jsonResponse.isEmpty) {
            print('Warning: Empty array from API');
            return [];
          }
          
          // Map each JSON object to a Property
          final properties = jsonResponse
              .where((item) => item != null)
              .map((json) {
                try {
                  return Property.fromJson(json);
                } catch (e) {
                  print('Error parsing property: $e');
                  print('Property data: $json');
                  return null;
                }
              })
              .where((prop) => prop != null)
              .cast<Property>()
              .toList();
              
          print('Successfully parsed ${properties.length} properties');
          return properties;
        } catch (parseError) {
          print('Error parsing response JSON: $parseError');
          // Try alternate format (sometimes the API wraps the response in an object)
          try {
            final Map<String, dynamic> mapResponse = json.decode(response.body);
            
            // Check if the response contains a properties array
            if (mapResponse.containsKey('properties') && mapResponse['properties'] is List) {
              final List<dynamic> propertiesList = mapResponse['properties'];
              
              // Map each JSON object to a Property
              final properties = propertiesList
                  .where((item) => item != null)
                  .map((json) => Property.fromJson(json))
                  .toList();
                  
              print('Parsed ${properties.length} properties from alternate format');
              return properties;
            } else {
              throw Exception('Properties list not found in response');
            }
          } catch (alternateError) {
            print('Error parsing alternate response format: $alternateError');
            throw Exception('Failed to parse API response: $parseError');
          }
        }
      } else {
        final errorBody = response.body;
        print('API error response (${response.statusCode}): $errorBody');
        throw Exception('Failed to load properties: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getNearbyProperties: $e');
      rethrow;
    }
  }
  
  // Search properties by address with enhanced error handling
  Future<Map<String, dynamic>> searchProperties(String address) async {
    try {
      print('Searching properties with address: $address');
      final url = '$baseUrl/properties/search?address=${Uri.encodeComponent(address)}';
      print('Request URL: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );
      
      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Create a result with fallbacks for missing data
        Map<String, dynamic> result = {};
        
        // Handle geocoded location
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('geocodedLocation')) {
            result['geocodedLocation'] = jsonResponse['geocodedLocation'];
          } else {
            // Create a default geocoded location from the original search
            result['geocodedLocation'] = {
              'lat': 0.0,
              'lng': 0.0,
              'formattedAddress': address
            };
          }
          
          // Handle properties list
          List<Property> properties = [];
          
          if (jsonResponse.containsKey('properties') && jsonResponse['properties'] is List) {
            try {
              properties = (jsonResponse['properties'] as List)
                  .map((json) => Property.fromJson(json))
                  .toList();
            } catch (e) {
              print('Error parsing properties: $e');
            }
          }
          
          result['properties'] = properties;
          return result;
        } else if (jsonResponse is List) {
          // If the response is a list, assume it's a list of properties directly
          try {
            final properties = jsonResponse
                .map((json) => Property.fromJson(json))
                .toList();
                
            // Create mock geocoded location
            final geocodedLocation = {
              'lat': properties.isNotEmpty ? properties[0].location.latitude : 0.0,
              'lng': properties.isNotEmpty ? properties[0].location.longitude : 0.0,
              'formattedAddress': address
            };
            
            return {
              'geocodedLocation': geocodedLocation,
              'properties': properties
            };
          } catch (e) {
            print('Error parsing properties list: $e');
            throw Exception('Failed to parse properties list: $e');
          }
        } else {
          throw Exception('Unexpected API response format');
        }
      } else {
        final errorBody = response.body;
        print('API error response (${response.statusCode}): $errorBody');
        throw Exception('Failed to search properties: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in searchProperties: $e');
      rethrow;
    }
  }
  
  // Estimate land value with improved error handling
 Future<ValuationResult> estimateLandValue({
  required LatLng position,
  required double area,
  String zoning = 'residential',
  bool nearWater = false,
  bool roadAccess = true,
  bool utilities = true,
}) async {
  try {
    print('Estimating land value at: ${position.latitude}, ${position.longitude}');
    final url = '$baseUrl/valuation/estimate';
    
    final body = {
      'lat': position.latitude,
      'lng': position.longitude,
      'area': area,
      'zoning': zoning,
      'features': {
        'nearWater': nearWater,
        'roadAccess': roadAccess,
        'utilities': utilities,
      }
    };
    
    print('Request body: ${json.encode(body)}');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(
      Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Connection timeout. Please check your internet connection.');
      },
    );
    
    print('Response status code: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      try {
        final rawResponse = response.body;
        if (rawResponse.isEmpty) {
          throw Exception('Empty response received from server');
        }
        
        print('Raw response: ${rawResponse.substring(0, min(200, rawResponse.length))}...');
        
        final Map<String, dynamic> jsonResponse = json.decode(rawResponse);
        
        // Debug the response structure
        print('Response keys: ${jsonResponse.keys.toList()}');
        
        if (jsonResponse.containsKey('success') && jsonResponse['success'] == false) {
          throw Exception(jsonResponse['message'] ?? 'Valuation failed on server');
        }
        
        // Check for required fields and log if they're missing
        if (!jsonResponse.containsKey('location')) {
          print('Warning: location field missing from response');
        }
        if (!jsonResponse.containsKey('valuation')) {
          print('Warning: valuation field missing from response');
        }
        if (!jsonResponse.containsKey('comparables')) {
          print('Warning: comparables field missing from response');
        }
        
        // Create a ValuationResult with the response, providing defaults if needed
        Map<String, dynamic> valuationData = {
          'location': jsonResponse.containsKey('location') ? jsonResponse['location'] : {
            'lat': position.latitude,
            'lng': position.longitude,
            'address': 'Unknown location',
          },
          'valuation': jsonResponse.containsKey('valuation') ? jsonResponse['valuation'] : {
            'estimatedValue': 0,
            'areaInSqFt': area,
            'avgPricePerSqFt': 0,
            'zoning': zoning,
            'valuationFactors': [],
          },
          'comparables': jsonResponse.containsKey('comparables') ? jsonResponse['comparables'] : [],
        };
        
        return ValuationResult.fromJson(valuationData);
      } catch (parseError) {
        print('Error parsing valuation response: $parseError');
        throw Exception('Failed to parse valuation response: $parseError');
      }
    } else {
      final errorBody = response.body;
      print('API error response (${response.statusCode}): $errorBody');
      throw Exception('Failed to estimate value: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in estimateLandValue: $e');
    rethrow;
  }
}
  
  // Get property by ID with error handling
  Future<Property> getPropertyById(String id) async {
    try {
      print('Fetching property with ID: $id');
      final url = '$baseUrl/properties/$id';
      
      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return Property.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to get property: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPropertyById: $e');
      rethrow;
    }
  }
  
  // Health check method to verify API connectivity
  Future<bool> checkApiHealth() async {
    try {
      final url = '$baseUrl/health';
      print('Checking API health: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Health check timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> healthData = json.decode(response.body);
        
        // API is considered healthy if the status is 'ok' and database is connected
        final bool isHealthy = 
            healthData.containsKey('status') && 
            healthData['status'] == 'ok' &&
            healthData.containsKey('dbStatus') && 
            healthData['dbStatus'] == 'connected';
            
        print('API health check result: $isHealthy');
        return isHealthy;
      } else {
        print('API health check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('API health check error: $e');
      return false;
    }
  }
}
// Helper to get min value
int min(int a, int b) {
  return a < b ? a : b;
}
// services/api_service.dart - FIXED VERSION
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/property.dart';
import '../models/valuation_result.dart';

class ApiService {
  final String baseUrl;
  
  ApiService() : baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.100.4:5000/api';
  
  // Get nearby properties with comprehensive error handling and debugging
  Future<List<Property>> getNearbyProperties(LatLng position, {double radius = 5000, int limit = 20}) async {
    try {
      print('Fetching nearby properties at: ${position.latitude}, ${position.longitude}');
      final url = '$baseUrl/properties/nearby?lat=${position.latitude}&lng=${position.longitude}&radius=$radius&limit=$limit';
      print('Request URL: $url');
      
      final response = await http.get(Uri.parse(url));
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body.substring(0, min(150, response.body.length))}...');
      
      if (response.statusCode == 200) {
        // Detailed parsing with debug info
        try {
          final dynamic jsonResponse = json.decode(response.body);
          print('Decoded response type: ${jsonResponse.runtimeType}');
          
          // Handle empty responses better
          if (jsonResponse == null) {
            print('Warning: Null response from API');
            return [];
          }
          
          if (jsonResponse is List) {
            if (jsonResponse.isEmpty) {
              print('Warning: Empty array from API');
              return [];
            }
            
            print('Response is a List with ${jsonResponse.length} items');
            print('First item keys: ${jsonResponse[0]?.keys?.toList() ?? "null item"}');
            
            // Try to create properties from the list
            final properties = jsonResponse
                .where((item) => item != null)
                .map((json) {
                  try {
                    return Property.fromJson(json);
                  } catch (e) {
                    print('Error parsing property: $e');
                    print('Property JSON: ${json.toString().substring(0, min(150, json.toString().length))}');
                    return null;
                  }
                })
                .where((prop) => prop != null)
                .cast<Property>()
                .toList();
                
            print('Successfully parsed ${properties.length} properties');
            return properties;
          } else if (jsonResponse is Map) {
            print('Response is a Map with keys: ${jsonResponse.keys.toList()}');
            
            // Check for different possible property list locations
            List<dynamic>? propList;
            
            if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
              propList = jsonResponse['data'];
              print('Found properties in "data" field');
            } else if (jsonResponse.containsKey('properties') && jsonResponse['properties'] is List) {
              propList = jsonResponse['properties'];
              print('Found properties in "properties" field');
            } else if (jsonResponse.containsKey('success') && jsonResponse['success'] == true) {
              // Try to find any list in the response
              for (var key in jsonResponse.keys) {
                if (jsonResponse[key] is List && (jsonResponse[key] as List).isNotEmpty) {
                  propList = jsonResponse[key];
                  print('Found potential properties in "$key" field');
                  break;
                }
              }
            }
            
            if (propList != null) {
              if (propList.isEmpty) {
                print('Warning: Empty property list field');
                return [];
              }
              
              // Try to create properties from the list
              final properties = propList
                  .where((item) => item != null)
                  .map((json) {
                    try {
                      return Property.fromJson(json);
                    } catch (e) {
                      print('Error parsing property: $e');
                      return null;
                    }
                  })
                  .where((prop) => prop != null)
                  .cast<Property>()
                  .toList();
                  
              print('Successfully parsed ${properties.length} properties from field');
              return properties;
            } else {
              print('No property list field found in response');
              throw Exception('Could not find properties in API response');
            }
          } else {
            print('Unexpected response type: ${jsonResponse.runtimeType}');
            throw Exception('Unexpected API response type: ${jsonResponse.runtimeType}');
          }
        } catch (parseError) {
          print('Error parsing response JSON: $parseError');
          throw Exception('Failed to parse API response: $parseError');
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
  
  // Helper method for min value (to avoid importing dart:math)
  int min(int a, int b) => a < b ? a : b;
  
  // Search properties by address with improved error handling
  Future<Map<String, dynamic>> searchProperties(String address) async {
    try {
      print('Searching properties with address: $address');
      final url = '$baseUrl/properties/search?address=${Uri.encodeComponent(address)}';
      print('Request URL: $url');
      
      final response = await http.get(Uri.parse(url));
      
      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Response keys: ${jsonResponse is Map ? jsonResponse.keys.toList() : "Not a Map"}');
        
        // Create a result with fallbacks
        Map<String, dynamic> result = {};
        
        // Handle geocoded location
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('geocodedLocation')) {
            result['geocodedLocation'] = jsonResponse['geocodedLocation'];
          } else if (jsonResponse.containsKey('location')) {
            result['geocodedLocation'] = jsonResponse['location'];
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
          } else if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
            try {
              properties = (jsonResponse['data'] as List)
                  .map((json) => Property.fromJson(json))
                  .toList();
            } catch (e) {
              print('Error parsing data: $e');
            }
          } else {
            print('No properties found in search result');
          }
          
          result['properties'] = properties;
          return result;
        } else {
          throw Exception('Unexpected API response format: not a Map');
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
      );
      
      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          print('Response keys: ${jsonResponse is Map ? jsonResponse.keys.toList() : "Not a Map"}');
          
          if (jsonResponse is Map<String, dynamic>) {
            // Look for the actual valuation data
            Map<String, dynamic> valuationData = jsonResponse;
            
            // Check if the response is wrapped in a 'success' field
            if (jsonResponse.containsKey('success')) {
              if (jsonResponse.containsKey('location') && 
                  jsonResponse.containsKey('valuation') && 
                  jsonResponse.containsKey('comparables')) {
                // The main data is at the root
                valuationData = jsonResponse;
              } else if (jsonResponse.containsKey('data') && 
                         jsonResponse['data'] is Map<String, dynamic>) {
                // The main data is in the 'data' field
                valuationData = jsonResponse['data'];
              } else {
                print('Cannot find valuation data. Keys: ${jsonResponse.keys.toList()}');
                throw Exception('Valuation data not found in response');
              }
            }
            
            // Verify the valuationData has all required fields
            if (!valuationData.containsKey('location') || 
                !valuationData.containsKey('valuation') || 
                !valuationData.containsKey('comparables')) {
              print('Valuation data missing required fields. Keys: ${valuationData.keys.toList()}');
              throw Exception('Valuation response missing required fields');
            }
            
            return ValuationResult.fromJson(valuationData);
          } else {
            throw Exception('Unexpected API response type: ${jsonResponse.runtimeType}');
          }
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
  
  // Initiate scraping for a location
  Future<Map<String, dynamic>> scrapeLandListings(String location) async {
    try {
      print('Initiating scrape for location: $location');
      
      final response = await http.post(
        Uri.parse('$baseUrl/scrape/listings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'location': location,
        }),
      );
      
      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = response.body;
        print('API error response (${response.statusCode}): $errorBody');
        throw Exception('Failed to initiate scraping: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in scrapeLandListings: $e');
      rethrow;
    }
  }
}
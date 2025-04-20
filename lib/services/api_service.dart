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
  
  // Get nearby properties with improved error handling
  Future<List<Property>> getNearbyProperties(LatLng position, {double radius = 5000, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/nearby?lat=${position.latitude}&lng=${position.longitude}&radius=$radius&limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        
        // Handle both array and object response formats
        if (jsonResponse is List) {
          // Original expected format - directly a list
          return jsonResponse.map((json) => Property.fromJson(json)).toList();
        } else if (jsonResponse is Map) {
          // New API format returns an object with data field containing the list
          // Check if it contains a 'data' field with the properties array
          if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
            return (jsonResponse['data'] as List)
                .map((json) => Property.fromJson(json))
                .toList();
          } else if (jsonResponse.containsKey('properties') && jsonResponse['properties'] is List) {
            // Alternative field name
            return (jsonResponse['properties'] as List)
                .map((json) => Property.fromJson(json))
                .toList();
          } else {
            // For debugging - see what fields are actually in the response
            print('Response keys: ${jsonResponse.keys.toList()}');
            throw Exception('Unexpected API response format. Expected a list of properties or an object with "data" field.');
          }
        } else {
          throw Exception('Unexpected API response type');
        }
      } else {
        final errorBody = response.body;
        print('API error response: $errorBody');
        throw Exception('Failed to load properties: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching nearby properties: $e');
      throw e;
    }
  }
  
  // Search properties by address with improved error handling
  Future<Map<String, dynamic>> searchProperties(String address) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/search?address=${Uri.encodeComponent(address)}'),
      );
      
      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        
        // Check if the response format matches what we expect
        if (jsonResponse is Map<String, dynamic>) {
          Map<String, dynamic> result = {};
          
          // Handle both possible response formats
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
          
          // Handle properties list in different formats
          List<Property> properties = [];
          if (jsonResponse.containsKey('properties') && jsonResponse['properties'] is List) {
            properties = (jsonResponse['properties'] as List)
                .map((json) => Property.fromJson(json))
                .toList();
          } else if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
            properties = (jsonResponse['data'] as List)
                .map((json) => Property.fromJson(json))
                .toList();
          } else {
            print('No properties found in response: ${jsonResponse.keys.toList()}');
          }
          
          result['properties'] = properties;
          return result;
        } else {
          throw Exception('Unexpected API response format');
        }
      } else {
        final errorBody = response.body;
        print('API error response: $errorBody');
        throw Exception('Failed to search properties: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching properties: $e');
      throw e;
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
        final dynamic jsonResponse = json.decode(response.body);
        
        // Handle both possible response formats
        if (jsonResponse is Map<String, dynamic>) {
          // Check if the response is wrapped in a 'success' field
          if (jsonResponse.containsKey('success')) {
            // Extract the actual data
            if (jsonResponse.containsKey('location') && 
                jsonResponse.containsKey('valuation') && 
                jsonResponse.containsKey('comparables')) {
              return ValuationResult.fromJson(jsonResponse);
            } else if (jsonResponse.containsKey('data') && 
                      jsonResponse['data'] is Map<String, dynamic>) {
              return ValuationResult.fromJson(jsonResponse['data']);
            } else {
              print('Unexpected response format: ${jsonResponse.keys.toList()}');
              throw Exception('Valuation data not found in response');
            }
          } else {
            // Direct response format
            return ValuationResult.fromJson(jsonResponse);
          }
        } else {
          throw Exception('Unexpected API response type');
        }
      } else {
        final errorBody = response.body;
        print('API error response: $errorBody');
        throw Exception('Failed to estimate value: ${response.statusCode}');
      }
    } catch (e) {
      print('Error estimating land value: $e');
      throw e;
    }
  }
  
  // Initiate scraping for a location with improved error handling
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
        final errorBody = response.body;
        print('API error response: $errorBody');
        throw Exception('Failed to initiate scraping: ${response.statusCode}');
      }
    } catch (e) {
      print('Error initiating scraping: $e');
      throw e;
    }
  }
}
// lib/debug_tools.dart - Enhanced Version

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'models/property.dart';

class ApiDebugTool {
  // Test all endpoints and report results with detailed output
  static Future<void> testAllEndpoints(BuildContext context, String baseUrl) async {
    final results = <String, dynamic>{};
    
    // Check server health first
    try {
      final healthResponse = await http.get(
        Uri.parse('$baseUrl/health'),
      );
      results['Health Status'] = healthResponse.statusCode;
      results['Health Body'] = _formatJson(healthResponse.body);
      
      // If health check fails, don't continue
      if (healthResponse.statusCode != 200) {
        _showResultsDialog(context, results);
        return;
      }
    } catch (e) {
      results['Health Error'] = e.toString();
      _showResultsDialog(context, results);
      return;
    }
    
    // Test Raw Properties API (direct MongoDB query for debugging)
    try {
      final rawPropertiesEndpoint = '$baseUrl/properties/nearby?lat=37.7749&lng=-122.4194&radius=5000&limit=10';
      results['Raw Request URL'] = rawPropertiesEndpoint;
      
      final rawPropertiesResponse = await http.get(
        Uri.parse(rawPropertiesEndpoint),
      );
      
      results['Raw Properties Status'] = rawPropertiesResponse.statusCode;
      
      // Try to interpret the response
      if (rawPropertiesResponse.statusCode == 200) {
        final rawResponseBody = rawPropertiesResponse.body;
        results['Raw Response Length'] = rawResponseBody.length;
        
        if (rawResponseBody.isEmpty) {
          results['Raw Properties Body'] = "EMPTY RESPONSE";
        } else {
          try {
            final dynamic jsonData = json.decode(rawResponseBody);
            
            if (jsonData is List) {
              results['Raw Response Type'] = "List with ${jsonData.length} items";
              if (jsonData.isNotEmpty) {
                results['First Item Keys'] = jsonData[0] is Map ? jsonData[0].keys.toList() : "Not a Map";
                
                // Try to create a Property object
                try {
                  final property = Property.fromJson(jsonData[0]);
                  results['Sample Property Parse'] = "Success: ${property.address}";
                } catch (parseError) {
                  results['Sample Property Parse Error'] = parseError.toString();
                }
              }
            } else if (jsonData is Map) {
              results['Raw Response Type'] = "Map with keys: ${jsonData.keys.toList()}";
            } else {
              results['Raw Response Type'] = jsonData.runtimeType.toString();
            }
            
            // Only show part of the response to avoid overwhelming the dialog
            results['Raw Properties Preview'] = _formatJson(rawResponseBody.substring(0, rawResponseBody.length > 500 ? 500 : rawResponseBody.length) + (rawResponseBody.length > 500 ? "..." : ""));
          } catch (jsonError) {
            results['Raw JSON Parse Error'] = jsonError.toString();
            results['Raw Properties Preview'] = rawResponseBody.substring(0, rawResponseBody.length > 100 ? 100 : rawResponseBody.length) + (rawResponseBody.length > 100 ? "..." : "");
          }
        }
      } else {
        results['Raw Properties Body'] = rawPropertiesResponse.body;
      }
    } catch (e) {
      results['Raw Properties Error'] = e.toString();
    }
    
    // Test Get Nearby Properties
    try {
      final nearbyPropertiesResponse = await http.get(
        Uri.parse('$baseUrl/properties/nearby?lat=37.7749&lng=-122.4194&radius=5000&limit=10'),
      );
      results['Nearby Properties Status'] = nearbyPropertiesResponse.statusCode;
      
      if (nearbyPropertiesResponse.statusCode == 200) {
        _analyzePropertiesResponse(nearbyPropertiesResponse.body, results, 'Nearby');
      } else {
        results['Nearby Properties Body'] = nearbyPropertiesResponse.body;
      }
    } catch (e) {
      results['Nearby Properties Error'] = e.toString();
    }
    
    // Test Search Properties
    try {
      final searchPropertiesResponse = await http.get(
        Uri.parse('$baseUrl/properties/search?address=${Uri.encodeComponent("San Francisco, CA")}'),
      );
      results['Search Properties Status'] = searchPropertiesResponse.statusCode;
      
      if (searchPropertiesResponse.statusCode == 200) {
        final searchResponseBody = searchPropertiesResponse.body;
        
        try {
          final dynamic jsonData = json.decode(searchResponseBody);
          
          if (jsonData is Map) {
            results['Search Response Keys'] = jsonData.keys.toList();
            
            if (jsonData.containsKey('geocodedLocation')) {
              results['Search Geocoded Location'] = jsonData['geocodedLocation'];
            }
            
            if (jsonData.containsKey('properties') && jsonData['properties'] is List) {
              results['Search Properties Count'] = (jsonData['properties'] as List).length;
              _analyzePropertyList(jsonData['properties'], results, 'Search');
            } else {
              results['Search Properties Missing'] = "No 'properties' field or not a list";
            }
          } else {
            results['Search Response Type'] = jsonData.runtimeType.toString();
          }
          
          results['Search Properties Preview'] = _formatJson(searchResponseBody.substring(0, searchResponseBody.length > 500 ? 500 : searchResponseBody.length) + (searchResponseBody.length > 500 ? "..." : ""));
        } catch (jsonError) {
          results['Search JSON Parse Error'] = jsonError.toString();
          results['Search Properties Preview'] = searchResponseBody.substring(0, searchResponseBody.length > 100 ? 100 : searchResponseBody.length);
        }
      } else {
        results['Search Properties Body'] = searchPropertiesResponse.body;
      }
    } catch (e) {
      results['Search Properties Error'] = e.toString();
    }
    
    // Test Valuation Estimate
    try {
      final valuationResponse = await http.post(
        Uri.parse('$baseUrl/valuation/estimate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lat': 37.7749,
          'lng': -122.4194,
          'area': 10000,
          'zoning': 'residential',
          'features': {
            'nearWater': false,
            'roadAccess': true,
            'utilities': true,
          }
        }),
      );
      results['Valuation Status'] = valuationResponse.statusCode;
      
      if (valuationResponse.statusCode == 200) {
        final valuationResponseBody = valuationResponse.body;
        
        try {
          final dynamic jsonData = json.decode(valuationResponseBody);
          
          if (jsonData is Map) {
            results['Valuation Response Keys'] = jsonData.keys.toList();
            
            if (jsonData.containsKey('success')) {
              results['Valuation Success'] = jsonData['success'];
            }
            
            if (jsonData.containsKey('valuation')) {
              results['Valuation Data'] = jsonData['valuation'];
            }
            
            if (jsonData.containsKey('comparables') && jsonData['comparables'] is List) {
              results['Valuation Comparables Count'] = (jsonData['comparables'] as List).length;
            }
          } else {
            results['Valuation Response Type'] = jsonData.runtimeType.toString();
          }
          
          results['Valuation Preview'] = _formatJson(valuationResponseBody.substring(0, valuationResponseBody.length > 500 ? 500 : valuationResponseBody.length) + (valuationResponseBody.length > 500 ? "..." : ""));
        } catch (jsonError) {
          results['Valuation JSON Parse Error'] = jsonError.toString();
          results['Valuation Preview'] = valuationResponseBody.substring(0, valuationResponseBody.length > 100 ? 100 : valuationResponseBody.length);
        }
      } else {
        results['Valuation Body'] = valuationResponse.body;
      }
    } catch (e) {
      results['Valuation Error'] = e.toString();
    }
    
    // Show results dialog
    _showResultsDialog(context, results);
  }
  
  // Helper to analyze properties response
  static void _analyzePropertiesResponse(String responseBody, Map<String, dynamic> results, String prefix) {
    if (responseBody.isEmpty) {
      results['${prefix} Properties Body'] = "EMPTY RESPONSE";
      return;
    }
    
    try {
      final dynamic jsonData = json.decode(responseBody);
      
      if (jsonData is List) {
        results['${prefix} Response Type'] = "List with ${jsonData.length} items";
        
        if (jsonData.isNotEmpty) {
          _analyzePropertyList(jsonData, results, prefix);
        }
      } else if (jsonData is Map) {
        results['${prefix} Response Type'] = "Map with keys: ${jsonData.keys.toList()}";
        
        // Try to find properties in the map
        if (jsonData.containsKey('properties') && jsonData['properties'] is List) {
          _analyzePropertyList(jsonData['properties'], results, prefix);
        } else if (jsonData.containsKey('data') && jsonData['data'] is List) {
          _analyzePropertyList(jsonData['data'], results, prefix);
        } else {
          results['${prefix} Properties Path'] = "Could not find properties list in response";
        }
      } else {
        results['${prefix} Response Type'] = jsonData.runtimeType.toString();
      }
      
      // Only show part of the response to avoid overwhelming the dialog
      results['${prefix} Properties Preview'] = _formatJson(responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length) + (responseBody.length > 500 ? "..." : ""));
    } catch (jsonError) {
      results['${prefix} JSON Parse Error'] = jsonError.toString();
      results['${prefix} Properties Preview'] = responseBody.substring(0, responseBody.length > 100 ? 100 : responseBody.length);
    }
  }
  
  // Helper to analyze a property list
  static void _analyzePropertyList(List propertyList, Map<String, dynamic> results, String prefix) {
    results['${prefix} Properties Count'] = propertyList.length;
    
    if (propertyList.isNotEmpty) {
      final firstItem = propertyList[0];
      results['${prefix} First Item Keys'] = firstItem is Map ? firstItem.keys.toList() : "Not a Map";
      
      // Check for expected property fields
      if (firstItem is Map) {
        final hasId = firstItem.containsKey('_id') || firstItem.containsKey('id');
        final hasLocation = firstItem.containsKey('location');
        final hasAddress = firstItem.containsKey('address');
        final hasPrice = firstItem.containsKey('price');
        
        results['${prefix} Property Has ID'] = hasId;
        results['${prefix} Property Has Location'] = hasLocation;
        results['${prefix} Property Has Address'] = hasAddress;
        results['${prefix} Property Has Price'] = hasPrice;
        
        // Try to create a Property object
        try {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          final Map<String, dynamic> propertyData = {};
          firstItem.forEach((key, value) {
            if (key is String) {
              propertyData[key] = value;
            }
          });
          
          final property = Property.fromJson(propertyData);
          results['${prefix} Sample Property Parse'] = "Success: ${property.address}";
        } catch (parseError) {
          results['${prefix} Sample Property Parse Error'] = parseError.toString();
        }
      }
    }
  }
  
  static String _formatJson(String jsonString) {
    try {
      final jsonObject = json.decode(jsonString);
      return const JsonEncoder.withIndent('  ').convert(jsonObject);
    } catch (e) {
      return jsonString;
    }
  }
  
  static void _showResultsDialog(BuildContext context, Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API Debug Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final key = results.keys.elementAt(index);
                    final value = results[key];
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 16, top: 4),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              value.toString(),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Force refresh properties by calling backend API directly
                      final String apiUrl = results.containsKey('Raw Request URL') 
                          ? (results['Raw Request URL'] as String).split('/properties/')[0]
                          : 'http://localhost:5000/api';
                      
                      _forceRefreshProperties(context, apiUrl).then((_) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Refresh requested, try loading properties again')),
                        );
                      });
                    },
                    child: Text('Force Refresh Properties'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Force refresh properties by calling the backend directly
  static Future<void> _forceRefreshProperties(BuildContext context, String baseUrl) async {
    try {
      // Get the current location for context
      final position = await _getCurrentPosition();
      
      // Call the scraping endpoint to trigger a refresh
      await http.post(
        Uri.parse('$baseUrl/scrape/listings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'location': '${position.latitude},${position.longitude}',
          'radius': 30 // 30 mile radius for better coverage
        }),
      );
      
      // Wait a moment to allow backend processing
      await Future.delayed(Duration(seconds: 2));
      
      // Check if there are any properties
      final propertiesResponse = await http.get(
        Uri.parse('$baseUrl/properties/nearby?lat=${position.latitude}&lng=${position.longitude}&radius=10000&limit=10'),
      );
      
      if (propertiesResponse.statusCode == 200) {
        final dynamic jsonData = json.decode(propertiesResponse.body);
        int propertyCount = 0;
        
        if (jsonData is List) {
          propertyCount = jsonData.length;
        } else if (jsonData is Map && jsonData.containsKey('properties') && jsonData['properties'] is List) {
          propertyCount = (jsonData['properties'] as List).length;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found $propertyCount properties after refresh')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing properties: $e')),
      );
    }
  }
  
  // Helper to get current position
  static Future<LatLng> _getCurrentPosition() async {
    try {
      // This is a stub - in a real implementation, this would use Geolocator
      return LatLng(37.7749, -122.4194); // Default to San Francisco
    } catch (e) {
      return LatLng(37.7749, -122.4194); // Default to San Francisco
    }
  }
}
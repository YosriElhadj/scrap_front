// Create a new file called debug_tools.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiDebugTool {
  // Test all endpoints and report results
  static Future<void> testAllEndpoints(BuildContext context, String baseUrl) async {
    final results = <String, dynamic>{};
    
    // Test Get Nearby Properties
    try {
      final nearbyPropertiesResponse = await http.get(
        Uri.parse('$baseUrl/properties/nearby?lat=37.7749&lng=-122.4194&radius=5000&limit=10'),
      );
      results['Nearby Properties Status'] = nearbyPropertiesResponse.statusCode;
      results['Nearby Properties Body'] = _formatJson(nearbyPropertiesResponse.body);
    } catch (e) {
      results['Nearby Properties Error'] = e.toString();
    }
    
    // Test Search Properties
    try {
      final searchPropertiesResponse = await http.get(
        Uri.parse('$baseUrl/properties/search?address=${Uri.encodeComponent("San Francisco, CA")}'),
      );
      results['Search Properties Status'] = searchPropertiesResponse.statusCode;
      results['Search Properties Body'] = _formatJson(searchPropertiesResponse.body);
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
      results['Valuation Body'] = _formatJson(valuationResponse.body);
    } catch (e) {
      results['Valuation Error'] = e.toString();
    }
    
    // Test Health
    try {
      final healthResponse = await http.get(
        Uri.parse('$baseUrl/health'),
      );
      results['Health Status'] = healthResponse.statusCode;
      results['Health Body'] = _formatJson(healthResponse.body);
    } catch (e) {
      results['Health Error'] = e.toString();
    }
    
    // Show results dialog
    _showResultsDialog(context, results);
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// screens/valuation_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/valuation_result.dart';

class ValuationScreen extends StatefulWidget {
  final ApiService apiService;
  final LatLng initialPosition;
  final double? prefilledArea;
  final String? prefilledZoning;

  ValuationScreen({
    required this.apiService,
    required this.initialPosition,
    this.prefilledArea,
    this.prefilledZoning,
  });

  @override
  _ValuationScreenState createState() => _ValuationScreenState();
}

class _ValuationScreenState extends State<ValuationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _areaController = TextEditingController();
  
  late LatLng _selectedPosition;
  String _selectedZoning = 'residential';
  bool _nearWater = false;
  bool _roadAccess = true;
  bool _utilities = true;
  
  bool _isLoading = false;
  String _errorMessage = '';
  ValuationResult? _valuationResult;
  
  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    
    if (widget.prefilledArea != null) {
      _areaController.text = widget.prefilledArea!.toString();
    }
    
    if (widget.prefilledZoning != null && widget.prefilledZoning!.isNotEmpty) {
      _selectedZoning = widget.prefilledZoning!;
    }
  }
  
  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }
  
  void _onMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _updateMarker();
    });
  }
  
  void _updateMarker() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(_selectedPosition));
  }
  
  Future<void> _calculateLandValue() async {
    if (_areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter land area')),
      );
      return;
    }
    
    final double? area = double.tryParse(_areaController.text);
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid land area')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _valuationResult = null;
    });
    
    try {
      final result = await widget.apiService.estimateLandValue(
        position: _selectedPosition,
        area: area,
        zoning: _selectedZoning,
        nearWater: _nearWater,
        roadAccess: _roadAccess,
        utilities: _utilities,
      );
      
      setState(() {
        _valuationResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error calculating value: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Land Value Estimator'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('selected_position'),
                  position: _selectedPosition,
                  infoWindow: InfoWindow(title: 'Selected Land'),
                ),
              },
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Land Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _areaController,
                            decoration: InputDecoration(
                              labelText: 'Area (sq ft)',
                              border: OutlineInputBorder(),
                              hintText: 'Enter land area in square feet',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 16),
                          Text('Zoning Type:'),
                          DropdownButton<String>(
                            value: _selectedZoning,
                            isExpanded: true,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedZoning = newValue;
                                });
                              }
                            },
                            items: <String>['residential', 'commercial', 'agricultural', 'industrial']
                              .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value.capitalizeFirst()),
                                );
                              }).toList(),
                          ),
                          SizedBox(height: 16),
                          Text('Land Features:'),
                          CheckboxListTile(
                            title: Text('Near Water'),
                            value: _nearWater,
                            onChanged: (bool? value) {
                              setState(() {
                                _nearWater = value ?? false;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: Text('Road Access'),
                            value: _roadAccess,
                            onChanged: (bool? value) {
                              setState(() {
                                _roadAccess = value ?? true;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: Text('Utilities Available'),
                            value: _utilities,
                            onChanged: (bool? value) {
                              setState(() {
                                _utilities = value ?? true;
                              });
                            },
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _calculateLandValue,
                              child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text('Calculate Estimated Value'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    
                  if (_valuationResult != null) ...[
                    SizedBox(height: 16),
                    _buildValuationResult(_valuationResult!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildValuationResult(ValuationResult result) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valuation Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Estimated Value:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '\$${result.valuation.estimatedValue.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Location: ${result.location.address}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Land Area: ${result.valuation.areaInSqFt.toStringAsFixed(0)} sq ft',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Average Price/sq ft: \$${result.valuation.avgPricePerSqFt.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Zoning: ${result.valuation.zoning.capitalizeFirst()}',
              style: TextStyle(fontSize: 16),
            ),
            
            SizedBox(height: 16),
            Text(
              'Valuation Factors:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            for (final factor in result.valuation.valuationFactors)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      factor.adjustment.contains('+') 
                          ? Icons.trending_up 
                          : Icons.trending_down,
                      color: factor.adjustment.contains('+') 
                          ? Colors.green 
                          : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${factor.factor}: ${factor.adjustment}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 24),
            Text(
              'Comparable Properties:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: result.comparables.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final comparable = result.comparables[index];
                  return _buildComparableCard(comparable);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComparableCard(ComparableProperty property) {
    return Card(
      margin: EdgeInsets.only(right: 12, bottom: 4),
      child: Container(
        width: 250,
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${property.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              property.address,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Divider(height: 16),
            _buildPropertyInfoRow('Area', '${property.area.toStringAsFixed(0)} sq ft'),
            _buildPropertyInfoRow('Price/sq ft', '\$${property.pricePerSqFt.toStringAsFixed(2)}'),
            SizedBox(height: 8),
            Row(
              children: [
                _buildFeatureIcon(property.features.nearWater, 'Water'),
                SizedBox(width: 8),
                _buildFeatureIcon(property.features.roadAccess, 'Road'),
                SizedBox(width: 8),
                _buildFeatureIcon(property.features.utilities, 'Utilities'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPropertyInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureIcon(bool available, String tooltip) {
    return Tooltip(
      message: available ? '$tooltip: Yes' : '$tooltip: No',
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: available ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          available ? Icons.check : Icons.close,
          color: available ? Colors.green.shade800 : Colors.red.shade800,
          size: 16,
        ),
      ),
    );
  }
}

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalizeFirst() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}
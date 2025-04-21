// screens/valuation_screen.dart - with UI fixes for Flutter 3.27.3
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/valuation_result.dart';
import '../theme/app_theme.dart';
import '../utils/string_utils.dart';

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
        title: Text(
          'Land Value Estimator',
          style: AppTheme.heading3,
        ),
        backgroundColor: Colors.white,
        elevation: 2,
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
              zoomControlsEnabled: false,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Land Details',
                            style: AppTheme.heading2,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _areaController,
                            decoration: InputDecoration(
                              labelText: 'Area (sq ft)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: 'Enter land area in square feet',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Zoning Type:',
                            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
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
                                      child: Text(StringUtils.capitalizeFirst(value)),
                                    );
                                  }).toList(),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Land Features:',
                            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          _buildFeatureCheckbox(
                            title: 'Near Water',
                            subtitle: 'Property is near a body of water',
                            value: _nearWater,
                            onChanged: (value) {
                              setState(() {
                                _nearWater = value ?? false;
                              });
                            },
                          ),
                          _buildFeatureCheckbox(
                            title: 'Road Access',
                            subtitle: 'Property has road access',
                            value: _roadAccess,
                            onChanged: (value) {
                              setState(() {
                                _roadAccess = value ?? true;
                              });
                            },
                          ),
                          _buildFeatureCheckbox(
                            title: 'Utilities Available',
                            subtitle: 'Water, electricity, or other utilities',
                            value: _utilities,
                            onChanged: (value) {
                              setState(() {
                                _utilities = value ?? true;
                              });
                            },
                          ),
                          SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _calculateLandValue,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Calculate Estimated Value',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 1,
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
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
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
  
  Widget _buildFeatureCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: value ? AppTheme.primaryColor.withOpacity(0.5) : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
        color: value ? AppTheme.primaryLightColor.withOpacity(0.3) : Colors.transparent,
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.bodySmall,
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  Widget _buildValuationResult(ValuationResult result) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Valuation Results',
                  style: AppTheme.heading2.copyWith(
                    color: AppTheme.primaryDarkColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Estimated value section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Estimated Value',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$${result.valuation.estimatedValue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  _buildPropertyInfoRow(
                    'Location:', 
                    result.location.address,
                  ),
                  SizedBox(height: 8),
                  _buildPropertyInfoRow(
                    'Land Area:', 
                    '${result.valuation.areaInSqFt.toStringAsFixed(0)} sq ft',
                  ),
                  SizedBox(height: 8),
                  _buildPropertyInfoRow(
                    'Avg Price/sq ft:', 
                    '\$${result.valuation.avgPricePerSqFt.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: 8),
                  _buildPropertyInfoRow(
                    'Zoning:', 
                    StringUtils.capitalizeFirst(result.valuation.zoning),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Valuation factors
            Text(
              'Valuation Factors',
              style: AppTheme.heading3,
            ),
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (final factor in result.valuation.valuationFactors)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: factor.adjustment.contains('+')
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              factor.adjustment.contains('+')
                                ? Icons.trending_up
                                : Icons.trending_down,
                              color: factor.adjustment.contains('+')
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  factor.factor,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  factor.adjustment,
                                  style: TextStyle(
                                    color: factor.adjustment.contains('+')
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Comparable properties
            Text(
              'Comparable Properties',
              style: AppTheme.heading3,
            ),
            SizedBox(height: 12),
            
            Container(
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
  
  Widget _buildPropertyInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textLightColor,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDarkColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildComparableCard(ComparableProperty property) {
    return Card(
      margin: EdgeInsets.only(right: 12, bottom: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 250,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
             StringUtils.formatPrice(property.price),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDarkColor,
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
            _buildPropertyInfoRow('Area:', '${property.area.toStringAsFixed(0)} sq ft'),
            SizedBox(height: 4),
            _buildPropertyInfoRow('Price/sq ft:', '\$${property.pricePerSqFt.toStringAsFixed(2)}'),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFeatureIcon(property.features.nearWater, 'Water'),
                _buildFeatureIcon(property.features.roadAccess, 'Road'),
                _buildFeatureIcon(property.features.utilities, 'Utilities'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureIcon(bool available, String tooltip) {
    return Tooltip(
      message: available ? '$tooltip: Yes' : '$tooltip: No',
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: available ? AppTheme.primaryLightColor : Colors.red.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          available ? Icons.check : Icons.close,
          color: available ? AppTheme.primaryColor : Colors.red.shade800,
          size: 16,
        ),
      ),
    );
  }
}
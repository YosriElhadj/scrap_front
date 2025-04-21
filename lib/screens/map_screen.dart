// screens/map_screen.dart - Enhanced UI with fixes
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import '../models/property.dart';
import '../utils/string_utils.dart';
import 'valuation_screen.dart';
import '../debug_tools.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  final LatLng initialPosition;
  final ApiService apiService;

  MapScreen({
    required this.initialPosition,
    required this.apiService,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  
  Set<Marker> _markers = {};
  List<Property> _properties = [];
  bool _isLoading = false;
  String _errorMessage = '';
  double _searchRadius = 5000; // meters
  late LatLng _currentPosition;
  late BitmapDescriptor _propertyIcon;
  int _retryCount = 0;
  
  // Animation controller for property details panel
  late AnimationController _panelController;
  late Animation<double> _panelAnimation;
  bool _isPanelVisible = false;
  Property? _selectedProperty;
  
  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _propertyIcon = BitmapDescriptor.defaultMarker;
    _loadCustomMarker();
    _loadPropertiesNearby();
    
    // Initialize animation controller
    _panelController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    
    _panelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _panelController, curve: Curves.easeInOut)
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  void _showApiDebugTool() {
    ApiDebugTool.testAllEndpoints(context, widget.apiService.baseUrl);
  }
  
  Future<void> _loadCustomMarker() async {
    // Could use custom marker icons in a real implementation
    setState(() {
      _propertyIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    });
  }
  
  Future<void> _loadPropertiesNearby() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    
    try {
      print('Loading properties near ${_currentPosition.latitude}, ${_currentPosition.longitude}');
      
      final properties = await widget.apiService.getNearbyProperties(
        _currentPosition,
        radius: _searchRadius,
      );
      
      if (mounted) {
        setState(() {
          _properties = properties;
          _createMarkers();
          _isLoading = false;
          _retryCount = 0; // Reset retry count on success
        });
      }
      
      // Log success
      print('Successfully loaded ${properties.length} properties');
    } catch (e) {
      print('Error loading properties: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading properties: $e';
          _isLoading = false;
        });
        
        // Auto-retry up to 3 times if no properties are found
        if (_properties.isEmpty && _retryCount < 3) {
          _retryCount++;
          
          print('Retrying property load (attempt $_retryCount)');
          
          // Show a snackbar to inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Retrying to load properties (attempt $_retryCount)'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          
          // Wait a moment before retrying
          Future.delayed(Duration(seconds: 2), () {
            _loadPropertiesNearby();
          });
        }
      }
    }
  }
  
void _createMarkers() {
  final Set<Marker> markers = {};
  
  // Add current position marker
  markers.add(
    Marker(
      markerId: MarkerId('current_position'),
      position: _currentPosition,
      infoWindow: InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
  );
  
  // Add property markers
  for (final property in _properties) {
    markers.add(
      Marker(
        markerId: MarkerId(property.id),
        position: property.location,
        infoWindow: InfoWindow(
          title: StringUtils.formatPrice(property.price),
          snippet: property.address,
        ),
        icon: _propertyIcon,
        onTap: () {
          _showPropertyDetails(property);
        },
      ),
    );
  }
  
  setState(() {
    _markers = markers;
  });
}
  
  void _showPropertyDetails(Property property) {
    setState(() {
      _selectedProperty = property;
      _isPanelVisible = true;
      _panelController.forward();
    });
  }
  
  void _hidePropertyDetails() {
    _panelController.reverse().then((_) {
      setState(() {
        _isPanelVisible = false;
        _selectedProperty = null;
      });
    });
  }
  
  Widget _buildPropertyInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textLightColor,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textDarkColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureRow(String feature, bool available) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? Colors.green : Colors.red,
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            feature,
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  // Changed the parameter type to Property? (nullable Property)
  void _navigateToValuation(Property? property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ValuationScreen(
          apiService: widget.apiService,
          initialPosition: property?.location ?? _currentPosition,
          prefilledArea: property?.area,
          prefilledZoning: property?.zoning,
        ),
      ),
    );
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }
  
  void _onMapTap(LatLng position) {
    setState(() {
      _currentPosition = position;
      
      // Add a marker at tapped position
      _markers.removeWhere((marker) => marker.markerId.value == 'selected_position');
      _markers.add(
        Marker(
          markerId: MarkerId('selected_position'),
          position: position,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: 'Tap to value this land',
            onTap: () {
              _navigateToValuation(null);
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    });
  }
  
  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final result = await widget.apiService.searchProperties(_searchController.text);
      final geocodedLocation = result['geocodedLocation'];
      final properties = result['properties'] as List<Property>;
      
      final LatLng position = LatLng(
        geocodedLocation['lat'],
        geocodedLocation['lng'],
      );
      
      // Move map to search location
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(position, 14));
      
      setState(() {
        _currentPosition = position;
        _properties = properties;
        _createMarkers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching location: $e';
        _isLoading = false;
      });
    }
  }
  
  void _adjustSearchRadius(double value) {
    setState(() {
      _searchRadius = value;
    });
    _loadPropertiesNearby();
  }

  // Modern floating action button
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToValuation(null),
      backgroundColor: AppTheme.primaryColor,
      icon: Icon(Icons.add_location_alt),
      label: Text('Value This Location'),
      elevation: 4,
    );
  }

  // Enhanced UI for map controls
  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      top: 120,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMapButton(
              icon: Icons.zoom_in,
              onPressed: () async {
                final controller = await _controller.future;
                controller.animateCamera(CameraUpdate.zoomIn());
              },
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            _buildMapButton(
              icon: Icons.zoom_out,
              onPressed: () async {
                final controller = await _controller.future;
                controller.animateCamera(CameraUpdate.zoomOut());
              },
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            _buildMapButton(
              icon: Icons.my_location,
              onPressed: () async {
                final controller = await _controller.future;
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentPosition, 14),
                );
              },
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            _buildMapButton(
              icon: Icons.layers,
              onPressed: () {
                // Show map layer options
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildLayersBottomSheet(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          size: 20,
          color: AppTheme.textDarkColor,
        ),
      ),
    );
  }

  Widget _buildLayersBottomSheet() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Map Layers',
            style: AppTheme.heading2,
          ),
          SizedBox(height: 16),
          _buildLayerOption(
            title: 'Standard',
            description: 'Default map view',
            isSelected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildLayerOption(
            title: 'Satellite',
            description: 'Aerial photography view',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              // Would implement map type change here
            },
          ),
          _buildLayerOption(
            title: 'Terrain',
            description: 'Topographic details',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              // Would implement map type change here
            },
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 16),
          Text(
            'Overlays',
            style: AppTheme.heading3,
          ),
          SizedBox(height: 12),
          _buildCheckboxOption(
            title: 'Property Boundaries',
            value: false,
            onChanged: (value) {},
          ),
          _buildCheckboxOption(
            title: 'Zoning Areas',
            value: true,
            onChanged: (value) {},
          ),
          _buildCheckboxOption(
            title: 'Flood Zones',
            value: false,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildLayerOption({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLightColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxOption({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Text(
            title,
            style: AppTheme.bodyText,
          ),
        ],
      ),
    );
  }
  
  // Property details panel - animated slide-in
  Widget _buildPropertyDetailsPanel() {
    if (!_isPanelVisible || _selectedProperty == null) return SizedBox.shrink();
    
    final property = _selectedProperty!;
    
    return AnimatedBuilder(
      animation: _panelAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.4 * _panelAnimation.value,
          child: Opacity(
            opacity: _panelAnimation.value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(16),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Property Details',
                    style: AppTheme.heading3.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: _hidePropertyDetails,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Property details content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price and address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${property.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDarkColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                property.address,
                                style: AppTheme.bodyText,
                              ),
                              Text(
                                '${property.city ?? ""}, ${property.state ?? ""} ${property.zipCode ?? ""}',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (property.zoning != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLightColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              StringUtils.capitalizeFirst(property.zoning!),
                              style: TextStyle(
                                color: AppTheme.primaryDarkColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    
                    // Property details
                    _buildPropertyInfoRow(
                      'Area',
                      property.area != null ? '${property.area!.toStringAsFixed(0)} sq ft' : 'Unknown'
                    ),
                    _buildPropertyInfoRow(
                      'Price/sq ft',
                      property.pricePerSqFt != null ? '\$${property.pricePerSqFt!.toStringAsFixed(2)}' : 'Unknown'
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Features
                    Text(
                      'Features',
                      style: AppTheme.heading3.copyWith(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    _buildFeatureRow('Water Proximity', property.features.nearWater),
                    _buildFeatureRow('Road Access', property.features.roadAccess),
                    _buildFeatureRow('Utilities Available', property.features.utilities),
                    
                    SizedBox(height: 16),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.calculate, size: 18),
                            label: Text('Value Similar Land'),
                            onPressed: () {
                              _hidePropertyDetails();
                              _navigateToValuation(property);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            if (property.sourceUrl != null) {
                              // In a real app, would launch URL
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Would open: ${property.sourceUrl}')),
                              );
                            }
                          },
                          child: Icon(Icons.link),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textDarkColor, 
                            padding: EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Land Valuation Map',
          style: AppTheme.heading3,
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPropertiesNearby,
            tooltip: 'Refresh properties',
          ),
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _showApiDebugTool,
            tooltip: 'Debug API',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map MUST be the first child in the stack to prevent being covered
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Using custom buttons instead
            onTap: _onMapTap,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false, // Using custom controls instead
            compassEnabled: false,
          ),
          
          // Search bar card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by address or city',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _searchLocation,
                      child: Text('Search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Filter options expandable panel
          Positioned(
            top: 88,
            left: 16,
            right: 16,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Text(
                  'Search Radius: ${(_searchRadius / 1000).toStringAsFixed(1)} km',
                  style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Slider(
                          value: _searchRadius,
                          min: 1000,
                          max: 10000,
                          divisions: 9,
                          activeColor: AppTheme.primaryColor,
                          inactiveColor: Colors.grey.shade300,
                          label: '${(_searchRadius / 1000).toStringAsFixed(1)} km',
                          onChanged: (value) {
                            setState(() {
                              _searchRadius = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _adjustSearchRadius(value);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1 km', style: AppTheme.caption),
                              Text('5 km', style: AppTheme.caption),
                              Text('10 km', style: AppTheme.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Property info box at bottom
          if (_properties.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_properties.length} properties found',
                      style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add_location_alt, size: 18),
                      label: Text('Value This Location'),
                      onPressed: () {
                        _navigateToValuation(null);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading properties...',
                          style: AppTheme.bodyText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Error message
          if (_errorMessage.isNotEmpty)
            Positioned(
              top: 160,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red.shade800),
                        onPressed: () {
                          setState(() {
                            _errorMessage = '';
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Map controls
          _buildMapControls(),
          
          // Property details panel
          _buildPropertyDetailsPanel(),
        ],
      ),
    );
  }
}
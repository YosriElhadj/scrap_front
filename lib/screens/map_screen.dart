// screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import '../models/property.dart';
import 'valuation_screen.dart';
import '../debug_tools.dart';

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

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  
  Set<Marker> _markers = {};
  List<Property> _properties = [];
  bool _isLoading = false;
  String _errorMessage = '';
  double _searchRadius = 5000; // meters
  late LatLng _currentPosition;
  late BitmapDescriptor _propertyIcon;
  
  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _propertyIcon = BitmapDescriptor.defaultMarker;
    _loadCustomMarker();
    _loadPropertiesNearby();
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
      final properties = await widget.apiService.getNearbyProperties(
        _currentPosition,
        radius: _searchRadius,
      );
      
      if (mounted) {
        setState(() {
          _properties = properties;
          _createMarkers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading properties: $e';
          _isLoading = false;
        });
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
            title: '\$${property.price.toStringAsFixed(0)}',
            snippet: property.address,
            onTap: () {
              _showPropertyDetails(property);
            },
          ),
          icon: _propertyIcon,
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  void _showPropertyDetails(Property property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${property.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 8),
              Text(
                property.address,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${property.city ?? ""}, ${property.state ?? ""} ${property.zipCode ?? ""}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              Divider(height: 24),
              _buildPropertyInfoRow(
                'Area', 
                property.area != null ? '${property.area!.toStringAsFixed(0)} sq ft' : 'Unknown'
              ),
              _buildPropertyInfoRow(
                'Price/sq ft', 
                property.pricePerSqFt != null ? '\$${property.pricePerSqFt!.toStringAsFixed(2)}' : 'Unknown'
              ),
              _buildPropertyInfoRow('Zoning', property.zoning ?? 'Unknown'),
              SizedBox(height: 16),
              Text(
                'Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              _buildFeatureRow('Water Proximity', property.features.nearWater),
              _buildFeatureRow('Road Access', property.features.roadAccess),
              _buildFeatureRow('Utilities Available', property.features.utilities),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.calculate),
                    label: Text('Value Similar Land'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateToValuation(property);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  if (property.sourceUrl != null)
                    TextButton.icon(
                      icon: Icon(Icons.link),
                      label: Text('View Source'),
                      onPressed: () {
                        // In a real app, launch URL
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Would open: ${property.sourceUrl}')),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPropertyInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureRow(String feature, bool available) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              fontSize: 16,
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Land Valuation Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPropertiesNearby,
            tooltip: 'Refresh properties',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by address or city',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) => _searchLocation(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchLocation,
                  child: Text('Search'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Search radius: ${(_searchRadius / 1000).toStringAsFixed(1)} km'),
                Expanded(
                  child: Slider(
                    value: _searchRadius,
                    min: 1000,
                    max: 10000,
                    divisions: 9,
                    onChanged: (value) {
                      setState(() {
                        _searchRadius = value;
                      });
                    },
                    onChangeEnd: (value) {
                      _adjustSearchRadius(value);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            LinearProgressIndicator(),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: widget.initialPosition,
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: _onMapTap,
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_properties.length} properties found'),
                ElevatedButton.icon(
                  icon: Icon(Icons.add_location_alt),
                  label: Text('Value Selected Location'),
                  onPressed: () {
                    _navigateToValuation(null);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
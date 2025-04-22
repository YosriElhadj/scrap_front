// lib/screens/property_list_screen.dart - OPTIMIZED VERSION
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import '../models/property.dart';
import 'valuation_screen.dart';

class PropertyListScreen extends StatefulWidget {
  final ApiService apiService;
  final LatLng initialPosition;

  PropertyListScreen({
    required this.apiService,
    required this.initialPosition,
  });

  @override
  _PropertyListScreenState createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Property> _properties = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _sortBy = 'price'; // Default sort
  bool _sortAscending = true;
  double _searchRadius = 5000; // meters
  late LatLng _currentPosition;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _loadPropertiesNearby();
  }

  Future<void> _loadPropertiesNearby() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final properties = await widget.apiService.getNearbyProperties(
        _currentPosition,
        radius: _searchRadius,
      );
      
      setState(() {
        _properties = properties;
        _sortProperties();
        _isLoading = false;
      });
      
      if (properties.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No properties found in this area'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading properties: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading properties: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _sortProperties() {
    switch (_sortBy) {
      case 'price':
        _properties.sort((a, b) => _sortAscending
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
        break;
      case 'area':
        _properties.sort((a, b) {
          if (a.area == null && b.area == null) return 0;
          if (a.area == null) return _sortAscending ? 1 : -1;
          if (b.area == null) return _sortAscending ? -1 : 1;
          return _sortAscending
              ? a.area!.compareTo(b.area!)
              : b.area!.compareTo(a.area!);
        });
        break;
      case 'pricePerSqFt':
        _properties.sort((a, b) {
          if (a.pricePerSqFt == null && b.pricePerSqFt == null) return 0;
          if (a.pricePerSqFt == null) return _sortAscending ? 1 : -1;
          if (b.pricePerSqFt == null) return _sortAscending ? -1 : 1;
          return _sortAscending
              ? a.pricePerSqFt!.compareTo(b.pricePerSqFt!)
              : b.pricePerSqFt!.compareTo(a.pricePerSqFt!);
        });
        break;
    }
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
      
      setState(() {
        _currentPosition = position;
        _properties = properties;
        _sortProperties();
        _isLoading = false;
      });
      
      if (properties.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No properties found for "${_searchController.text}"'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching location: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching location: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _adjustSearchRadius(double value) {
    setState(() {
      _searchRadius = value;
    });
    _loadPropertiesNearby();
  }
  
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

  // Define the missing method _buildPropertyTag
  Widget _buildPropertyTag(String text, IconData icon) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
  
  // Missing _showPropertyDetails method
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
                  if (property.sourceUrl != null && property.sourceUrl!.isNotEmpty)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Land Listings'),
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
                Text('Radius: ${(_searchRadius / 1000).toStringAsFixed(1)} km'),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Sort by:'),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortBy = newValue;
                        _sortProperties();
                      });
                    }
                  },
                  items: <String>['price', 'area', 'pricePerSqFt']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(_getSortLabel(value)),
                      );
                    }).toList(),
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _sortProperties();
                    });
                  },
                  tooltip: _sortAscending ? 'Ascending' : 'Descending',
                ),
                Spacer(),
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
            child: _properties.isEmpty
                ? Center(
                    child: _isLoading
                        ? Text('Loading properties...')
                        : Text('No properties found in this area'),
                  )
                : ListView.builder(
                    itemCount: _properties.length,
                    itemBuilder: (context, index) {
                      final property = _properties[index];
                      return _buildPropertyCard(property);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToValuation(null),
        child: Icon(Icons.add),
        tooltip: 'Valuate New Land',
      ),
    );
  }
  
  String _getSortLabel(String sortKey) {
    switch (sortKey) {
      case 'price':
        return 'Price';
      case 'area':
        return 'Area';
      case 'pricePerSqFt':
        return 'Price per sq ft';
      default:
        return sortKey;
    }
  }
  
  Widget _buildPropertyCard(Property property) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showPropertyDetails(property),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property image or placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.landscape,
                    size: 40,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${property.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      property.address,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (property.area != null)
                          _buildPropertyTag(
                            '${property.area!.toStringAsFixed(0)} sq ft',
                            Icons.straighten,
                          ),
                        if (property.pricePerSqFt != null)
                          _buildPropertyTag(
                            '\$${property.pricePerSqFt!.toStringAsFixed(2)}/sq ft',
                            Icons.attach_money,
                          ),
                        if (property.zoning != null)
                          _buildPropertyTag(
                            property.zoning![0].toUpperCase() + property.zoning!.substring(1),
                            Icons.category,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
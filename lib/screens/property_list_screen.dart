// screens/property_list_screen.dart - Enhanced UI
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import '../models/property.dart';
import '../utils/string_utils.dart';
import 'valuation_screen.dart';
import '../theme/app_theme.dart';

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
  bool _isFilterExpanded = false;
  
  // Filter options
  double _minPrice = 0;
  double _maxPrice = 1000000;
  double _minArea = 0;
  double _maxArea = 100000;
  String _selectedZoning = 'all';
  bool _filterNearWater = false;
  bool _filterRoadAccess = false;
  bool _filterUtilities = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _loadPropertiesNearby();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading properties: $e';
        _isLoading = false;
      });
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
  
  void _scrapeData() async {
    final location = _searchController.text.isNotEmpty 
        ? _searchController.text 
        : 'Current Location';
        
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_download, color: AppTheme.primaryColor, size: 24),
            SizedBox(width: 8),
            Text('Scrape Land Listings'),
          ],
        ),
        content: Text(
          'This will start scraping land listings for "$location". '
          'The scraping process runs in the background and may take several minutes.',
          style: AppTheme.bodyText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                final result = await widget.apiService.scrapeLandListings(
                  _searchController.text.isNotEmpty 
                      ? _searchController.text 
                      : '${_currentPosition.latitude},${_currentPosition.longitude}'
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Scraping initiated: ${result['message']}'),
                    duration: Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                
                // Wait a bit and refresh the list
                Future.delayed(Duration(seconds: 10), () {
                  _loadPropertiesNearby();
                });
                
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: Text('Start Scraping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced property tag with better styling
  Widget _buildPropertyTag(String text, IconData icon) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textLightColor),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textDarkColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Enhanced property details bottom sheet
  void _showPropertyDetails(Property property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Container(
              width: double.infinity,
              child: Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            
            // Header with price and address
            Container(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\${property.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            property.address,
                            style: AppTheme.bodyText,
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLightColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          StringUtils.capitalizeFirst(property.zoning!) ?? 'Unknown',
                          style: TextStyle(
                            color: AppTheme.primaryDarkColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (property.city != null || property.state != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${property.city ?? ""}, ${property.state ?? ""} ${property.zipCode ?? ""}',
                        style: AppTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            
            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property specs
                    Text(
                      'Property Specifications',
                      style: AppTheme.heading3,
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildPropertyInfoRow(
                            'Area', 
                            property.area != null ? '${property.area!.toStringAsFixed(0)} sq ft' : 'Unknown'
                          ),
                          Divider(height: 16),
                          _buildPropertyInfoRow(
                            'Price/sq ft', 
                            property.pricePerSqFt != null ? '\${property.pricePerSqFt!.toStringAsFixed(2)}' : 'Unknown'
                          ),
                          Divider(height: 16),
                          _buildPropertyInfoRow('Zoning', property.zoning ?? 'Unknown'),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Features
                    Text(
                      'Features',
                      style: AppTheme.heading3,
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureItem('Water Proximity', property.features.nearWater),
                          SizedBox(height: 12),
                          _buildFeatureItem('Road Access', property.features.roadAccess),
                          SizedBox(height: 12),
                          _buildFeatureItem('Utilities Available', property.features.utilities),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Description
                    if (property.sourceUrl != null) ...[
                      Text(
                        'Source',
                        style: AppTheme.heading3,
                      ),
                      SizedBox(height: 8),
                      Text(
                        property.sourceUrl!,
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                    
                    // Actions
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.calculate),
                        label: Text('Value Similar Land'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _navigateToValuation(property);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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
  
  Widget _buildPropertyInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textLightColor,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.textDarkColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeatureItem(String feature, bool available) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: available ? AppTheme.primaryLightColor : Colors.red.shade50,
          ),
          child: Center(
            child: Icon(
              available ? Icons.check : Icons.close,
              color: available ? AppTheme.primaryColor : Colors.red,
              size: 16,
            ),
          ),
        ),
        SizedBox(width: 12),
        Text(
          feature,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textDarkColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Land Listings',
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
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by address or city',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          onSubmitted: (_) => _searchLocation(),
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: Colors.grey.shade300,
                        margin: EdgeInsets.symmetric(vertical: 8),
                      ),
                      IconButton(
                        icon: Icon(Icons.tune),
                        onPressed: () {
                          setState(() {
                            _isFilterExpanded = !_isFilterExpanded;
                          });
                        },
                        tooltip: 'Filters',
                      ),
                      SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
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
                      ),
                    ],
                  ),
                ),
                
                // Filter panel
                if (_isFilterExpanded)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filters',
                              style: AppTheme.heading3.copyWith(fontSize: 18),
                            ),
                            TextButton(
                              onPressed: () {
                                // Reset filters
                                setState(() {
                                  _minPrice = 0;
                                  _maxPrice = 1000000;
                                  _minArea = 0;
                                  _maxArea = 100000;
                                  _selectedZoning = 'all';
                                  _filterNearWater = false;
                                  _filterRoadAccess = false;
                                  _filterUtilities = false;
                                });
                              },
                              child: Text('Reset'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Price range
                        Text(
                          'Price Range',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDarkColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
  child: TextField(
    decoration: InputDecoration(
      labelText: 'Min',
      prefixText: '\$',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    keyboardType: TextInputType.number,
    onChanged: (value) {
      if (value.isNotEmpty) {
        setState(() {
          _minPrice = double.tryParse(value) ?? 0;
        });
      }
    },
  ),
),
SizedBox(width: 12),
Expanded(
  child: TextField(
    decoration: InputDecoration(
      labelText: 'Max',
      prefixText: '\$',  // Fixed: Removed unnecessary escape
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    keyboardType: TextInputType.number,
    onChanged: (value) {
      if (value.isNotEmpty) {
        setState(() {
          _maxPrice = double.tryParse(value) ?? 1000000;
        });
      }
    },
  ),
),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Zoning
                        Text(
                          'Zoning Type',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDarkColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedZoning,
                              isExpanded: true,
                              hint: Text('Select zoning'),
                              items: [
                                DropdownMenuItem(value: 'all', child: Text('All')),
                                DropdownMenuItem(value: 'residential', child: Text('Residential')),
                                DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                                DropdownMenuItem(value: 'agricultural', child: Text('Agricultural')),
                                DropdownMenuItem(value: 'industrial', child: Text('Industrial')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedZoning = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Features
                        Text(
                          'Features',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDarkColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            _buildFilterChip('Near Water', _filterNearWater, (val) {
                              setState(() {
                                _filterNearWater = val ?? false;
                              });
                            }),
                            SizedBox(width: 8),
                            _buildFilterChip('Road Access', _filterRoadAccess, (val) {
                              setState(() {
                                _filterRoadAccess = val ?? false;
                              });
                            }),
                            SizedBox(width: 8),
                            _buildFilterChip('Utilities', _filterUtilities, (val) {
                              setState(() {
                                _filterUtilities = val ?? false;
                              });
                            }),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Apply button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Apply filters
                              setState(() {
                                _isFilterExpanded = false;
                                // Filtered properties would be applied here
                              });
                            },
                            child: Text('Apply Filters'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Sort and count header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_properties.length} properties found',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDarkColor,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Sort by:',
                      style: TextStyle(
                        color: AppTheme.textLightColor,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isDense: true,
                          items: [
                            DropdownMenuItem(value: 'price', child: Text('Price')),
                            DropdownMenuItem(value: 'area', child: Text('Area')),
                            DropdownMenuItem(value: 'pricePerSqFt', child: Text('Price per sq ft')),
                          ],
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _sortBy = newValue;
                                _sortProperties();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 20),
                      onPressed: () {
                        setState(() {
                          _sortAscending = !_sortAscending;
                          _sortProperties();
                        });
                      },
                      tooltip: _sortAscending ? 'Ascending' : 'Descending',
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Property list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : _properties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No properties found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textLightColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your search criteria',
                              style: TextStyle(
                                color: AppTheme.textLightColor,
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: Icon(Icons.cloud_download),
                              label: Text('Download Properties'),
                              onPressed: _scrapeData,
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
                      )
                    : _buildPropertyList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToValuation(null),
        label: Text('New Valuation'),
        icon: Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
  
  Widget _buildFilterChip(String label, bool selected, Function(bool?) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppTheme.primaryLightColor,
      checkmarkColor: AppTheme.primaryColor,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryDarkColor : AppTheme.textDarkColor,
        fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
    );
  }
  
  Widget _buildPropertyList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 88), // Extra bottom padding for FAB
      itemCount: _properties.length,
      itemBuilder: (context, index) {
        return _buildEnhancedPropertyCard(_properties[index]);
      },
    );
  }
  
  Widget _buildEnhancedPropertyCard(Property property) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showPropertyDetails(property),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder with price tag
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: property.images?.isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(property.images!.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // Gradient overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                  
                  // Property placeholder icon
                  Center(
                    child: Icon(
                      Icons.landscape,
                      size: 48,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  
                  // Price tag
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Text(
                      '\${property.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Zoning badge
                 if (property.zoning != null)
  Positioned(
    top: 12,
    right: 12,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
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
  ),
                ],
              ),
            ),
            
            // Property details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address
                  Text(
                    property.address,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDarkColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (property.city != null || property.state != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${property.city ?? ""}, ${property.state ?? ""} ${property.zipCode ?? ""}',
                        style: TextStyle(
                          color: AppTheme.textLightColor,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  SizedBox(height: 12),
                  
                  // Property tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (property.area != null)
                        _buildPropertyTag(
                          '${property.area!.toStringAsFixed(0)} sq ft',
                          Icons.straighten,
                        ),
                      if (property.pricePerSqFt != null)
                        _buildPropertyTag(
                          '\${property.pricePerSqFt!.toStringAsFixed(2)}/sq ft',
                          Icons.attach_money,
                        ),
                      if (property.features.nearWater)
                        _buildPropertyTag(
                          'Near Water',
                          Icons.water,
                        ),
                      if (property.features.roadAccess)
                        _buildPropertyTag(
                          'Road Access',
                          Icons.add_road,
                        ),
                      if (property.features.utilities)
                        _buildPropertyTag(
                          'Utilities',
                          Icons.power,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
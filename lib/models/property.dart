// models/property.dart - IMPROVED VERSION
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class Property {
  final String id;
  final LatLng location;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final double price;
  final double? area;
  final double? pricePerSqFt;
  final String? zoning;
  final PropertyFeatures features;
  final String? sourceUrl;
  final List<String>? images;
  final DateTime lastUpdated;
  final String? description;

  // Extended fields from backend
  final String? originalPrice;
  final dynamic originalArea;
  final String? governorate;
  final String? neighborhood;
  final String? propertyType;
  final String? source;
  final double? priceUSD;
  final double? areaInSqMeters;
  final double? areaInHectares;

  Property({
    required this.id,
    required this.location,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    required this.price,
    this.area,
    this.pricePerSqFt,
    this.zoning,
    required this.features,
    this.sourceUrl,
    this.images,
    required this.lastUpdated,
    this.description,
    this.originalPrice,
    this.originalArea,
    this.governorate,
    this.neighborhood,
    this.propertyType,
    this.source,
    this.priceUSD,
    this.areaInSqMeters,
    this.areaInHectares,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // Handle coordinates correctly with error checking
    List<double> extractCoordinates() {
      try {
        if (json.containsKey('location') && json['location'] != null) {
          final location = json['location'];
          
          if (location.containsKey('coordinates') && location['coordinates'] is List) {
            final coordinates = location['coordinates'];
            if (coordinates.length >= 2) {
              final lng = coordinates[0] is int ? (coordinates[0] as int).toDouble() : coordinates[0];
              final lat = coordinates[1] is int ? (coordinates[1] as int).toDouble() : coordinates[1];
              
              if (lng is double && lat is double && 
                  !lng.isNaN && !lat.isNaN &&
                  lng >= -180 && lng <= 180 &&
                  lat >= -90 && lat <= 90) {
                return [lng, lat];
              }
            }
          }
        }
        // If we can't get valid coordinates, generate a random point near Tunis
        print('Warning: Invalid or missing coordinates, using default with random offset');
        final random = math.Random();
        final latOffset = (random.nextDouble() - 0.5) * 0.1; // +/- 0.05 degrees (~5km)
        final lngOffset = (random.nextDouble() - 0.5) * 0.1;
        return [10.1815 + lngOffset, 36.8065 + latOffset]; // Tunis coordinates
      } catch (e) {
        print('Error extracting coordinates: $e');
        return [10.1815, 36.8065]; // Default to Tunis if all else fails
      }
    }
    
    // Handle images list correctly
    List<String> extractImages() {
      try {
        if (json.containsKey('images') && json['images'] != null) {
          if (json['images'] is List) {
            return List<String>.from(json['images'].map((img) => img.toString()));
          } else if (json['images'] is String) {
            // Handle case where images might be a comma-separated string
            return json['images'].toString().split(',').map((img) => img.trim()).toList();
          }
        }
        return [];
      } catch (e) {
        print('Error extracting images: $e');
        return [];
      }
    }
    
    // Parse features with default values for safety
    PropertyFeatures extractFeatures() {
      try {
        if (json.containsKey('features') && json['features'] is Map) {
          return PropertyFeatures.fromJson(json['features']);
        }
        // If features missing or not a Map, create default features
        return PropertyFeatures(
          nearWater: false,
          roadAccess: true,
          utilities: true,
        );
      } catch (e) {
        print('Error extracting features: $e');
        return PropertyFeatures(
          nearWater: false,
          roadAccess: true,
          utilities: true,
        );
      }
    }
    
    // Extract ID with fallbacks
    String extractId() {
      if (json.containsKey('_id') && json['_id'] != null) {
        return json['_id'].toString();
      } else if (json.containsKey('id') && json['id'] != null) {
        return json['id'].toString();
      } else {
        // Use a combination of fields as a fallback ID
        final price = json['price']?.toString() ?? '';
        final address = json['address']?.toString() ?? '';
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        return 'property_${price}_${address}_$timestamp'.replaceAll(' ', '_');
      }
    }
    
    // Safe number conversion with fallbacks
    double safeDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        try {
          return double.parse(value);
        } catch (_) {
          return defaultValue;
        }
      }
      return defaultValue;
    }
    
    // Extract datetime with fallback
    DateTime extractDateTime(String key) {
      try {
        if (json.containsKey(key) && json[key] != null) {
          return DateTime.parse(json[key]);
        }
      } catch (e) {
        print('Error parsing date $key: $e');
      }
      return DateTime.now();
    }
    
    // Now extract all values with proper error handling
    final coordinates = extractCoordinates();
    final latLng = LatLng(coordinates[1], coordinates[0]);
    
    return Property(
      id: extractId(),
      location: latLng,
      address: json['address'] ?? 'Unknown Address',
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      price: safeDouble(json['price'], 0),
      area: json.containsKey('area') ? safeDouble(json['area']) : null,
      pricePerSqFt: json.containsKey('pricePerSqFt') ? safeDouble(json['pricePerSqFt']) : null,
      zoning: json['zoning'],
      features: extractFeatures(),
      sourceUrl: json['sourceUrl'],
      images: extractImages(),
      lastUpdated: extractDateTime('lastUpdated'),
      description: json['description'],

      // Extended fields
      originalPrice: json['originalPrice'],
      originalArea: json['originalArea'],
      governorate: json['governorate'],
      neighborhood: json['neighborhood'],
      propertyType: json['propertyType'],
      source: json['source'],
      priceUSD: json.containsKey('priceUSD') ? safeDouble(json['priceUSD']) : null,
      areaInSqMeters: json.containsKey('areaInSqMeters') ? safeDouble(json['areaInSqMeters']) : null,
      areaInHectares: json.containsKey('areaInHectares') ? safeDouble(json['areaInHectares']) : null,
    );
  }

  // Create a copy with optional parameter overrides
  Property copyWith({
    String? id,
    LatLng? location,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? price,
    double? area,
    double? pricePerSqFt,
    String? zoning,
    PropertyFeatures? features,
    String? sourceUrl,
    List<String>? images,
    DateTime? lastUpdated,
    String? description,
    String? originalPrice,
    dynamic originalArea,
    String? governorate,
    String? neighborhood,
    String? propertyType,
    String? source,
    double? priceUSD,
    double? areaInSqMeters,
    double? areaInHectares,
  }) {
    return Property(
      id: id ?? this.id,
      location: location ?? this.location,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      price: price ?? this.price,
      area: area ?? this.area,
      pricePerSqFt: pricePerSqFt ?? this.pricePerSqFt,
      zoning: zoning ?? this.zoning,
      features: features ?? this.features,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      images: images ?? this.images,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      description: description ?? this.description,
      originalPrice: originalPrice ?? this.originalPrice,
      originalArea: originalArea ?? this.originalArea,
      governorate: governorate ?? this.governorate,
      neighborhood: neighborhood ?? this.neighborhood,
      propertyType: propertyType ?? this.propertyType,
      source: source ?? this.source,
      priceUSD: priceUSD ?? this.priceUSD,
      areaInSqMeters: areaInSqMeters ?? this.areaInSqMeters,
      areaInHectares: areaInHectares ?? this.areaInHectares,
    );
  }
}

class PropertyFeatures {
  final bool nearWater;
  final bool roadAccess;
  final bool utilities;

  PropertyFeatures({
    required this.nearWater,
    required this.roadAccess,
    required this.utilities,
  });

  factory PropertyFeatures.fromJson(Map<String, dynamic> json) {
    return PropertyFeatures(
      nearWater: json['nearWater'] ?? false,
      roadAccess: json['roadAccess'] ?? true,
      utilities: json['utilities'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nearWater': nearWater,
      'roadAccess': roadAccess,
      'utilities': utilities,
    };
  }
  
  // Create a copy with optional parameter overrides
  PropertyFeatures copyWith({
    bool? nearWater,
    bool? roadAccess,
    bool? utilities,
  }) {
    return PropertyFeatures(
      nearWater: nearWater ?? this.nearWater,
      roadAccess: roadAccess ?? this.roadAccess,
      utilities: utilities ?? this.utilities,
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
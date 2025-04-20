// models/property.dart - Updated with images field
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final List<String>? images; // Made nullable for compatibility
  final DateTime lastUpdated;
  final String? description;
  
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
  });
  
  factory Property.fromJson(Map<String, dynamic> json) {
    final coordinates = json['location']['coordinates'];
    return Property(
      id: json['_id'],
      location: LatLng(
        coordinates[1], // latitude
        coordinates[0], // longitude
      ),
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      price: json['price'].toDouble(),
      area: json['area']?.toDouble(),
      pricePerSqFt: json['pricePerSqFt']?.toDouble(),
      zoning: json['zoning'],
      features: PropertyFeatures.fromJson(json['features']),
      sourceUrl: json['sourceUrl'],
      images: json['images'] != null 
        ? List<String>.from(json['images']) 
        : null,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      description: json['description'],
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
}

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalizeFirst() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}
// models/property.dart
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
  final List<String>? images;
  final DateTime lastUpdated;
  final String? description;

  // Extended fields from backend
  final String? originalPrice;
  final String? originalArea;
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
    final coordinates = json['location']['coordinates'];
    return Property(
      id: json['_id'],
      location: LatLng(coordinates[1], coordinates[0]),
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
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      description: json['description'],

      // Extra fields from backend
      originalPrice: json['originalPrice'],
      originalArea: json['originalArea'],
      governorate: json['governorate'],
      neighborhood: json['neighborhood'],
      propertyType: json['propertyType'],
      source: json['source'],
      priceUSD: json['priceUSD']?.toDouble(),
      areaInSqMeters: json['areaInSqMeters']?.toDouble(),
      areaInHectares: json['areaInHectares']?.toDouble(),
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
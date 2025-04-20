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
  final DateTime lastUpdated;
  
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
    required this.lastUpdated,
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
      lastUpdated: DateTime.parse(json['lastUpdated']),
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


// models/valuation_result.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'property.dart';

class ValuationResult {
  final LocationInfo location;
  final ValuationInfo valuation;
  final List<ComparableProperty> comparables;
  
  ValuationResult({
    required this.location,
    required this.valuation,
    required this.comparables,
  });
  
  factory ValuationResult.fromJson(Map<String, dynamic> json) {
    return ValuationResult(
      location: LocationInfo.fromJson(json['location']),
      valuation: ValuationInfo.fromJson(json['valuation']),
      comparables: (json['comparables'] as List)
          .map((comp) => ComparableProperty.fromJson(comp))
          .toList(),
    );
  }
}

class LocationInfo {
  final LatLng position;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  
  LocationInfo({
    required this.position,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
  });
  
  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      position: LatLng(json['lat'], json['lng']),
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
    );
  }
}

class ValuationInfo {
  final int estimatedValue;
  final double areaInSqFt;
  final double avgPricePerSqFt;
  final String zoning;
  final List<ValuationFactor> valuationFactors;
  
  ValuationInfo({
    required this.estimatedValue,
    required this.areaInSqFt,
    required this.avgPricePerSqFt,
    required this.zoning,
    required this.valuationFactors,
  });
  
  factory ValuationInfo.fromJson(Map<String, dynamic> json) {
    return ValuationInfo(
      estimatedValue: json['estimatedValue'],
      areaInSqFt: json['areaInSqFt'].toDouble(),
      avgPricePerSqFt: json['avgPricePerSqFt'].toDouble(),
      zoning: json['zoning'],
      valuationFactors: (json['valuationFactors'] as List)
          .map((factor) => ValuationFactor.fromJson(factor))
          .toList(),
    );
  }
}

class ValuationFactor {
  final String factor;
  final String adjustment;
  
  ValuationFactor({
    required this.factor,
    required this.adjustment,
  });
  
  factory ValuationFactor.fromJson(Map<String, dynamic> json) {
    return ValuationFactor(
      factor: json['factor'],
      adjustment: json['adjustment'],
    );
  }
}

class ComparableProperty {
  final String id;
  final String address;
  final double price;
  final double area;
  final double pricePerSqFt;
  final PropertyFeatures features;
  
  ComparableProperty({
    required this.id,
    required this.address,
    required this.price,
    required this.area,
    required this.pricePerSqFt,
    required this.features,
  });
  
  factory ComparableProperty.fromJson(Map<String, dynamic> json) {
    return ComparableProperty(
      id: json['id'],
      address: json['address'],
      price: json['price'].toDouble(),
      area: json['area'].toDouble(),
      pricePerSqFt: json['pricePerSqFt'].toDouble(),
      features: PropertyFeatures.fromJson(json['features']),
    );
  }
}
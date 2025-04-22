// models/valuation_result.dart - FIXED WITH NULL SAFETY
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
    // Handle null location
    final locationJson = json['location'] ?? {};
    
    // Handle null valuation
    final valuationJson = json['valuation'] ?? {};
    
    // Handle null comparables or empty list
    final comparablesJson = json['comparables'] ?? [];
    
    return ValuationResult(
      location: LocationInfo.fromJson(locationJson),
      valuation: ValuationInfo.fromJson(valuationJson),
      comparables: (comparablesJson as List)
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
    // Safe conversion for lat/lng with defaults
    double safeLat = 0.0;
    double safeLng = 0.0;
    
    try {
      if (json['lat'] != null) {
        final dynamic lat = json['lat'];
        safeLat = (lat is int) ? lat.toDouble() : (lat is double) ? lat : 0.0;
      }
      
      if (json['lng'] != null) {
        final dynamic lng = json['lng'];
        safeLng = (lng is int) ? lng.toDouble() : (lng is double) ? lng : 0.0;
      }
    } catch (e) {
      print('Error parsing lat/lng: $e');
    }
    
    return LocationInfo(
      position: LatLng(safeLat, safeLng),
      address: json['address'] ?? 'Unknown location',
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
    // Safe conversion for numeric values with defaults
    int safeEstimatedValue = 0;
    double safeAreaInSqFt = 0.0;
    double safeAvgPricePerSqFt = 0.0;
    
    try {
      if (json['estimatedValue'] != null) {
        final dynamic value = json['estimatedValue'];
        safeEstimatedValue = (value is double) ? value.toInt() : (value is int) ? value : 0;
      }
      
      if (json['areaInSqFt'] != null) {
        final dynamic value = json['areaInSqFt'];
        safeAreaInSqFt = (value is int) ? value.toDouble() : (value is double) ? value : 0.0;
      }
      
      if (json['avgPricePerSqFt'] != null) {
        final dynamic value = json['avgPricePerSqFt'];
        safeAvgPricePerSqFt = (value is int) ? value.toDouble() : (value is double) ? value : 0.0;
      }
    } catch (e) {
      print('Error parsing numeric values: $e');
    }
    
    // Safe extraction of valuation factors
    List<ValuationFactor> factors = [];
    try {
      if (json['valuationFactors'] is List) {
        factors = (json['valuationFactors'] as List)
            .map((factor) => ValuationFactor.fromJson(factor))
            .toList();
      }
    } catch (e) {
      print('Error parsing valuation factors: $e');
    }
    
    return ValuationInfo(
      estimatedValue: safeEstimatedValue,
      areaInSqFt: safeAreaInSqFt,
      avgPricePerSqFt: safeAvgPricePerSqFt,
      zoning: json['zoning'] ?? 'residential',
      valuationFactors: factors,
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
      factor: json['factor'] ?? 'Unknown Factor',
      adjustment: json['adjustment'] ?? '0%',
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
    // Safe conversion of numeric values with defaults
    double safePrice = 0.0;
    double safeArea = 0.0;
    double safePricePerSqFt = 0.0;
    
    try {
      if (json['price'] != null) {
        final dynamic value = json['price'];
        safePrice = (value is int) ? value.toDouble() : (value is double) ? value : 0.0;
      }
      
      if (json['area'] != null) {
        final dynamic value = json['area'];
        safeArea = (value is int) ? value.toDouble() : (value is double) ? value : 0.0;
      }
      
      if (json['pricePerSqFt'] != null) {
        final dynamic value = json['pricePerSqFt'];
        safePricePerSqFt = (value is int) ? value.toDouble() : (value is double) ? value : 0.0;
      }
    } catch (e) {
      print('Error parsing numeric values for comparable: $e');
    }
    
    // Safe extraction of features with defaults
    PropertyFeatures safeFeatures;
    try {
      if (json['features'] is Map) {
        safeFeatures = PropertyFeatures.fromJson(json['features']);
      } else {
        safeFeatures = PropertyFeatures(nearWater: false, roadAccess: true, utilities: true);
      }
    } catch (e) {
      print('Error parsing features: $e');
      safeFeatures = PropertyFeatures(nearWater: false, roadAccess: true, utilities: true);
    }
    
    return ComparableProperty(
      id: json['id'] ?? 'unknown',
      address: json['address'] ?? 'Unknown',
      price: safePrice,
      area: safeArea,
      pricePerSqFt: safePricePerSqFt,
      features: safeFeatures,
    );
  }
}
// lib/core/services/location_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';

class LocationService {
  Future<List<Map<String, dynamic>>> _loadLocations() async {
    final String jsonString = await rootBundle.loadString('assets/data/ListofUnion05.json');
    // The JSON file is an array of objects, so we cast it as such.
    return (json.decode(jsonString) as List).cast<Map<String, dynamic>>();
  }

  Future<List<String>> getDivisions() async {
    final data = await _loadLocations();
    // Use a Set to get unique division names, then convert back to a List.
    return data.map((d) => d['বিভাগ'].toString().trim()).toSet().toList();
  }

  Future<List<String>> getDistricts(String division) async {
    final data = await _loadLocations();
    return data
        .where((d) => d['বিভাগ'].toString().trim() == division)
        .map((d) => d['জেলা'].toString().trim())
        .toSet()
        .toList();
  }

  Future<List<String>> getUpazilas(String division, String district) async {
    final data = await _loadLocations();
    return data
        .where((d) => d['বিভাগ'].toString().trim() == division && d['জেলা'].toString().trim() == district)
        .map((d) => d['উপজেলা'].toString().trim())
        .toSet()
        .toList();
  }

  Future<List<String>> getUnions(String division, String district, String upazila) async {
    final data = await _loadLocations();
    final locationData = data.firstWhere(
        (d) => d['বিভাগ'].toString().trim() == division && d['জেলা'].toString().trim() == district && d['উপজেলা'].toString().trim() == upazila);

    List<String> unions = [];
    // The union data is spread across multiple columns, so we iterate through the keys.
    locationData.forEach((key, value) {
      if (key.startsWith('ইউনিয়নসমূহ') || key.startsWith('Column')) {
        if (value != null && value.toString().trim().isNotEmpty) {
          unions.add(value.toString().trim());
        }
      }
    });
    return unions;
  }
}
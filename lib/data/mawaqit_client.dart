import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../models/mosque_info.dart';
import '../models/yearly_calendar.dart';

class MawaqitClient {
  static const _baseApi = 'https://mawaqit.net/api/2.0';
  static const _baseWeb = 'https://mawaqit.net';

  static final _confDataRegex = RegExp(
    r'(?:var|let)\s+confData\s*=\s*(.*?);',
    dotAll: true,
  );

  final Dio _dio;

  MawaqitClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Accept': 'application/json, text/html',
                if (!kIsWeb) 'User-Agent': 'Bilal/1.0',
              },
            ));

  /// Search mosques by name, city, or keyword.
  Future<List<MosqueInfo>> searchMosques(String query) async {
    try {
      final response = await _dio.get(
        '$_baseApi/mosque/search',
        queryParameters: {'word': query},
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => MosqueInfo.fromSearchJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw MawaqitException('Search failed: ${e.message}');
    }
  }

  /// Fetch the full confData for a mosque by scraping its page.
  /// Returns the raw parsed JSON map.
  Future<Map<String, dynamic>> fetchConfData(String mosqueSlug) async {
    try {
      final response = await _dio.get(
        '$_baseWeb/fr/$mosqueSlug',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/html'},
        ),
      );

      final html = response.data as String;
      final match = _confDataRegex.firstMatch(html);
      if (match == null) {
        throw MawaqitException(
          'Could not find confData in page for $mosqueSlug',
        );
      }

      final jsonStr = match.group(1)!;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return data;
    } on DioException catch (e) {
      throw MawaqitException('Failed to fetch mosque page: ${e.message}');
    } on FormatException catch (e) {
      throw MawaqitException('Failed to parse confData JSON: ${e.message}');
    }
  }

  /// Fetch the full yearly calendar for a mosque.
  Future<YearlyCalendar> fetchYearlyCalendar(String mosqueSlug) async {
    final confData = await fetchConfData(mosqueSlug);
    final calendarData = confData['calendar'];
    if (calendarData == null || calendarData is! List) {
      throw MawaqitException('No calendar data found in confData');
    }
    return YearlyCalendar.fromConfData(calendarData, mosqueSlug);
  }

  /// Fetch mosque info + calendar in one shot.
  Future<({MosqueInfo info, YearlyCalendar calendar})> fetchMosqueFull(
    String mosqueSlug,
  ) async {
    final confData = await fetchConfData(mosqueSlug);

    final calendarData = confData['calendar'];
    if (calendarData == null || calendarData is! List) {
      throw MawaqitException('No calendar data found in confData');
    }
    final calendar = YearlyCalendar.fromConfData(calendarData, mosqueSlug);

    final info = MosqueInfo(
      uuid: confData['uuid'] as String? ?? '',
      name: confData['name'] as String? ?? confData['label'] as String? ?? '',
      slug: mosqueSlug,
      localisation: confData['localisation'] as String?,
      phone: confData['phone'] as String?,
      email: confData['email'] as String?,
      site: confData['site'] as String?,
      image: (confData['image1'] ?? confData['image']) as String?,
      jumua: confData['jumua'] as String?,
      jumua2: confData['jumua2'] as String?,
      latitude: (confData['latitude'] as num?)?.toDouble(),
      longitude: (confData['longitude'] as num?)?.toDouble(),
      iqamaEnabled: confData['iqamaEnabled'] as bool? ?? false,
      hijriAdjustment: (confData['hijriAdjustment'] as num?)?.toInt() ?? 0,
    );

    return (info: info, calendar: calendar);
  }

  void dispose() {
    _dio.close();
  }
}

class MawaqitException implements Exception {
  final String message;
  const MawaqitException(this.message);

  @override
  String toString() => 'MawaqitException: $message';
}

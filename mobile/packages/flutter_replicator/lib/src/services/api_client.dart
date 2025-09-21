// lib/src/services/api_client.dart

import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../core/replicator_config.dart';
import '../models/sync_response.dart';

/// A network client for communicating with the replicator backend service using Dio.
class ApiClient {
  final ReplicatorConfig config;
  final Dio _dio;

  /// Creates an ApiClient instance.
  ///
  /// An optional [dio] instance can be provided to use a pre-configured Dio
  /// client (e.g., one with custom interceptors for authentication).
  ///
  /// If [dio] is `null`, a new Dio instance will be created internally. In this
  /// case, `config.baseUrl` must not be null.
  ApiClient({required this.config, Dio? dio})
      : _dio = dio ?? _createDefaultDio(config) {
    // If a custom Dio instance is provided, we don't modify its interceptors
    // to ensure we don't interfere with the user's setup.
    // The default instance already has logging and basic setup.
  }

  /// Creates a default Dio instance when one is not provided.
  static Dio _createDefaultDio(ReplicatorConfig config) {
    if (config.baseUrl == null || config.baseUrl!.isEmpty) {
      throw ArgumentError(
        'baseUrl must be provided in ReplicatorConfig when a custom Dio instance is not supplied.',
      );
    }
    return Dio(
      BaseOptions(
        baseUrl: config.baseUrl!,
        headers: {
          'Content-Type': 'application/json',
          // Note: User/Device specific headers are now added per-request
          // to support shared Dio instances.
        },
        // Set reasonable timeouts
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  /// Fetches incremental changes from the server since the last sync.
  Future<IncrementalSyncResponse> fetchIncrementalChanges(int lastSeqId) async {
    final responseData = await _get(
      '/sync',
      queryParameters: {
        'last_seq_id': lastSeqId,
        'limit': config.defaultPageLimit,
      },
    );
    return IncrementalSyncResponse.fromJson(responseData);
  }

  /// Fetches the list of tables to sync for a new device (full sync).
  Future<FullSyncInitResponse> fetchFullSyncInit() async {
    final responseData = await _get('/sync/full_init');
    return FullSyncInitResponse.fromJson(responseData);
  }

  /// Fetches a page of data for a specific table during a full sync.
  Future<FullSyncDataResponse> fetchFullSyncData(
    String tableName,
    String? pageToken,
  ) async {
    final queryParameters = {
      'table': tableName,
      'limit': config.defaultPageLimit,
      if (pageToken != null) 'page_token': pageToken,
    };
    final responseData = await _get(
      '/sync/full_data',
      queryParameters: queryParameters,
    );
    return FullSyncDataResponse.fromJson(responseData);
  }

  /// Private helper for making GET requests and handling Dio-specific errors.
  /// It adds replicator-specific headers to each request without modifying
  /// the shared Dio instance's defaults.
  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        // Add module-specific headers per request. This is safe for shared Dio instances.
        options: Options(
          headers: {
            'X-User-ID': config.userId,
            'X-Device-ID': config.deviceId,
          },
        ),
      );
      // Dio automatically decodes JSON, so response.data is typically a Map or List.
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      // Handle cases where the response might be an unexpected type.
      else if (response.data != null) {
        return json.decode(response.data.toString());
      }
      throw Exception('Received invalid response format from the server.');
    } on DioException catch (e) {
      // Provide more specific error messages based on the DioException type.
      log(
        'DioException caught in ApiClient: ${e.message}',
        name: 'ApiClient',
        error: e,
      );
      final errorMessage = _getErrorMessage(e);
      throw Exception('API Error: $errorMessage');
    } catch (e) {
      // Catch any other unexpected errors.
      log('Unexpected error in ApiClient: $e', name: 'ApiClient', error: e);
      throw Exception('An unknown network error occurred: $e');
    }
  }

  /// Extracts a user-friendly error message from a [DioException].
  String _getErrorMessage(DioException e) {
    if (e.response != null && e.response!.data is Map) {
      // Try to extract the specific error message from the response body.
      return e.response!.data['error'] ??
          'Server returned an error (${e.response!.statusCode}).';
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The connection has timed out. Please check your network.';
      case DioExceptionType.badResponse:
        return 'Received an invalid status code: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'The request to the server was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your network connection.';
      case DioExceptionType.unknown:
      default:
        return 'An unexpected network error occurred.';
    }
  }
}

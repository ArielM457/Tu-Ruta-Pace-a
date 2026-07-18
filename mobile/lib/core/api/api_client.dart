import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_environment.dart';
import 'api_exception.dart';

const Duration _requestTimeout = Duration(seconds: 20);

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnvironment.apiBaseUrl,
      connectTimeout: _requestTimeout,
      receiveTimeout: _requestTimeout,
    ),
  );
  dio.interceptors.add(_SupabaseTokenInterceptor());
  dio.interceptors.add(_ResponseEnvelopeInterceptor());
  return dio;
});

ApiException toApiException(DioException exception) {
  final error = exception.error;
  if (error is ApiException) {
    return error;
  }
  return const ApiConnectionException();
}

class _SupabaseTokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }
}

class _ResponseEnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      response.data = body['data'];
    }
    handler.next(response);
  }

  @override
  void onError(DioException exception, ErrorInterceptorHandler handler) {
    handler.next(exception.copyWith(error: _extractApiError(exception)));
  }

  ApiException _extractApiError(DioException exception) {
    final body = exception.response?.data;
    if (body is Map<String, dynamic> && body['error'] is Map<String, dynamic>) {
      final envelopeError = body['error'] as Map<String, dynamic>;
      return ApiException(
        code: envelopeError['code'] as String? ?? 'UNKNOWN_ERROR',
        message: envelopeError['message'] as String? ??
            'Ocurrió un error inesperado',
      );
    }
    return const ApiConnectionException();
  }
}

import 'package:dio/dio.dart';
import 'package:dio_http_client/costants.dart';
import 'package:dio_http_client/interceptors/error_interceptor.dart';
import 'package:dio_http_client/interceptors/logging_interceptor.dart';

import 'api_response.dart';
import 'base_http_client.dart';
import 'error_response.dart';

class AppHttpClient extends BaseHttpClient {
  final bool debug;
  final BaseOptions? baseOptions;

  AppHttpClient(
      {this.baseOptions,
      List<Interceptor>? interceptors,
      this.debug = true,
      int requestSendTimeout = HttpConstants.requestReceiveTimeout,
      int requestReceiveTimeout = HttpConstants.requestSendTimeout})
      : super(
            interceptors: interceptors ??
                [ErrorInterceptor(), if (debug) LoggingInterceptor()],
            useLogInterceptor: false,
            baseOptions: baseOptions,
            requestReceiveTimeout: requestReceiveTimeout,
            requestSendTimeout: requestSendTimeout);

  updateToken(String token) {
    baseOptions?.headers["Authorization"] = token;
  }

  @override
  ErrorResponse manageDioError(
    DioError e,
    StackTrace stacktrace, {
    dynamic Function(dynamic)? decoder,
  }) {
    if (e.response?.data != null && decoder != null) {
      try {
        dynamic res = decoder(e.response?.data);
        if (res is ApiResponse) {
          return ErrorResponse(e.response?.statusCode ?? 999, res.message ?? '',
              res.body.errorCode ?? "");
        }
      } catch (_) {
        return ErrorResponse(e.response?.statusCode ?? 999,
            e.response?.statusMessage ?? e.message, "");
      }
    }

    return ErrorResponse(e.response?.statusCode ?? 999,
        e.response?.statusMessage ?? e.message, "");
  }

  @override
  ErrorResponse manageError(Object e, StackTrace stacktrace) {
    return ErrorResponse(999, e.toString(), "");
  }

  @override
  ErrorResponse manageException(Exception e, StackTrace stacktrace) {
    return ErrorResponse(999, e.toString(), "");
  }
}

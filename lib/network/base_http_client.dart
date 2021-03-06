import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:dio_http_client/network/success_response.dart';
import 'package:flutter/foundation.dart';

import '../source/base_data_source.dart';
import 'base_request.dart';
import 'error_response.dart';

abstract class BaseHttpClient extends BaseDataSource<BaseRequest> {
  late Dio _dioClient;
  int? requestSendTimeout;
  int? requestReceiveTimeout;

  BaseHttpClient(
      {BaseOptions? baseOptions,
      List<Interceptor>? interceptors,
      bool useLogInterceptor = true,
      bool cached = false,
      this.requestSendTimeout,
      this.requestReceiveTimeout}) {
    setup(baseOptions, interceptors, useLogInterceptor);
  }

  Interceptors get interceptors => _dioClient.interceptors;

  Dio get http => _dioClient;

  void setup(
    BaseOptions? baseOptions,
    List<Interceptor>? interceptors,
    bool useLogInterceptor,
  ) {
    _dioClient = Dio(baseOptions);

    _dioClient.interceptors.addAll(interceptors ?? []);
    if (useLogInterceptor) {
      _dioClient.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  @override
  Future<Either<ErrorResponse, SuccessResponse<T>>> retrieveData<T>(
      BaseRequest request,
      {bool? cached,
      bool? forceRefresh,
      Duration? duration}) async {
    try {
      Options options = Options(
        headers: request.headers,
        method: request.method.rawValue,
        receiveDataWhenStatusError: true,
        receiveTimeout: request.receiveTimeout ?? requestReceiveTimeout,
        sendTimeout: request.sendTimeout ?? requestSendTimeout,
        responseType: request.responseType,
      );

      Response dioResponse = await _dioClient.request(
        request.completeUrl,
        data: request.formData ?? request.body,
        options: [
                  TargetPlatform.iOS,
                  TargetPlatform.android,
                  TargetPlatform.macOS,
                ].contains(defaultTargetPlatform) &&
                (cached ?? false)
            ? buildCacheOptions(
                duration ?? const Duration(days: 7),
                forceRefresh: forceRefresh,
                options: options,
              )
            : options,
        queryParameters: request.queryParameters,
      );

      final decoder = request.decoder;

      if (decoder != null) {
        final data = decoder(dioResponse.data);
        return Right(SuccessResponse<T>(dioResponse.statusCode, data));
      } else {
        return Right(SuccessResponse(dioResponse.statusCode, dioResponse.data));
      }
    } on DioError catch (e, stacktrace) {
      return Left(manageDioError(
        e,
        stacktrace,
        decoder: request.decoder,
      ));
    } on Exception catch (e, stacktrace) {
      return Left(manageException(e, stacktrace));
    } catch (e, stacktrace) {
      return Left(manageError(e, stacktrace));
    }
  }

  ErrorResponse manageDioError(
    DioError e,
    StackTrace stacktrace, {
    dynamic Function(dynamic)? decoder,
  });

  ErrorResponse manageException(Exception e, StackTrace stacktrace);

  ErrorResponse manageError(Object e, StackTrace stacktrace);
}

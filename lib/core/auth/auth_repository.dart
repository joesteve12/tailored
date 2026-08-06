import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dio_client.dart';
import 'models/user.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// POST /auth/login — path is carried over from the original plan
  /// document but NOT confirmed against an actual route in your backend
  /// (only the Google flow's service function was checked). Verify the
  /// path and body shape match before relying on this.
  Future<User> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _handleAuthResponse(response.data as Map<String, dynamic>);
  }

  /// POST /auth/google — path is an assumption (reasonable convention, not
  /// confirmed). The body key 'google_token' DOES match the parameter name
  /// in your google_auth() service function, so that part is solid; just
  /// double check the route itself.
  Future<User> loginWithGoogle({required String idToken}) async {
    final response = await _dio.post('/auth/google', data: {
      'google_token': idToken,
    });
    return _handleAuthResponse(response.data as Map<String, dynamic>);
  }

  /// POST /auth/register — confirmed against the real request/response
  /// schema you shared. Returns the same {access_token, user} shape as
  /// login, so registering logs the user straight in; no separate
  /// /auth/login call needed afterward.
  Future<User> registerWithPassword({
    required String businessName,
    required String ownerName,
    required String businessAddress,
    required List<String> specializations,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'business_name': businessName,
      'owner_name': ownerName,
      'business_address': businessAddress,
      'specializations': specializations,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return _handleAuthResponse(response.data as Map<String, dynamic>);
  }

  /// PUT /users/me — updates the logged-in business's profile. Only the
  /// non-null arguments are sent (the endpoint applies a partial update), so
  /// this backs both the "complete your profile" flow and any later edit.
  /// Returns the refreshed user and rewrites the cached-user JSON so a cold
  /// start restores the updated profile. Note: unlike login/register the
  /// response is the bare user object, not a {access_token, user} envelope, so
  /// the token is untouched here.
  Future<User> updateProfile({
    String? businessName,
    String? ownerName,
    String? businessAddress,
    List<String>? specializations,
    String? phone,
  }) async {
    final data = <String, dynamic>{};
    if (businessName != null) data['business_name'] = businessName;
    if (ownerName != null) data['owner_name'] = ownerName;
    if (businessAddress != null) data['business_address'] = businessAddress;
    if (specializations != null) data['specializations'] = specializations;
    if (phone != null) data['phone'] = phone;

    final response = await _dio.put('/users/me', data: data);
    final userJson = response.data as Map<String, dynamic>;
    await _tokenStorage.writeCachedUserJson(jsonEncode(userJson));
    return User.fromJson(userJson);
  }

  Future<void> logout() => _tokenStorage.clearSession();

  Future<User> _handleAuthResponse(Map<String, dynamic> data) async {
    final token = data['access_token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;

    await _tokenStorage.writeToken(token);
    await _tokenStorage.writeCachedUserJson(jsonEncode(userJson));

    return User.fromJson(userJson);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});

// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tocmanager/models/api_response.dart';
import 'package:http/http.dart' as http;
import 'package:tocmanager/services/constant.dart';

import '../models/Users.dart';

//login
Future<ApiResponse> Login(String email, String password) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    final response = await http.post(Uri.parse(loginURL),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password});
    switch (response.statusCode) {
      case 200:
        apiResponse.data = Users.fromJson(jsonDecode(response.body));
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        break;
      default:
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    apiResponse.error = serverError;
  }

  return apiResponse;
}

//register
Future<ApiResponse> Register(Map<String, dynamic> data) async {
  dynamic body = json.encode(data);

  ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  final response = await dio.post(registerURL,
      options: Options(headers: {
        'Accept': 'application/json',
      }),
      data: body);
  switch (response.statusCode) {
    case 200:
      if (response.data['status'] == "success") {
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = response.data['status'];
        apiResponse.message = response.data['message'];
        apiResponse.data = response.data['data'];
      } else {
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = response.data['status'];
        apiResponse.message = response.data['message'];
        apiResponse.data = response.data['data'];
      }
      break;
    case 403:
      apiResponse.error = response.data['message'];
      apiResponse.statusCode = response.statusCode;
      break;
    case 500:
      apiResponse.error = response.data['message'];
      apiResponse.statusCode = response.statusCode;
      break;
    default:
      apiResponse.error = somethingWentWrong;
      break;
  }

  return apiResponse;
}

//Users
Future<ApiResponse> getUsersDetail() async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.get(
      Uri.parse(userURL),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.data = jsonDecode(response.body);
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        break;
      default:
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    apiResponse.error = serverError;
  }

  return apiResponse;
}

//get token
Future<String> getToken() async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  return localStorage.getString('token') ?? '';
}

//get compagnie_id
Future<int> getCompagnie_id() async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  return localStorage.getInt('compagnie_id') ?? 0;
}

//get Users id
Future<int> getUsersId() async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  return localStorage.getInt('userId') ?? 0;
}

//get Users state
Future<int> getUserState() async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  return localStorage.getInt('userState') ?? 0;
}

//logout
Future<bool> logout() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return await pref.remove('token');
}

getUsers() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  String? json = pref.getString('user');
  Users user = Users.fromJson(jsonDecode(json!));
  return user;
}

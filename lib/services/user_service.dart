// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tocmanager/models/api_response.dart';
import 'package:http/http.dart' as http;
import 'package:tocmanager/services/constant.dart';

import '../models/user.dart';


//login
Future<ApiResponse> Login(String email, String password) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    final response = await http.post(Uri.parse(loginURL),
        headers: {'Accept': 'application/json'},
        body: {'eamil': email, 'password': password});
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

//Users
Future<ApiResponse> getUsersDetail() async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.post(
      Uri.parse(userURL),
      headers: {'Accept': 'application/json',
      'Authorization':'Bearer $token'
      },
      
    );
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

//get token
Future<String> getToken() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getString('token') ?? '';
}

//get Users id
Future<int> getUsersId() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getInt('UsersID') ?? 0;
}

//logout
Future<bool> logout() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return await pref.remove('token');
}

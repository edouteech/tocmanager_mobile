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
    print(response.statusCode);
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

//modify password
Future<ApiResponse> ModifyPassword(Map<String, dynamic> data) async {
  dynamic body = json.encode(data);

  Dio dio = Dio();
  ApiResponse apiResponse = ApiResponse();
  String token = await getToken();
  try {
    final response = await dio.post(modifyPaswwordURL,
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        }),
        data: body);
    switch (response.statusCode) {
      case 200:
        if (jsonDecode(response.data)['status'] == 'error') {
          apiResponse.message = jsonDecode(response.data)['message'];
          apiResponse.status = jsonDecode(response.data)['status'];
        } else {
          apiResponse.statusCode = response.statusCode;
          apiResponse.data = jsonDecode(response.data);
          apiResponse.status = jsonDecode(response.data)['status'];
        }

        break;
      case 422:
        final errors = jsonDecode(response.data)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        apiResponse.statusCode = response.statusCode;
        break;
      case 403:
        apiResponse.error = jsonDecode(response.data)['message'];
        apiResponse.statusCode = response.statusCode;
        break;
      default:
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    // apiResponse.error = serverError;
  }

  return apiResponse;
}

//chech grace period
Future<ApiResponse> SuscribeGrace(int compagnie_id) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse(
        '$suscribeGraceURL/$compagnie_id',
      ),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = jsonDecode(response.body)['status'];
        apiResponse.data = jsonDecode(response.body)['data'];
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        apiResponse.statusCode = response.statusCode;
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        apiResponse.statusCode = response.statusCode;
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

//suscribe
Future<ApiResponse> SuscribeCheck(int compagnie_id) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse(
        '$suscribeURL/$compagnie_id',
      ),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = jsonDecode(response.body)['status'];
        apiResponse.data = jsonDecode(response.body)['data'];
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        apiResponse.statusCode = response.statusCode;
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        apiResponse.statusCode = response.statusCode;
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

Future<ApiResponse> TableauDeBord(int compagnie_id) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.post(
        Uri.parse(
          tableauDeBordURL,
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: {
          'compagnie_id': compagnie_id.toString()
        });

    switch (response.statusCode) {
      case 200:
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = jsonDecode(response.body)['status'];
        apiResponse.data = jsonDecode(response.body)['data'];
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        apiResponse.statusCode = response.statusCode;
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        apiResponse.statusCode = response.statusCode;
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
  pref.remove('token');
  pref.remove('compagnie_id');
  pref.remove('userId');
  pref.remove('userState');
  return true;
}

getUsers() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  String? json = pref.getString('user');
  Users user = Users.fromJson(jsonDecode(json!));
  return user;
}

//read products
// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable

import 'dart:convert';

import 'package:tocmanager/models/api_response.dart';
import 'package:http/http.dart' as http;
import 'package:tocmanager/services/constant.dart';
import 'package:tocmanager/services/user_service.dart';
import 'package:dio/dio.dart';

//read sell
Future<ApiResponse> ReadSells(
  int compagnie_id,
) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$sellsURL?compagnie_id=$compagnie_id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.statusCode = response.statusCode;
        apiResponse.data = response.body;
        apiResponse.data = jsonDecode(response.body)['data']['data'] as List;

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
    print(e);
    apiResponse.error = serverError;
  }

  return apiResponse;
}

//create sells
Future<ApiResponse> CreateSells(Map<String, dynamic> ventes) async {
  dynamic body = json.encode(ventes);

  ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.post(sellsURL,
      options: Options(headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }),
      data: body);
  // print(response.data['message']);
  switch (response.statusCode) {
    case 200:
      if (response.data['status'] == "success") {
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = response.data['status'];
        apiResponse.message = response.data['message'];
      } else {
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = response.data['status'];
        apiResponse.message = response.data['message'];
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

//delete sells
Future<ApiResponse> DeleteSells(int compagnie_id, int sell_id) async {
  ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.delete(
    "$sellsURL/$sell_id?compagnie_id=$compagnie_id",
    options: Options(headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    }),
  );
  switch (response.statusCode) {
    case 200:
      if (response.data['status'] == "success") {
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = response.data['status'];
        apiResponse.message = response.data['message'];
      } else {
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = response.data['status'];
        apiResponse.message = response.data['message'];
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

//get Sells details
Future<ApiResponse> DetailsSells(int compagnie_id, int sell_id) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$sellsURL/$sell_id?compagnie_id=$compagnie_id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.statusCode = response.statusCode;
        apiResponse.data = jsonDecode(response.body)['data'] as List;

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
    print(e);
    apiResponse.error = serverError;
  }

  return apiResponse;
}

//Update sells
Future<ApiResponse> UpdateSells(
    Map<String, dynamic> ventes, int sell_id) async {
  dynamic body = json.encode(ventes);
  print(body);

  ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.put('$sellsURL/$sell_id',
      options: Options(headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }),
      data: body);
  print(response.statusCode);
  switch (response.statusCode) {
    case 200:
      if (response.data['status'] == "success") {
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = response.data['status'];
        apiResponse.message = response.data['message'];
      } else {
        apiResponse.statusCode = response.statusCode;
        apiResponse.status = response.data['status'];
        apiResponse.message = response.data['message'];
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

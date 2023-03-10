// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:tocmanager/models/api_response.dart';
import 'package:tocmanager/services/constant.dart';
import 'package:tocmanager/services/user_service.dart';
import 'package:http/http.dart' as http;

Future<ApiResponse> ReadSuppliers(
  int compagnie_id,
) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$suppliersURL?compagnie_id=$compagnie_id'),
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
    apiResponse.error = serverError;
  }

  return apiResponse;
}

//create suppliers
Future<ApiResponse> CreateSuppliers(String compagnie_id, String name,
    String? email, String? phone, int nature) async {
      
  ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.post('$suppliersURL?compagnie_id=$compagnie_id',
      options: Options(headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }),
      data: {"name": name, "email": email, "phone": phone, "nature": nature});
      
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

//delete suppliers

Future<ApiResponse> DeleteSuppliers(int compagnie_id, int supplier_id) async {
  ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.delete(
    '$suppliersURL/$supplier_id?compagnie_id=$compagnie_id',
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




Future<ApiResponse> UpdateSuppliers(String compagnie_id, String name,
    String? email, String? phone, int nature, int supplier_id) async {
  ApiResponse apiResponse = ApiResponse();
  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.put(
      '$suppliersURL/$supplier_id?compagnie_id=$compagnie_id',
      options: Options(headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }),
      data: {"name": name, "email": email, "phone": phone, "nature": nature});
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

//one Category
Future<ApiResponse> ReadOneSupplier(int compagnie_id, int supplier_id) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$suppliersURL/$supplier_id?compagnie_id=$compagnie_id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.statusCode = response.statusCode;
        apiResponse.data = response.body;
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
    apiResponse.error = serverError;
  }

  return apiResponse;
}

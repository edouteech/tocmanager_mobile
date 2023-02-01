// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:convert';
import 'package:tocmanager/models/api_response.dart';
import 'package:http/http.dart' as http;
import 'package:tocmanager/services/constant.dart';
import 'package:tocmanager/services/user_service.dart';

//get categories
Future<ApiResponse> ReadCategories(
  int compagnie_id,
) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$categoriesURL?compagnie_id=$compagnie_id'),
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

//create categories
Future<ApiResponse> CreateCategories(
    String compagnie_id, String name, String? parent_id) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    String token = await getToken();

    final response = await http.post(Uri.parse(categoriesURL),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: parent_id != null
            ? {
                'compagnie_id': compagnie_id,
                'name': name,
                'parent_id': parent_id
              }
            : {
                'compagnie_id': compagnie_id,
                'name': name,
              });

    switch (response.statusCode) {
      case 200:
        if (jsonDecode(response.body)['status'] == 'error') {
          apiResponse.message = jsonDecode(response.body)['message'];
          apiResponse.status = jsonDecode(response.body)['status'];
        } else {
          apiResponse.statusCode = response.statusCode;
          apiResponse.data = jsonDecode(response.body);
          apiResponse.status = jsonDecode(response.body)['status'];
        }

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

//delete category
Future<ApiResponse> DeleteCategories(int compagnie_id, int? category_id) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    String token = await getToken();
    final response = await http.delete(
      Uri.parse("$categoriesURL/$category_id?compagnie_id=$compagnie_id"),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    switch (response.statusCode) {
      case 200:
        if (jsonDecode(response.body)['status'] == 'error') {
          apiResponse.message = jsonDecode(response.body)['message'];
          apiResponse.status = jsonDecode(response.body)['status'];
        } else {
          apiResponse.statusCode = response.statusCode;
          apiResponse.data = jsonDecode(response.body);
          apiResponse.status = jsonDecode(response.body)['status'];
        }

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

//edit categories
Future<ApiResponse> EditCategories(String compagnie_id, String name,
    String? parent_id, int? category_id) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    String token = await getToken();

    final response = await http.put(
        Uri.parse("$categoriesURL/$category_id?compagnie_id=$compagnie_id"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: parent_id != null
            ? {
                'compagnie_id': compagnie_id,
                'name': name,
                'parent_id': parent_id
              }
            : {'compagnie_id': compagnie_id, 'name': name, 'parent_id':null});
    switch (response.statusCode) {
      case 200:
        if (jsonDecode(response.body)['status'] == 'error') {
          apiResponse.message = jsonDecode(response.body)['message'];
          apiResponse.status = jsonDecode(response.body)['status'];
          print(apiResponse.message);
          print(response.statusCode);
          print(response.body);
        } else {
          apiResponse.statusCode = response.statusCode;
          apiResponse.data = jsonDecode(response.body);
          apiResponse.status = jsonDecode(response.body)['status'];
          print(apiResponse.message);
          print(response.statusCode);
        }

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

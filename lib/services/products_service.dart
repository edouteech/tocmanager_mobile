//get categories
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:tocmanager/models/api_response.dart';
import 'package:tocmanager/services/constant.dart';
import 'package:tocmanager/services/user_service.dart';
import 'package:http/http.dart' as http;

//read products
Future<ApiResponse> ReadProducts(
  int compagnie_id,
) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$productsURL?compagnie_id=$compagnie_id'),
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

//create products
Future<ApiResponse> CreateProducts(
    int compagnie_id,
    int? category_id,
    String? name,
    int? quantity,
    dynamic price_sell,
    dynamic price_buy,
    int stock_min,
    int stock_max,
    String? tax_group,
    String? code) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    String token = await getToken();

    final response = await http.post(
        Uri.parse(categoriesURL),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: {
          

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

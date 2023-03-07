//get categories
// ignore_for_file: non_constant_identifier_names, avoid_print, unnecessary_null_comparison

import 'dart:convert';

import 'package:tocmanager/models/api_response.dart';
import 'package:tocmanager/services/constant.dart';
import 'package:tocmanager/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

//read products
Future<ApiResponse> ReadProducts(
  int compagnie_id,
) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$productsURL?compagnie_id=$compagnie_id&is_paginated=0'),
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

//create products
Future<ApiResponse> CreateProducts(
    int compagnie_id,
    String? category_id,
    String name,
    String quantity,
    dynamic price_sell,
    dynamic price_buy,
    String stock_min,
    String stock_max,
    String code) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    String token = await getToken();

    final response = await http
        .post(Uri.parse('$productsURL?compagnie_id=$compagnie_id'), headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    }, body: {
      'category_id': category_id.toString() == null ? null : category_id,
      'name': name,
      'quantity': quantity,
      'price_sell': price_sell,
      'price_buy': price_buy,
      'stock_min': stock_min,
      'stock_max': stock_max,
      'code': code.toString() == null ? null : code
    });
    print(category_id);

    switch (response.statusCode) {
      case 200:
        if (jsonDecode(response.body)['status'] == 'error') {
          apiResponse.message = jsonDecode(response.body)['message'];
          print(apiResponse.message);
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
    print(e);
    // apiResponse.error = serverError;
  }

  return apiResponse;
}

//delete category
Future<ApiResponse> DeleteProducts(int compagnie_id, int? product_id) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    String token = await getToken();
    final response = await http.delete(
      Uri.parse("$productsURL/$product_id?compagnie_id=$compagnie_id"),
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

//get one product
Future<ApiResponse> ReadProductbyId(int compagnie_id, int? product_id) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$productsURL/$product_id?compagnie_id=$compagnie_id'),
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

//update product
Future<ApiResponse> UpdateProducts(
    Map<String, dynamic> products, int product_id) async {
  Dio dio = Dio();
  dynamic body = json.encode(products);
  ApiResponse apiResponse = ApiResponse();

  String token = await getToken();
  try {
    final response = await dio.put('$productsURL/$product_id',
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        }),
        data: body);
    print(response.statusCode);

    switch (response.statusCode) {
      case 200:
        if (jsonDecode(response.data)['status'] == 'error') {
          apiResponse.message = jsonDecode(response.data)['message'];
          print(apiResponse.message);
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
    print(e);
    // apiResponse.error = serverError;
  }

  return apiResponse;
}

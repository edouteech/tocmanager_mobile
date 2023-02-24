// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:tocmanager/services/constant.dart';
import 'package:tocmanager/services/user_service.dart';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import 'package:dio/dio.dart';

//read buys
Future<ApiResponse> ReadBuys(
  int compagnie_id,
  int page
) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$buysURL?compagnie_id=$compagnie_id&page=$page'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.statusCode = response.statusCode;
        apiResponse.data = response.body;
        apiResponse.data = jsonDecode(response.body)['data']['data'] as List;
         apiResponse.current_page =
            jsonDecode(response.body)['data']['current_page'];
        apiResponse.next_page_url = jsonDecode(response.body)['data']['next_page_url'];
        apiResponse.prev_page_url = jsonDecode(response.body)['data']['prev_page_url'];
        apiResponse.totalPage = jsonDecode(response.body)['data']['total'];

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

//create buys
Future<ApiResponse> CreateBuys(
  Map<String, dynamic> achats,
) async {
  dynamic body = json.encode(achats);

  ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.post(buysURL,
      options: Options(headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }),
      data: body);

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

//delete buys
Future<ApiResponse> DeleteBuys(int compagnie_id, int buy_id) async {
  ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.delete(
    "$buysURL/$buy_id?compagnie_id=$compagnie_id",
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

//get Buys details
Future<ApiResponse> DetailsBuys(int compagnie_id, int buy_id) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$buysURL/$buy_id?compagnie_id=$compagnie_id'),
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
    apiResponse.error = serverError;
  }

  return apiResponse;
}

//Update sells
Future<ApiResponse> UpdateBuys(
    Map<String, dynamic> achats, int buy_id) async {
  dynamic body = json.encode(achats);



  ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.put('$buysURL/$buy_id',
      options: Options(headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }),
      data: body);
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


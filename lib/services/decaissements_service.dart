// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tocmanager/models/api_response.dart';
import 'package:tocmanager/services/constant.dart';
import 'package:http/http.dart' as http;
import 'package:tocmanager/services/user_service.dart';

Future<ApiResponse> ReadDecaissements(int compagnie_id, int buy_id) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse('$decaissementsURL?compagnie_id=$compagnie_id&buy_id=$buy_id'),
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

//create decaissement
Future<ApiResponse> CreateDecaissement(
    Map<String, dynamic> decaissement, int compagnie_id, int buy_id) async {
  dynamic body = json.encode(decaissement);

  ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.post(
      "$decaissementsURL?compagnie_id=$compagnie_id&buy_id=$buy_id",
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


//delete decaissement 

Future<ApiResponse> DeleteDecaissement(int compagnie_id, int buy_id)async{
   ApiResponse apiResponse = ApiResponse();

  Dio dio = Dio();
  String token = await getToken();
  final response = await dio.delete(
    "$decaissementsURL/$buy_id?compagnie_id=$compagnie_id",
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

// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:tocmanager/models/api_response.dart';
import 'package:tocmanager/services/constant.dart';
import 'package:http/http.dart' as http;
import 'package:tocmanager/services/user_service.dart';

Future<ApiResponse> ReadDecaissements(int compagnie_id, int buy_id) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();

    final response = await http.get(
      Uri.parse(
          '$decaissementsURL?compagnie_id=$compagnie_id&buy_id=$buy_id'),
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
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/customer.dart';

class ApiService {
  static const String baseUrl = 'https://dummyjson.com';
  static const Duration timeoutDuration = Duration(seconds: 10);
  // Fetch paginated customers
  static Future<List<Customer>> fetchCustomers({
    required int limit,
    required int skip,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/users?limit=$limit&skip=$skip');
      final response = await http.get(uri).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = data['users'] as List;
        return users.map((user) => Customer.fromJson(user)).toList();
      } else {
        throw HttpException(
          'Failed to load customers. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw const SocketException('No internet connection');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  // Search customers by name
  static Future<List<Customer>> searchCustomers(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    try {
      final uri = Uri.parse(
        '$baseUrl/users/search?q=${Uri.encodeComponent(query)}',
      );
      final response = await http.get(uri).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = data['users'] as List;
        return users.map((user) => Customer.fromJson(user)).toList();
      } else {
        throw HttpException(
          'Failed to search customers. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw const SocketException('No internet connection');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }
}

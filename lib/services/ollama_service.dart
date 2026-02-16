import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/transaction.dart';
import '../domain/models/category.dart';
import '../domain/models/account.dart';

class OllamaService {
  final String baseUrl;
  final String model;

  OllamaService({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'gemma3', // User specified gemma3
  });

  /// Check if the Ollama service is reachable
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/')).timeout(
        const Duration(milliseconds: 500),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Categorize a transaction description using the LLM
  /// Returns the name of the most likely category from the provided list
  Future<String?> categorizeTransaction(
    String description,
    List<Category> availableCategories,
  ) async {
    if (availableCategories.isEmpty) return null;

    final categoriesString = availableCategories.map((c) => c.name).join(', ');
    
    final prompt = '''
You are a financial assistant. Categorize the transaction description below into one of the following categories:
[$categoriesString]

Transaction: "$description"

Return ONLY the exact category name from the list. If none fit perfectly, pick the closest one. If it is completely ambiguous, return "Uncategorized".
''';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'prompt': prompt,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prediction = (data['response'] as String).trim();
        
        // Basic cleanup in case the model adds extra text
        for (final category in availableCategories) {
          if (prediction.toLowerCase().contains(category.name.toLowerCase())) {
            return category.id; // Return ID for easier use, logic matches name
          }
        }
      }
      return null;
    } catch (e) {
      print('Error calling Ollama: $e');
      return null;
    }
  }

  /// Parses a natural language query into a structured search filter.
  Future<Map<String, dynamic>?> parseSearchIntent(
    String query,
    List<Category> categories,
    List<Account> accounts,
  ) async {
    final categoriesList = categories.map((c) => '{"id": "${c.id}", "name": "${c.name}"}').join(', ');
    final accountsList = accounts.map((a) => '{"id": "${a.id}", "name": "${a.name}"}').join(', ');
    final now = DateTime.now();

    final prompt = '''
You are a financial data assistant. Your task is to convert the user's natural language search query into a JSON filter object.

Today's date is ${now.toIso8601String()}.

Available Categories: [$categoriesList]
Available Accounts: [$accountsList]

The JSON schema should be:
{
  "searchQuery": string (optional, sub-string matching on description/notes),
  "type": "withdrawal" | "deposit" | "transfer" (optional),
  "accountId": string (ID from accounts list, optional),
  "categoryId": string (ID from categories list, optional),
  "startDate": ISO string (optional),
  "endDate": ISO string (optional),
  "minAmount": number (optional),
  "maxAmount": number (optional)
}

Query: "$query"

Return ONLY valid JSON. If you are unsure about a field, leave it out. Do not add any explanation.
''';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'prompt': prompt,
          'stream': false,
          'format': 'json', // Ollama supports JSON mode
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = (data['response'] as String).trim();
        return jsonDecode(responseText) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error parsing search intent: $e');
      return null;
    }
  }

  /// Get financial insights or chat with the data
  Future<String> chat(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['content'];
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error connecting to Ollama: $e';
    }
  }
}

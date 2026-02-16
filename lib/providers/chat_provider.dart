import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/transaction_filter.dart';
import '../domain/models/transaction_type.dart';
import 'providers.dart';

part 'chat_provider.g.dart';

@riverpod
class ChatSession extends _$ChatSession {
  @override
  List<ChatMessage> build() {
    return [
       ChatMessage(
        id: const Uuid().v4(),
        content: 'Hello! I am your AI financial assistant. How can I help you search for transactions today?',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    ];
  }

  Future<void> sendMessage(String text) async {
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = [...state, userMessage];

    final ollama = ref.read(ollamaServiceProvider);
    
    // Show typing indicator or similar if we had one.
    // For now, just wait for response.
    
    try {
      final categories = await ref.read(categoriesProvider.future);
      final accounts = await ref.read(accountsProvider.future);
      
      final intent = await ollama.parseSearchIntent(text, categories, accounts);
      
      if (intent != null && intent.isNotEmpty) {
        // Map types safely
        TransactionType? type;
        if (intent['type'] != null) {
          type = TransactionType.values.where(
            (e) => e.name == intent['type']
          ).firstOrNull;
        }

        String? categoryId = intent['categoryId']?.toString();
        String? accountId = intent['accountId']?.toString();

        // Resolve names to IDs
        if (categoryId != null) {
          final matchesId = categories.any((c) => c.id == categoryId);
          if (!matchesId) {
            final matchByName = categories.where(
              (c) => c.name.toLowerCase() == categoryId!.toLowerCase()
            ).firstOrNull;
            if (matchByName != null) categoryId = matchByName.id;
          }
        }

        if (accountId != null) {
          final matchesId = accounts.any((a) => a.id == accountId);
          if (!matchesId) {
            final matchByName = accounts.where(
              (a) => a.name.toLowerCase() == accountId!.toLowerCase()
            ).firstOrNull;
            if (matchByName != null) accountId = matchByName.id;
          }
        }

        final filter = TransactionFilter(
          searchQuery: intent['searchQuery'],
          type: type,
          accountId: accountId,
          categoryId: categoryId,
          startDate: intent['startDate'] != null ? DateTime.tryParse(intent['startDate']) : null,
          endDate: intent['endDate'] != null ? DateTime.tryParse(intent['endDate']) : null,
          minAmount: intent['minAmount']?.toDouble(),
          maxAmount: intent['maxAmount']?.toDouble(),
        );

        final assistantMessage = ChatMessage(
          id: const Uuid().v4(),
          content: "I've found and applied the matching transactions for you.",
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          metadata: intent,
        );

        state = [...state, assistantMessage];
        
        // Auto-apply filter
        ref.read(transactionFiltersProvider.notifier).setFilters(filter);
        
        // Auto-navigate to Transactions tab (index 2)
        ref.read(navigationProvider.notifier).setTab(2);
      } else {
         final response = await ollama.chat(text);
         final assistantMessage = ChatMessage(
          id: const Uuid().v4(),
          content: response,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        );
        state = [...state, assistantMessage];
      }
    } catch (e) {
       final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        content: 'Sorry, I encountered an error: $e',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      state = [...state, errorMessage];
    }
  }

  void clearChat() {
    state = [
      ChatMessage(
        id: const Uuid().v4(),
        content: 'Chat cleared. How else can I help?',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

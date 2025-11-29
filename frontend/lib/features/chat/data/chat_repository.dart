import 'package:frontend/core/services/local_db_service.dart';
import 'package:frontend/features/auth/application/services/chat_service.dart';

class ChatRepository {
  final ApiChatService _apiService = ApiChatService();
  final LocalDbService _localDbService = LocalDbService();

  /// Returns a stream of messages.
  /// Emits cached messages first, then fetches from network and emits updated messages.
  Stream<List<dynamic>> getMessages(String classId) async* {
    // 1. Emit cached messages immediately
    final cachedMessages = await _localDbService.getCachedMessages(classId);
    if (cachedMessages.isNotEmpty) {
      yield cachedMessages;
    }

    // 2. Fetch from network
    try {
      final networkMessages = await _apiService.getChatHistory(classId);
      
      // 3. Update cache
      await _localDbService.cacheMessages(classId, networkMessages);
      
      // 4. Emit updated messages (read from cache again to ensure consistency)
      final updatedMessages = await _localDbService.getCachedMessages(classId);
      yield updatedMessages;
    } catch (e) {
      // If network fails, we just stop. The user has the cached data.
      print("ChatRepository: Network fetch failed: $e");
      if (cachedMessages.isEmpty) {
        // If we had no cache and network failed, rethrow or yield empty
        yield []; 
      }
    }
  }
}

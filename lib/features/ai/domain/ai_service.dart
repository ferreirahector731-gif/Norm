import 'ai_config.dart';
import 'chat_message_model.dart';

class AIService {
  AIService();

  Stream<String> chat({
    required List<ChatMessage> history,
    required String newMessage,
    required AIProvider providerOverride,
    required AIReasoningMode mode,
  }) async* {
    yield 'Respuesta de IA no implementada aún.';
  }
}

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/supabase_config.dart';
import '../models/topic_model.dart';
import '../models/cue_card_model.dart';
import '../models/question_model.dart';
import '../models/vocabulary_model.dart';

abstract class SpeakingRemoteDataSource {
  Future<List<TopicModel>> getPart1Topics();
  Future<List<CueCardModel>> getCueCards();
  Future<List<QuestionModel>> getQuestionsByTopic(String topicId);
  Future<List<VocabularyModel>> getVocabularyItems({String? category});
}

class SpeakingRemoteDataSourceImpl implements SpeakingRemoteDataSource {
  @override
  Future<List<TopicModel>> getPart1Topics() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw ServerException('Supabase is not configured or offline');
    }

    try {
      final response = await client.from('topics').select().order('created_at', ascending: true);
      final List data = response as List;
      return data
          .map((json) => TopicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch topics from Supabase: $e');
    }
  }

  @override
  Future<List<CueCardModel>> getCueCards() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw ServerException('Supabase is not configured or offline');
    }

    try {
      final response = await client.from('cue_cards').select().order('created_at', ascending: true);
      final List data = response as List;
      return data
          .map((json) => CueCardModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch cue cards from Supabase: $e');
    }
  }

  @override
  Future<List<QuestionModel>> getQuestionsByTopic(String topicId) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw ServerException('Supabase is not configured or offline');
    }

    try {
      final response = await client
          .from('questions')
          .select()
          .eq('topic_id', topicId)
          .order('order_index', ascending: true);
      final List data = response as List;
      return data
          .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch questions from Supabase: $e');
    }
  }

  @override
  Future<List<VocabularyModel>> getVocabularyItems({String? category}) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw ServerException('Supabase is not configured or offline');
    }

    try {
      var query = client.from('vocabulary').select();
      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.eq('topic_tag', category);
      }
      final response = await query.order('phrase', ascending: true);
      final List data = response as List;
      return data
          .map((json) => VocabularyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch vocabulary from Supabase: $e');
    }
  }
}

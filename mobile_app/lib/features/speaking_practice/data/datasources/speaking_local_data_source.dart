import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/topic_model.dart';
import '../models/cue_card_model.dart';
import '../models/question_model.dart';
import '../models/vocabulary_model.dart';
import '../models/mock_evaluation_model.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/entities/vocabulary_entity.dart';

abstract class SpeakingLocalDataSource {
  Future<List<TopicModel>> getPart1Topics();
  Future<List<CueCardModel>> getCueCards();
  Future<CueCardModel> getCueCardById(String id);
  Future<List<QuestionModel>> getQuestionsByTopic(String topicId);
  Future<List<VocabularyModel>> getVocabularyItems({String? category});
  Future<bool> toggleBookmark(String itemId, bool currentStatus);
  Future<List<String>> getBookmarkedIds();
  Future<MockEvaluationModel> saveMockTestEvaluation(MockEvaluationModel evaluation);
  Future<List<MockEvaluationModel>> getMockTestEvaluations();

  // Cache methods for offline support
  Future<void> cacheTopics(List<TopicModel> topics);
  Future<void> cacheCueCards(List<CueCardModel> cueCards);
  Future<void> cacheQuestions(String topicId, List<QuestionModel> questions);
  Future<void> cacheVocabulary(List<VocabularyModel> vocabulary);
}

class SpeakingLocalDataSourceImpl implements SpeakingLocalDataSource {
  final SharedPreferences sharedPreferences;

  SpeakingLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<String>> getBookmarkedIds() async {
    try {
      final list = sharedPreferences.getStringList(AppConstants.prefBookmarks);
      return list ?? [];
    } catch (e) {
      throw CacheException('Failed to read bookmarks from cache');
    }
  }

  @override
  Future<bool> toggleBookmark(String itemId, bool currentStatus) async {
    try {
      final bookmarks = await getBookmarkedIds();
      final updated = List<String>.from(bookmarks);
      if (currentStatus) {
        updated.remove(itemId);
      } else {
        if (!updated.contains(itemId)) {
          updated.add(itemId);
        }
      }
      await sharedPreferences.setStringList(AppConstants.prefBookmarks, updated);
      return !currentStatus;
    } catch (e) {
      throw CacheException('Failed to toggle bookmark');
    }
  }

  @override
  Future<List<TopicModel>> getPart1Topics() async {
    try {
      final bookmarks = await getBookmarkedIds();
      List<TopicModel> topics = [];
      final cachedJson = sharedPreferences.getString('cached_topics');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final list = jsonDecode(cachedJson) as List<dynamic>;
          topics = list.map((e) => TopicModel.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
      if (topics.isEmpty) {
        topics = _part1RawTopics;
      }
      return topics.map((topic) {
        final isBookmarked = bookmarks.contains(topic.id);
        return TopicModel(
          id: topic.id,
          title: topic.title,
          description: topic.description,
          category: topic.category,
          partNumber: topic.partNumber,
          questionsCount: topic.questionsCount,
          bandTarget: topic.bandTarget,
          isBookmarked: isBookmarked,
          iconCode: topic.iconCode,
        );
      }).toList();
    } catch (e) {
      throw CacheException('Failed to fetch Part 1 topics');
    }
  }

  @override
  Future<List<CueCardModel>> getCueCards() async {
    try {
      final bookmarks = await getBookmarkedIds();
      List<CueCardModel> cards = [];
      final cachedJson = sharedPreferences.getString('cached_cue_cards');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final list = jsonDecode(cachedJson) as List<dynamic>;
          cards = list.map((e) => CueCardModel.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
      if (cards.isEmpty) {
        cards = _rawCueCards;
      }
      return cards.map((cueCard) {
        final isBookmarked = bookmarks.contains(cueCard.id);
        return CueCardModel(
          id: cueCard.id,
          title: cueCard.title,
          topicArea: cueCard.topicArea,
          cuePrompt: cueCard.cuePrompt,
          bulletPoints: cueCard.bulletPoints,
          storyIdeas: cueCard.storyIdeas,
          band9ModelAnswer: cueCard.band9ModelAnswer,
          shortSampleAnswer: cueCard.shortSampleAnswer,
          keyCollocations: cueCard.keyCollocations,
          part3FollowUps: cueCard.part3FollowUps,
          isBookmarked: isBookmarked,
        );
      }).toList();
    } catch (e) {
      throw CacheException('Failed to fetch cue cards');
    }
  }

  @override
  Future<CueCardModel> getCueCardById(String id) async {
    try {
      final cards = await getCueCards();
      return cards.firstWhere(
        (c) => c.id == id,
        orElse: () => _rawCueCards.first,
      );
    } catch (e) {
      throw CacheException('Cue card not found');
    }
  }

  @override
  Future<List<QuestionModel>> getQuestionsByTopic(String topicId) async {
    try {
      final cachedJson = sharedPreferences.getString('cached_questions_$topicId');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final list = jsonDecode(cachedJson) as List<dynamic>;
          final questions = list.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>)).toList();
          if (questions.isNotEmpty) return questions;
        } catch (_) {}
      }
      final questions = _rawQuestions[topicId];
      if (questions != null && questions.isNotEmpty) {
        return questions;
      }
      return [];
    } catch (e) {
      throw CacheException('Questions not found for topic');
    }
  }

  @override
  Future<List<VocabularyModel>> getVocabularyItems({String? category}) async {
    try {
      List<VocabularyModel> vocab = [];
      final cachedJson = sharedPreferences.getString('cached_vocabulary');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final list = jsonDecode(cachedJson) as List<dynamic>;
          vocab = list.map((e) => VocabularyModel.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
      if (vocab.isEmpty) {
        vocab = _rawVocabulary;
      }
      if (category == null || category.isEmpty || category == 'All') {
        return vocab;
      }
      return vocab.where((item) => item.topicTag.toLowerCase() == category.toLowerCase()).toList();
    } catch (e) {
      throw CacheException('Failed to fetch vocabulary items');
    }
  }

  @override
  Future<MockEvaluationModel> saveMockTestEvaluation(MockEvaluationModel evaluation) async {
    try {
      final existingJson = sharedPreferences.getString(AppConstants.prefCompletedTests);
      List<dynamic> list = [];
      if (existingJson != null) {
        list = jsonDecode(existingJson);
      }
      list.add(evaluation.toJson());
      await sharedPreferences.setString(AppConstants.prefCompletedTests, jsonEncode(list));
      return evaluation;
    } catch (e) {
      throw CacheException('Failed to save mock test evaluation');
    }
  }

  @override
  Future<List<MockEvaluationModel>> getMockTestEvaluations() async {
    try {
      final json = sharedPreferences.getString(AppConstants.prefCompletedTests);
      if (json == null) return [];
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => MockEvaluationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw CacheException('Failed to read mock test evaluations');
    }
  }

  // ===== Offline Cache Implementation =====

  @override
  Future<void> cacheTopics(List<TopicModel> topics) async {
    try {
      final json = jsonEncode(topics.map((t) => t.toJson()).toList());
      await sharedPreferences.setString('cached_topics', json);
    } catch (_) {}
  }

  @override
  Future<void> cacheCueCards(List<CueCardModel> cueCards) async {
    try {
      final json = jsonEncode(cueCards.map((c) => c.toJson()).toList());
      await sharedPreferences.setString('cached_cue_cards', json);
    } catch (_) {}
  }

  @override
  Future<void> cacheQuestions(String topicId, List<QuestionModel> questions) async {
    try {
      final json = jsonEncode(questions.map((q) => q.toJson()).toList());
      await sharedPreferences.setString('cached_questions_$topicId', json);
    } catch (_) {}
  }

  @override
  Future<void> cacheVocabulary(List<VocabularyModel> vocabulary) async {
    try {
      final json = jsonEncode(vocabulary.map((v) => v.toJson()).toList());
      await sharedPreferences.setString('cached_vocabulary', json);
    } catch (_) {}
  }

  // Authentic Sample IELTS Database
  static final List<TopicModel> _part1RawTopics = [
    const TopicModel(
      id: 'p1_tech',
      title: 'Artificial Intelligence & Tech',
      description: 'Discussing daily smart gadgets, automated systems, and modern digital lifestyle.',
      category: TopicCategory.technology,
      partNumber: 1,
      questionsCount: 4,
      bandTarget: '8.0+',
      iconCode: 'smart_toy',
    ),
    const TopicModel(
      id: 'p1_work',
      title: 'Work & Studies',
      description: 'Core IELTS topic: current job, career aspirations, and educational background.',
      category: TopicCategory.workAndStudy,
      partNumber: 1,
      questionsCount: 5,
      bandTarget: '7.5+',
      iconCode: 'business_center',
    ),
    const TopicModel(
      id: 'p1_hometown',
      title: 'Hometown & Living Space',
      description: 'Describing your hometown, public transport amenities, and future changes.',
      category: TopicCategory.travelAndPlaces,
      partNumber: 1,
      questionsCount: 4,
      bandTarget: '7.0+',
      iconCode: 'location_city',
    ),
    const TopicModel(
      id: 'p1_environment',
      title: 'Environmental Protection',
      description: 'Recycling habits, renewable green habits, and weather changes.',
      category: TopicCategory.environment,
      partNumber: 1,
      questionsCount: 4,
      bandTarget: '8.0+',
      iconCode: 'eco',
    ),
    const TopicModel(
      id: 'p1_culture',
      title: 'Traditional Art & Music',
      description: 'Live concerts, classical vs modern music, and cultural heritage.',
      category: TopicCategory.artAndCulture,
      partNumber: 1,
      questionsCount: 4,
      bandTarget: '7.5+',
      iconCode: 'music_note',
    ),
  ];

  static final List<CueCardModel> _rawCueCards = [
    const CueCardModel(
      id: 'cc_1',
      title: 'A Difficult Decision with a Positive Outcome',
      topicArea: 'Life Experience & Problem Solving',
      cuePrompt: 'Describe a difficult decision you made that had a positive outcome in the end.',
      bulletPoints: [
        'What the decision was and when you made it',
        'Why it was difficult or stressful to make',
        'What advice or factors influenced your final choice',
        'And explain why the outcome turned out to be so rewarding.',
      ],
      storyIdeas: [
        'Option A: Leaving a secure corporate job to learn software engineering',
        'Option B: Choosing to study abroad in a foreign country despite homesickness',
        'Option C: Turning down a safe inheritance to build a sustainable local startup',
      ],
      shortSampleAnswer:
        'A challenging decision I made was leaving my comfortable corporate job to pivot into software engineering, which initially felt daunting but eventually doubled my career fulfillment.',
      band9ModelAnswer: 
        'Without a shadow of a doubt, making consequential life choices is seldom straightforward. I would like to talk about the pivotal juncture three years ago when I resolved to transition from my stable corporate desk job into high-tech software engineering. \n\n'
        'At that time, I was working as a junior project coordinator. While the compensation was dependable, I felt professionally stagnant and realized my genuine passion lay in technology and problem solving. It was an excruciating dilemma because it demanded resigning from a steady income stream to enroll in an intensive boot-camp. My peers were somewhat skeptical, arguing that abandoning stability was a reckless gamble.\n\n'
        'Nonetheless, after conducting thorough research and seeking counsel from a seasoned mentor, I took the leap of faith. The initial months were undeniably grueling—I had to burn the midnight oil mastering complex algorithmic paradigms. However, persevering through that steep learning curve yielded spectacular rewards. Within eight months, I secured a role at an international tech firm with double my prior remuneration and immensely greater job satisfaction. Looking back, that difficult choice taught me that calculated risks and resilience invariably pay dividends.',
      keyCollocations: [
        'Without a shadow of a doubt',
        'Pivotal juncture',
        'Professionally stagnant',
        'Leap of faith',
        'Burn the midnight oil',
        'Pay dividends'
      ],
      part3FollowUps: [
        'Why do some individuals struggle more than others with decision making?',
        'Do you think elders always give more sensible advice compared to friends?',
        'How does technology influence everyday decision making nowadays?'
      ],
    ),
    const CueCardModel(
      id: 'cc_2',
      title: 'An Ambitious Person You Greatly Admire',
      topicArea: 'People & Personality',
      cuePrompt: 'Describe an ambitious person you know and greatly admire.',
      bulletPoints: [
        'Who this person is and your relationship to them',
        'What their personal or professional goals are',
        'How they work tirelessly to achieve those goals',
        'And explain why you hold them in such high esteem.',
      ],
      storyIdeas: [
        'Option A: An older sibling or relative who became a dedicated doctor/surgeon',
        'Option B: A local entrepreneur who built an educational academy from nothing',
        'Option C: A school teacher who overcame physical disability to mentor students',
      ],
      shortSampleAnswer:
        'The ambitious person I admire most is my elder sister, who navigated grueling pediatric surgical residency to provide free healthcare in rural clinics.',
      band9ModelAnswer:
        'When thinking of ambition and tenacity, the first person that spontaneously springs to mind is my elder sister, Nodira. She is a dedicated pediatric surgeon whose unwavering commitment to healthcare has always left me in awe.\n\n'
        'Ever since our teenage years, she harbored an aspiration to spearhead pediatric medical research in underserved regions. Achieving this required navigating an exceptionally competitive academic pipeline. She completed her residency while concurrently authoring peer-reviewed medical journals. Her diligence is astonishing; she maintains an impeccable work ethic without ever succumbing to burnout.\n\n'
        'What I admire most is that her ambition is not driven by vanity or monetary gain, but rather by an altruistic desire to alleviate suffering among vulnerable children. Her tenacity serves as a continuous beacon of inspiration for my own personal and academic endeavors.',
      keyCollocations: [
        'Spontaneously springs to mind',
        'Unwavering commitment',
        'Harbored an aspiration',
        'Impeccable work ethic',
        'Beacon of inspiration'
      ],
      part3FollowUps: [
        'Is ambition always a positive character trait, or can it have detrimental effects?',
        'How can parents nurture healthy ambition in young children?',
        'Are people in your country generally more career-oriented today than in past generations?'
      ],
    ),
    const CueCardModel(
      id: 'cc_3',
      title: 'An Eco-Friendly Rule or Law You Would Introduce',
      topicArea: 'Environment & Society',
      cuePrompt: 'Describe an environmental regulation or law you would enact if you had the authority.',
      bulletPoints: [
        'What the regulation would entail',
        'How it would be enforced across communities',
        'Who would be most affected by this mandate',
        'And explain how it would positively impact the ecological balance.',
      ],
      storyIdeas: [
        'Option A: Strict ban on single-use plastic packaging in retail',
        'Option B: Mandatory solar panel installations on all new commercial buildings',
        'Option C: Free public electric transit subsidized by vehicle congestion charges',
      ],
      shortSampleAnswer:
        'If given legislative power, I would implement a complete ban on single-use non-biodegradable plastics combined with tax incentives for green bio-packaging.',
      band9ModelAnswer:
        'If I were endowed with legislative authority, the first measure I would champion is a comprehensive ban on single-use non-biodegradable commercial packaging, paired with mandatory corporate composting programs.\n\n'
        'Under this scheme, supermarkets and retail conglomerates would be prohibited from supplying petroleum-based plastic bags and non-recyclable wraps. Instead, they would be legally obliged to transition to mycelium-based or sugarcane bio-packaging. Strict fines would be levied against repeat offenders, while companies proactively adopting circular economy practices would receive tax credits.\n\n'
        'This initiative would profoundly curb municipal landfill overflow and drastically reduce marine pollution. Furthermore, it would stimulate green tech innovation and sensitize the general public toward conscious consumerism.',
      keyCollocations: [
        'Endowed with legislative authority',
        'Champion a measure',
        'Circular economy practices',
        'Curb municipal landfill overflow',
        'Conscious consumerism'
      ],
      part3FollowUps: [
        'Who bears the primary responsibility for tackling climate change: governments or consumers?',
        'Do you think environmental penalties are more effective than educational awareness campaigns?',
        'What role should international cooperation play in environmental governance?'
      ],
    ),
  ];

  static final Map<String, List<QuestionModel>> _rawQuestions = {
    'p1_tech': [
      const QuestionModel(
        id: 'q1_1',
        topicId: 'p1_tech',
        questionText: 'Do you frequently use artificial intelligence tools in your daily routine?',
        ideas: [
          'Daily tools: ChatGPT, Grammarly, smart search',
          'Use cases: Drafting emails, summarizing articles, brainstorming ideas',
          'Benefits: Saves hours of tedious work, boosts productivity',
        ],
        shortSampleAnswer:
          'Yes, I use AI apps like ChatGPT and smart writing assistants daily to draft quick emails, summarize long articles, and save time on repetitive work.',
        sampleAnswerBand8: 
          'Yes, absolutely. AI has practically woven itself into the fabric of my daily routine. For instance, I frequently rely on intelligent search engines and natural language assistants to streamline research and automate repetitive clerical tasks. It saves me an enormous amount of time.',
        highBandVocabulary: [
          'Woven itself into the fabric of',
          'Streamline research',
          'Automate repetitive clerical tasks'
        ],
        examinerTips: [
          'Extend your answer by giving a clear, concrete example.',
          'Avoid simple yes/no responses; showcase topical collocations.'
        ],
      ),
      const QuestionModel(
        id: 'q1_2',
        topicId: 'p1_tech',
        questionText: 'Are there any disadvantages to relying heavily on modern gadgets?',
        ideas: [
          'Attention span & patience: Instant dopamine reduces focus',
          'Cognitive reliance: Relying on calculators and spell-check weakens mental math & spelling',
          'Health: Eye strain, sedentary lifestyle, insomnia from blue light',
        ],
        shortSampleAnswer:
          'A major disadvantage is reduced attention span and reliance on automated corrections, which can weaken memory and creative problem-solving skills.',
        sampleAnswerBand8:
          'Undoubtedly, there are noticeable pitfalls. One primary drawback is our diminishing cognitive endurance and attention spans, as people have become accustomed to instantaneous gratification. Furthermore, over-reliance on automated tools can occasionally stifle spontaneous creative thinking.',
        highBandVocabulary: [
          'Noticeable pitfalls',
          'Diminishing cognitive endurance',
          'Instantaneous gratification',
          'Stifle spontaneous creative thinking'
        ],
        examinerTips: [
          'Use contrasting linking words like "Undoubtedly" or "Furthermore".',
          'Discuss broader societal impacts rather than just personal inconvenience.'
        ],
      ),
      const QuestionModel(
        id: 'q1_3',
        topicId: 'p1_tech',
        questionText: 'What technological invention has had the most profound impact on your life?',
        ideas: [
          'Invention: High-speed mobile smartphone / internet',
          'Why: Instant global knowledge, remote work/study anywhere',
          'Connection: Seamless contact with international mentors and family',
        ],
        shortSampleAnswer:
          'High-speed mobile internet has made the biggest difference because it lets me study courses worldwide, connect with anyone, and work on the go.',
        sampleAnswerBand8:
          'Without a doubt, high-speed mobile internet coupled with cloud computing. It allows me to access a global repository of knowledge, collaborate seamlessly with international teams, and manage my studies from virtually any corner of the globe.',
        highBandVocabulary: [
          'Without a doubt',
          'Cloud computing',
          'Global repository of knowledge',
          'Collaborate seamlessly'
        ],
        examinerTips: [
          'Use compound adjectives and precise noun phrases.',
          'Deliver your answer with smooth, unhesitant intonation.'
        ],
      ),
    ],
    'p1_work': [
      const QuestionModel(
        id: 'q2_1',
        topicId: 'p1_work',
        questionText: 'Do you currently work or are you a student?',
        ideas: [
          'Status: Juggling both (part-time software job + student)',
          'Daily routine: Classes in the morning, coding projects in afternoon',
          'Benefits: Applying classroom theories directly into real-world code',
        ],
        shortSampleAnswer:
          'I am currently balancing both: studying computer science at university while working part-time as a junior developer to gain real-world experience.',
        sampleAnswerBand8:
          'At present, I am actively juggling both. I work part-time as a junior developer while concurrently pursuing a degree in computer engineering. Maintaining this equilibrium requires rigorous discipline, but it allows me to directly translate theoretical classroom concepts into practical industry applications.',
        highBandVocabulary: [
          'Actively juggling both',
          'Concurrently pursuing',
          'Maintaining this equilibrium',
          'Theoretical concepts into practical applications'
        ],
        examinerTips: [
          'Be direct in your first sentence, then elaborate with nuance.',
          'Use dynamic adverbs like "concurrently", "rigorously".'
        ],
      ),
      const QuestionModel(
        id: 'q2_2',
        topicId: 'p1_work',
        questionText: 'What aspect of your chosen field do you find most intellectually stimulating?',
        ideas: [
          'Aspect: Algorithmic problem-solving & optimization',
          'Feeling: The thrill of debugging difficult bottlenecks',
          'Impact: Seeing systems run faster and serve thousands of users',
        ],
        shortSampleAnswer:
          'The most stimulating part is solving tricky programming bottlenecks and seeing algorithms run faster and more efficiently.',
        sampleAnswerBand8:
          'I find algorithmic optimization and problem-solving immensely gratifying. There is a genuine sense of accomplishment when you unravel an intricate programming bottleneck and optimize system efficiency.',
        highBandVocabulary: [
          'Intellectually stimulating',
          'Immensely gratifying',
          'Intricate programming bottleneck',
          'System efficiency'
        ],
        examinerTips: [
          'Paraphrase the examiner\'s prompt words rather than repeating "I like".'
        ],
      ),
    ],
    'p1_hometown': [
      const QuestionModel(
        id: 'q3_1',
        topicId: 'p1_hometown',
        questionText: 'Where is your hometown, and what is it known for?',
        ideas: [
          'Location: A vibrant city in the heart of the country',
          'Known for: Rich cultural heritage and historical landmarks',
          'Vibe: Bustling markets, friendly locals, and diverse cuisine',
        ],
        shortSampleAnswer:
          'My hometown is a lively city renowned for its historical architecture and vibrant local markets that attract visitors from surrounding regions.',
        sampleAnswerBand8:
          'I come from a vibrant metropolitan area situated in the heart of the country. It is renowned for its rich cultural heritage, particularly its well-preserved historical architecture and bustling artisan markets. The city has a distinctive charm that seamlessly blends tradition with modern urban development.',
        highBandVocabulary: [
          'Vibrant metropolitan area',
          'Renowned for',
          'Rich cultural heritage',
          'Well-preserved historical architecture',
          'Seamlessly blends',
        ],
        examinerTips: [
          'Use descriptive adjectives to paint a vivid picture.',
          'Mention a specific landmark or dish to make your answer memorable.',
        ],
      ),
      const QuestionModel(
        id: 'q3_2',
        topicId: 'p1_hometown',
        questionText: 'Has your hometown changed much since you were a child?',
        ideas: [
          'Changes: Modern infrastructure, new transport systems, high-rise buildings',
          'Positives: Better connectivity, more job opportunities',
          'Negatives: Loss of green spaces, increased traffic congestion',
        ],
        shortSampleAnswer:
          'Yes, my hometown has undergone significant modernization with new transport networks and commercial developments, though some green spaces have been lost.',
        sampleAnswerBand8:
          'Without a doubt, my hometown has undergone a remarkable transformation. The skyline has been dramatically altered by high-rise developments, and the public transport infrastructure has been substantially upgraded. However, this rapid urbanization has come at a cost — several cherished green spaces have been razed to make way for commercial complexes.',
        highBandVocabulary: [
          'Undergone a remarkable transformation',
          'Dramatically altered',
          'Substantially upgraded',
          'Rapid urbanization',
          'Come at a cost',
        ],
        examinerTips: [
          'Balance positives and negatives to show nuanced thinking.',
          'Use past tense for childhood memories and present perfect for changes.',
        ],
      ),
    ],
    'p1_environment': [
      const QuestionModel(
        id: 'q4_1',
        topicId: 'p1_environment',
        questionText: 'Do you try to be environmentally friendly in your daily life?',
        ideas: [
          'Daily habits: Recycling, reducing plastic use, using reusable bags',
          'Transport: Walking or cycling short distances instead of driving',
          'Energy: Turning off lights and appliances when not in use',
        ],
        shortSampleAnswer:
          'Yes, I make a conscious effort to be eco-friendly by recycling, minimizing plastic consumption, and opting for public transport whenever feasible.',
        sampleAnswerBand8:
          'Absolutely. I make a concerted effort to minimize my ecological footprint on a daily basis. For instance, I religiously segregate recyclable waste, carry reusable shopping bags, and opt for public transit rather than driving. These may seem like modest gestures, but collectively they make a tangible difference.',
        highBandVocabulary: [
          'Concerted effort',
          'Minimize my ecological footprint',
          'Religiously segregate',
          'Modest gestures',
          'Tangible difference',
        ],
        examinerTips: [
          'Use adverbs of frequency (always, rarely) to describe habits.',
          'Connect personal actions to broader environmental impact.',
        ],
      ),
      const QuestionModel(
        id: 'q4_2',
        topicId: 'p1_environment',
        questionText: 'What environmental issues are most concerning in your country?',
        ideas: [
          'Air pollution: Vehicle emissions and industrial smog in urban areas',
          'Water scarcity: Drying rivers and declining groundwater levels',
          'Waste management: Insufficient recycling infrastructure',
        ],
        shortSampleAnswer:
          'The most pressing environmental concern is air pollution from vehicle emissions and industrial activity, particularly in major cities.',
        sampleAnswerBand8:
          'The most pressing environmental predicament in my country is undeniably air pollution. Vehicular emissions coupled with unchecked industrial discharge have led to hazardous smog levels in metropolitan areas. Additionally, water scarcity is becoming increasingly acute, with groundwater reserves depleting at an alarming rate.',
        highBandVocabulary: [
          'Pressing environmental predicament',
          'Vehicular emissions',
          'Unchecked industrial discharge',
          'Hazardous smog levels',
          'Increasingly acute',
        ],
        examinerTips: [
          'Use specific data or examples to substantiate your claims.',
          'Avoid overly emotional language; maintain an objective tone.',
        ],
      ),
    ],
    'p1_culture': [
      const QuestionModel(
        id: 'q5_1',
        topicId: 'p1_culture',
        questionText: 'What kind of music do you enjoy listening to?',
        ideas: [
          'Genre: A mix of classical and contemporary instrumental',
          'When: While studying, commuting, or unwinding after work',
          'Why: Helps concentration and creates a calming atmosphere',
        ],
        shortSampleAnswer:
          'I enjoy a blend of classical and contemporary instrumental music, as it helps me focus while studying and relax after a long day.',
        sampleAnswerBand8:
          'My musical preferences are quite eclectic, though I am particularly drawn to instrumental compositions. I find that classical pieces, with their intricate melodic structures, have an almost therapeutic effect on my mental well-being. Conversely, contemporary instrumental tracks provide an ideal backdrop when I need to concentrate on demanding tasks.',
        highBandVocabulary: [
          'Eclectic',
          'Particularly drawn to',
          'Intricate melodic structures',
          'Therapeutic effect',
          'Mental well-being',
        ],
        examinerTips: [
          'Explain why you enjoy the music, not just what you listen to.',
          'Use sensory adjectives (soothing, upbeat, melancholic).',
        ],
      ),
      const QuestionModel(
        id: 'q5_2',
        topicId: 'p1_culture',
        questionText: 'Do you think traditional arts are still important in modern society?',
        ideas: [
          'Importance: Preserves cultural identity and heritage',
          'Relevance: Offers a counterbalance to digital entertainment',
          'Concern: Younger generations may lose interest',
        ],
        shortSampleAnswer:
          'Yes, traditional arts remain vital as they preserve cultural identity and provide a meaningful counterbalance to our increasingly digital lives.',
        sampleAnswerBand8:
          'I firmly believe that traditional arts are of paramount importance in contemporary society. They serve as an irreplaceable repository of our collective cultural identity, connecting successive generations to their ancestral roots. Furthermore, in an era dominated by ephemeral digital content, traditional craftsmanship offers a grounding, tangible authenticity.',
        highBandVocabulary: [
          'Of paramount importance',
          'Irreplaceable repository',
          'Collective cultural identity',
          'Successive generations',
          'Ephemeral digital content',
        ],
        examinerTips: [
          'Use comparative language (whereas, in contrast) to contrast traditional and modern.',
          'Connect to broader societal trends for a higher band score.',
        ],
      ),
    ],
  };

  static final List<VocabularyModel> _rawVocabulary = [
    const VocabularyModel(
      id: 'v_1',
      phrase: 'Embark upon',
      phonetics: '/ɪmˈbɑːrk əˈpɒn/',
      type: VocabularyType.collocation,
      meaning: 'To start or commence a significant, adventurous, or challenging undertaking.',
      bandTarget: 'Band 8.5+',
      exampleIeltsContext: 'Before embarking upon my university studies, I took a gap year to volunteer.',
      topicTag: 'Education & Career',
    ),
    const VocabularyModel(
      id: 'v_2',
      phrase: 'Of paramount importance',
      phonetics: '/ɒv ˈpær.ə.maʊnt ɪmˈpɔː.təns/',
      type: VocabularyType.academicLexis,
      meaning: 'More important than anything else; supreme in significance.',
      bandTarget: 'Band 9.0',
      exampleIeltsContext: 'Safeguarding natural biospheres is of paramount importance for succeeding generations.',
      topicTag: 'Environment',
    ),
    const VocabularyModel(
      id: 'v_3',
      phrase: 'Having said that',
      phonetics: '/ˈhæv.ɪŋ sed ðæt/',
      type: VocabularyType.discourseMarker,
      meaning: 'Used to introduce an opposing viewpoint or qualification; synonymous with nevertheless.',
      bandTarget: 'Band 8.0+',
      exampleIeltsContext: 'Urban living is bustling and full of career opportunities. Having said that, the stress levels can be quite detrimental.',
      topicTag: 'Discourse Marker',
    ),
    const VocabularyModel(
      id: 'v_4',
      phrase: 'Crystal clear',
      phonetics: '/ˈkrɪs.təl klɪər/',
      type: VocabularyType.idiom,
      meaning: 'Extremely easy to understand; unmistakable in meaning.',
      bandTarget: 'Band 7.5+',
      exampleIeltsContext: 'The professor’s explanation made the intricate economic principles crystal clear.',
      topicTag: 'General & Idioms',
    ),
    const VocabularyModel(
      id: 'v_5',
      phrase: 'Pay dividends',
      phonetics: '/peɪ ˈdɪv.ɪ.dendz/',
      type: VocabularyType.idiom,
      meaning: 'To produce valuable benefits or rewards in the future as a result of effort.',
      bandTarget: 'Band 8.5+',
      exampleIeltsContext: 'Consistent pronunciation practice will ultimately pay dividends on test day.',
      topicTag: 'Success & Hard Work',
    ),
    const VocabularyModel(
      id: 'v_6',
      phrase: 'On the flip side',
      phonetics: '/ɒn ðə flɪp saɪd/',
      type: VocabularyType.discourseMarker,
      meaning: 'Looking at the other side of an argument or situation.',
      bandTarget: 'Band 8.0+',
      exampleIeltsContext: 'Remote working provides unmatched flexibility. On the flip side, it can lead to social isolation.',
      topicTag: 'Discourse Marker',
    ),
  ];
}

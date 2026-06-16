import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cat_data.dart';

class MockResult {
  const MockResult({
    required this.varc,
    required this.dilr,
    required this.qa,
    required this.percentile,
    this.remarks = '',
    this.analysis = '',
    this.nextActions = '',
  });

  final int varc;
  final int dilr;
  final int qa;
  final double percentile;
  final String remarks;
  final String analysis;
  final String nextActions;

  int get total => varc + dilr + qa;

  Map<String, Object> toJson() {
    return {
      'varc': varc,
      'dilr': dilr,
      'qa': qa,
      'percentile': percentile,
      'remarks': remarks,
      'analysis': analysis,
      'nextActions': nextActions,
    };
  }

  static MockResult? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final varc = value['varc'];
    final dilr = value['dilr'];
    final qa = value['qa'];
    final percentile = value['percentile'];
    if (varc is! num || dilr is! num || qa is! num || percentile is! num) {
      return null;
    }
    return MockResult(
      varc: varc.round(),
      dilr: dilr.round(),
      qa: qa.round(),
      percentile: percentile.toDouble(),
      remarks: value['remarks']?.toString() ?? '',
      analysis: value['analysis']?.toString() ?? '',
      nextActions: value['nextActions']?.toString() ?? '',
    );
  }
}

class CustomMock {
  const CustomMock({
    required this.id,
    required this.title,
    required this.date,
    required this.kind,
    required this.focus,
  });

  final String id;
  final String title;
  final DateTime date;
  final String kind;
  final String focus;

  MockSlot toSlot() {
    return MockSlot(id: id, title: title, date: date, focus: focus, kind: kind);
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'kind': kind,
      'focus': focus,
    };
  }

  static CustomMock? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final id = value['id']?.toString();
    final title = value['title']?.toString();
    final rawDate = value['date']?.toString();
    if (id == null || title == null || rawDate == null) {
      return null;
    }
    final date = DateTime.tryParse(rawDate);
    if (date == null) {
      return null;
    }
    return CustomMock(
      id: id,
      title: title,
      date: DateTime(date.year, date.month, date.day),
      kind: value['kind']?.toString() ?? 'Custom mock',
      focus: value['focus']?.toString() ?? 'Custom mock practice.',
    );
  }
}

class PrepStore extends ChangeNotifier {
  PrepStore._(this._preferences);

  static const _completedTopicsKey = 'completedTopics';
  static const _completedSubtopicsKey = 'completedSubtopics';
  static const _topicHoursKey = 'topicHours';
  static const _completedTasksKey = 'completedTasks';
  static const _taskDateKey = 'taskDate';
  static const _mockResultsKey = 'mockResults';
  static const _customMocksKey = 'customMocks';
  static const _customSyllabusKey = 'customSyllabus';
  static const _completedPyqsKey = 'completedPyqs';
  static const _notesKey = 'notes';
  static const _studyDaysKey = 'studyDays';
  static const _studyLogsKey = 'studyLogs';
  static const _darkModeKey = 'darkMode';

  final SharedPreferences _preferences;
  final Set<String> _completedTopicIds = {};
  final Set<String> _completedSubtopicIds = {};
  final Set<String> _completedTaskIds = {};
  final Set<String> _studyDayKeys = {};
  final Map<String, double> _topicHours = {};
  final Map<String, String> _notes = {};
  final Map<String, String> _studyLogs = {};
  final Map<String, MockResult> _mockResults = {};
  final List<CustomMock> _customMocks = [];
  final List<PrepTopic> _customTopics = [];
  final Map<String, List<PrepSubtopic>> _customSubtopics = {};
  final Set<String> _completedPyqIds = {};
  bool _darkMode = false;

  static Future<PrepStore> load() async {
    final preferences = await SharedPreferences.getInstance();
    final store = PrepStore._(preferences);
    store._hydrate();
    return store;
  }

  Set<String> get completedTopicIds => Set.unmodifiable(_completedTopicIds);
  Set<String> get completedSubtopicIds =>
      Set.unmodifiable(_completedSubtopicIds);
  Set<String> get completedTaskIds => Set.unmodifiable(_completedTaskIds);
  Set<String> get studyDayKeys => Set.unmodifiable(_studyDayKeys);
  Map<String, double> get topicHours => Map.unmodifiable(_topicHours);
  Map<String, String> get notes => Map.unmodifiable(_notes);
  Map<String, String> get studyLogs => Map.unmodifiable(_studyLogs);
  Map<String, MockResult> get mockResults => Map.unmodifiable(_mockResults);
  List<CustomMock> get customMocks => List.unmodifiable(_customMocks);
  List<PrepTopic> get customTopics => List.unmodifiable(_customTopics);
  Set<String> get completedPyqIds => Set.unmodifiable(_completedPyqIds);
  bool get darkMode => _darkMode;

  List<PrepTopic> get allTopics => [...catTopics, ..._customTopics];

  List<PrepSubtopic> subtopicsFor(PrepTopic topic) {
    return [...topic.subtopics, ...?_customSubtopics[topic.id]];
  }

  bool isCustomTopic(String topicId) {
    return _customTopics.any((topic) => topic.id == topicId);
  }

  bool isCustomSubtopic(String subtopicId) {
    return _customSubtopics.values.any(
      (subtopics) => subtopics.any((subtopic) => subtopic.id == subtopicId),
    );
  }

  void _hydrate() {
    _completedTopicIds
      ..clear()
      ..addAll(_preferences.getStringList(_completedTopicsKey) ?? const []);

    _completedSubtopicIds
      ..clear()
      ..addAll(_preferences.getStringList(_completedSubtopicsKey) ?? const []);

    final customSyllabus = _decodeCustomSyllabus(
      _preferences.getString(_customSyllabusKey),
    );
    _customTopics
      ..clear()
      ..addAll(customSyllabus.topics);
    _customSubtopics
      ..clear()
      ..addAll(customSyllabus.subtopics);

    _migrateCompletedTopicsToSubtopics();

    _completedTaskIds.clear();
    final storedTaskDate = _preferences.getString(_taskDateKey);
    if (storedTaskDate == dateKey(DateTime.now())) {
      _completedTaskIds.addAll(
        _preferences.getStringList(_completedTasksKey) ?? const [],
      );
    } else {
      _preferences.setString(_taskDateKey, dateKey(DateTime.now()));
      _preferences.setStringList(_completedTasksKey, const []);
    }

    _topicHours
      ..clear()
      ..addAll(_decodeHours(_preferences.getString(_topicHoursKey)));

    _studyDayKeys
      ..clear()
      ..addAll(_preferences.getStringList(_studyDaysKey) ?? const []);

    _notes
      ..clear()
      ..addAll(_decodeStringMap(_preferences.getString(_notesKey)));

    _studyLogs
      ..clear()
      ..addAll(_decodeStringMap(_preferences.getString(_studyLogsKey)));

    _mockResults
      ..clear()
      ..addAll(_decodeMockResults(_preferences.getString(_mockResultsKey)));

    _customMocks
      ..clear()
      ..addAll(_decodeCustomMocks(_preferences.getString(_customMocksKey)));

    _completedPyqIds
      ..clear()
      ..addAll(_preferences.getStringList(_completedPyqsKey) ?? const []);

    _darkMode = _preferences.getBool(_darkModeKey) ?? false;
  }

  Map<String, double> _decodeHours(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }
      return decoded.map((key, value) {
        if (value is num) {
          return MapEntry(key, value.toDouble());
        }
        return MapEntry(key, 0);
      });
    } on FormatException {
      return {};
    }
  }

  Map<String, MockResult> _decodeMockResults(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }
      final results = <String, MockResult>{};
      for (final entry in decoded.entries) {
        final result = MockResult.fromJson(entry.value);
        if (result != null) {
          results[entry.key] = result;
        }
      }
      return results;
    } on FormatException {
      return {};
    }
  }

  List<CustomMock> _decodeCustomMocks(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded.map(CustomMock.fromJson).whereType<CustomMock>().toList();
    } on FormatException {
      return [];
    }
  }

  ({List<PrepTopic> topics, Map<String, List<PrepSubtopic>> subtopics})
  _decodeCustomSyllabus(String? raw) {
    if (raw == null || raw.isEmpty) {
      return (topics: [], subtopics: {});
    }
    try {
      return _customSyllabusFromObject(jsonDecode(raw));
    } on FormatException {
      return (topics: [], subtopics: {});
    }
  }

  ({List<PrepTopic> topics, Map<String, List<PrepSubtopic>> subtopics})
  _customSyllabusFromObject(Object? value) {
    if (value is! Map<String, dynamic>) {
      return (topics: [], subtopics: {});
    }

    final topics = <PrepTopic>[];
    final rawTopics = value['topics'];
    if (rawTopics is List) {
      topics.addAll(rawTopics.map(_prepTopicFromJson).whereType<PrepTopic>());
    }

    final subtopics = <String, List<PrepSubtopic>>{};
    final rawSubtopics = value['subtopics'];
    if (rawSubtopics is Map<String, dynamic>) {
      for (final entry in rawSubtopics.entries) {
        final rawList = entry.value;
        if (rawList is List) {
          final parsed = rawList
              .map(_prepSubtopicFromJson)
              .whereType<PrepSubtopic>()
              .toList();
          if (parsed.isNotEmpty) {
            subtopics[entry.key] = parsed;
          }
        }
      }
    }

    return (topics: topics, subtopics: subtopics);
  }

  PrepTopic? _prepTopicFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final id = value['id']?.toString();
    final title = value['title']?.toString();
    final section = _sectionFromJson(value['section']);
    if (id == null || title == null || section == null) {
      return null;
    }
    final plannedHours = value['plannedHours'];
    return PrepTopic(
      id: id,
      section: section,
      cluster: value['cluster']?.toString() ?? 'Custom',
      title: title,
      detail: value['detail']?.toString() ?? 'Custom topic added by you.',
      difficulty: value['difficulty']?.toString() ?? 'Custom',
      weight: value['weight']?.toString() ?? 'Custom coverage',
      priority: value['priority']?.toString() ?? 'Medium',
      plannedHours: plannedHours is num ? plannedHours.round() : 4,
    );
  }

  PrepSubtopic? _prepSubtopicFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final id = value['id']?.toString();
    final title = value['title']?.toString();
    if (id == null || title == null) {
      return null;
    }
    return PrepSubtopic(
      id,
      title,
      value['about']?.toString() ?? 'Custom subtopic added by you.',
      value['weightage']?.toString() ?? 'Custom coverage',
      value['pastYears']?.toString() ?? 'Added manually',
      value['practiceHint']?.toString() ?? 'Add practice notes as you revise.',
      difficulty: value['difficulty']?.toString() ?? 'Custom',
    );
  }

  CatSection? _sectionFromJson(Object? value) {
    switch (value?.toString()) {
      case 'varc':
      case 'VARC':
        return CatSection.varc;
      case 'dilr':
      case 'DILR':
        return CatSection.dilr;
      case 'qa':
      case 'QA':
        return CatSection.qa;
      default:
        return null;
    }
  }

  Map<String, String> _decodeStringMap(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } on FormatException {
      return {};
    }
  }

  void _migrateCompletedTopicsToSubtopics() {
    var changed = false;
    for (final topic in allTopics) {
      final subtopics = subtopicsFor(topic);
      if (_completedTopicIds.contains(topic.id) && subtopics.isNotEmpty) {
        for (final subtopic in subtopics) {
          changed = _completedSubtopicIds.add(subtopic.id) || changed;
        }
      }
    }
    if (changed) {
      _preferences.setStringList(
        _completedSubtopicsKey,
        _completedSubtopicIds.toList(),
      );
    }
  }

  bool isTopicComplete(PrepTopic topic) {
    final subtopics = subtopicsFor(topic);
    if (subtopics.isEmpty) {
      return _completedTopicIds.contains(topic.id);
    }
    return subtopics.every((subtopic) => isSubtopicComplete(subtopic.id));
  }

  bool isSubtopicComplete(String subtopicId) {
    return _completedSubtopicIds.contains(subtopicId);
  }

  double hoursFor(String topicId) => _topicHours[topicId] ?? 0;

  bool isTaskComplete(String taskId) => _completedTaskIds.contains(taskId);

  bool isStudyDay(DateTime date) => _studyDayKeys.contains(dateKey(date));

  String studyLogFor(DateTime date) => _studyLogs[dateKey(date)] ?? '';

  String noteFor(String noteId) => _notes[noteId] ?? '';

  MockResult? resultFor(String mockId) => _mockResults[mockId];

  List<MockSlot> get allMockSlots {
    return [...mockSlots, ..._customMocks.map((mock) => mock.toSlot())]
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  bool isPyqComplete(String pyqId) => _completedPyqIds.contains(pyqId);

  void setTopicComplete(PrepTopic topic, bool complete) {
    final subtopics = subtopicsFor(topic);
    if (complete) {
      _completedTopicIds.add(topic.id);
      for (final subtopic in subtopics) {
        _completedSubtopicIds.add(subtopic.id);
      }
      _topicHours[topic.id] = hoursFor(
        topic.id,
      ).clamp(topic.plannedHours.toDouble(), topic.plannedHours.toDouble());
    } else {
      _completedTopicIds.remove(topic.id);
      for (final subtopic in subtopics) {
        _completedSubtopicIds.remove(subtopic.id);
      }
    }
    _persistTopics();
    notifyListeners();
  }

  void setSubtopicComplete(
    PrepTopic topic,
    PrepSubtopic subtopic,
    bool complete,
  ) {
    if (complete) {
      _completedSubtopicIds.add(subtopic.id);
    } else {
      _completedSubtopicIds.remove(subtopic.id);
      _completedTopicIds.remove(topic.id);
    }

    final progress = topicCompletion(topic);
    _topicHours[topic.id] = mathSafeHours(topic, progress);
    if (isTopicComplete(topic)) {
      _completedTopicIds.add(topic.id);
    }
    _persistTopics();
    notifyListeners();
  }

  void addTopicHours(PrepTopic topic, double delta) {
    final current = hoursFor(topic.id);
    final next = (current + delta).clamp(0, topic.plannedHours.toDouble());
    _topicHours[topic.id] = next.toDouble();
    _persistTopics();
    notifyListeners();
  }

  void addCustomTopic({
    required CatSection section,
    required String title,
    required String cluster,
    required String detail,
    required int plannedHours,
    required List<String> subtopicTitles,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }
    final createdAt = DateTime.now().microsecondsSinceEpoch;
    final topic = PrepTopic(
      id: 'custom_topic_$createdAt',
      section: section,
      cluster: cluster.trim().isEmpty
          ? 'Custom ${section.shortName}'
          : cluster.trim(),
      title: trimmedTitle,
      detail: detail.trim().isEmpty
          ? 'Custom topic added by you.'
          : detail.trim(),
      difficulty: 'Custom',
      weight: 'Custom coverage',
      priority: 'Medium',
      plannedHours: plannedHours <= 0 ? 4 : plannedHours,
    );
    _customTopics.add(topic);

    final subtopics = _customSubtopicsFromTitles(
      topic.id,
      subtopicTitles,
      createdAt,
    );
    if (subtopics.isNotEmpty) {
      _customSubtopics[topic.id] = subtopics;
    }

    _persistCustomSyllabus();
    notifyListeners();
  }

  void addCustomSubtopics(PrepTopic topic, List<String> titles) {
    final createdAt = DateTime.now().microsecondsSinceEpoch;
    final subtopics = _customSubtopicsFromTitles(topic.id, titles, createdAt);
    if (subtopics.isEmpty) {
      return;
    }
    _customSubtopics.putIfAbsent(topic.id, () => []).addAll(subtopics);
    _completedTopicIds.remove(topic.id);
    _topicHours[topic.id] = mathSafeHours(topic, topicCompletion(topic));
    _persistCustomSyllabus();
    _persistTopics();
    notifyListeners();
  }

  void removeCustomTopic(PrepTopic topic) {
    if (!isCustomTopic(topic.id)) {
      return;
    }
    final subtopics = subtopicsFor(topic);
    _customTopics.removeWhere((customTopic) => customTopic.id == topic.id);
    _customSubtopics.remove(topic.id);
    _completedTopicIds.remove(topic.id);
    _topicHours.remove(topic.id);
    _notes.remove('topic:${topic.id}');
    for (final subtopic in subtopics) {
      _completedSubtopicIds.remove(subtopic.id);
      _notes.remove('subtopic:${subtopic.id}');
    }
    _persistCustomSyllabus();
    _persistTopics();
    _preferences.setString(_notesKey, jsonEncode(_notes));
    notifyListeners();
  }

  void removeCustomSubtopic(PrepTopic topic, PrepSubtopic subtopic) {
    if (!isCustomSubtopic(subtopic.id)) {
      return;
    }
    final subtopics = _customSubtopics[topic.id];
    if (subtopics == null) {
      return;
    }
    subtopics.removeWhere((item) => item.id == subtopic.id);
    if (subtopics.isEmpty) {
      _customSubtopics.remove(topic.id);
    }
    _completedSubtopicIds.remove(subtopic.id);
    _completedTopicIds.remove(topic.id);
    _notes.remove('subtopic:${subtopic.id}');
    _topicHours[topic.id] = mathSafeHours(topic, topicCompletion(topic));
    _persistCustomSyllabus();
    _persistTopics();
    _preferences.setString(_notesKey, jsonEncode(_notes));
    notifyListeners();
  }

  void toggleTask(String taskId, bool complete) {
    if (complete) {
      _completedTaskIds.add(taskId);
    } else {
      _completedTaskIds.remove(taskId);
    }
    _preferences.setString(_taskDateKey, dateKey(DateTime.now()));
    _preferences.setStringList(_completedTasksKey, _completedTaskIds.toList());
    if (complete) {
      _studyDayKeys.add(dateKey(DateTime.now()));
      _persistStudyDays();
    }
    notifyListeners();
  }

  void toggleStudyDay(DateTime date, bool studied) {
    final key = dateKey(date);
    if (studied) {
      _studyDayKeys.add(key);
    } else {
      _studyDayKeys.remove(key);
      _studyLogs.remove(key);
      _persistStudyLogs();
    }
    _persistStudyDays();
    notifyListeners();
  }

  void saveStudyLog(DateTime date, bool studied, String log) {
    final key = dateKey(date);
    final trimmed = log.trim();
    if (studied) {
      _studyDayKeys.add(key);
      if (trimmed.isEmpty) {
        _studyLogs.remove(key);
      } else {
        _studyLogs[key] = trimmed;
      }
    } else {
      _studyDayKeys.remove(key);
      _studyLogs.remove(key);
    }
    _persistStudyDays();
    _persistStudyLogs();
    notifyListeners();
  }

  void saveNote(String noteId, String note) {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      _notes.remove(noteId);
    } else {
      _notes[noteId] = trimmed;
    }
    _preferences.setString(_notesKey, jsonEncode(_notes));
    notifyListeners();
  }

  void setDarkMode(bool enabled) {
    _darkMode = enabled;
    _preferences.setBool(_darkModeKey, enabled);
    notifyListeners();
  }

  void saveMockResult(String mockId, MockResult result) {
    _mockResults[mockId] = result;
    final slot = allMockSlots.where((mock) => mock.id == mockId).firstOrNull;
    if (slot != null) {
      _studyDayKeys.add(dateKey(slot.date));
      _persistStudyDays();
    }
    _persistMocks();
    notifyListeners();
  }

  void clearMockResult(String mockId) {
    _mockResults.remove(mockId);
    _persistMocks();
    notifyListeners();
  }

  void addCustomMock({
    required String title,
    required DateTime date,
    required String kind,
    required String focus,
  }) {
    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    _customMocks.add(
      CustomMock(
        id: id,
        title: title.trim().isEmpty ? 'Custom mock' : title.trim(),
        date: DateTime(date.year, date.month, date.day),
        kind: kind.trim().isEmpty ? 'Custom mock' : kind.trim(),
        focus: focus.trim().isEmpty ? 'Custom mock practice.' : focus.trim(),
      ),
    );
    _persistCustomMocks();
    notifyListeners();
  }

  void removeCustomMock(String mockId) {
    _customMocks.removeWhere((mock) => mock.id == mockId);
    _mockResults.remove(mockId);
    _persistCustomMocks();
    _persistMocks();
    notifyListeners();
  }

  void setPyqComplete(String pyqId, bool complete) {
    if (complete) {
      _completedPyqIds.add(pyqId);
    } else {
      _completedPyqIds.remove(pyqId);
    }
    _persistPyqs();
    notifyListeners();
  }

  void resetProgress() {
    _completedTopicIds.clear();
    _completedSubtopicIds.clear();
    _completedTaskIds.clear();
    _studyDayKeys.clear();
    _topicHours.clear();
    _notes.clear();
    _studyLogs.clear();
    _mockResults.clear();
    _customMocks.clear();
    _completedPyqIds.clear();
    _preferences.remove(_completedTopicsKey);
    _preferences.remove(_completedSubtopicsKey);
    _preferences.remove(_topicHoursKey);
    _preferences.remove(_mockResultsKey);
    _preferences.remove(_customMocksKey);
    _preferences.remove(_completedPyqsKey);
    _preferences.remove(_notesKey);
    _preferences.remove(_studyDaysKey);
    _preferences.remove(_studyLogsKey);
    _preferences.setString(_taskDateKey, dateKey(DateTime.now()));
    _preferences.setStringList(_completedTasksKey, const []);
    notifyListeners();
  }

  double completionFor(Iterable<PrepTopic> topics) {
    final list = topics.toList();
    if (list.isEmpty) {
      return 0;
    }
    final total = totalSubtopicCountFor(list);
    if (total == 0) {
      final completed = list.where(isTopicComplete).length;
      return completed / list.length;
    }
    return completedSubtopicCountFor(list) / total;
  }

  int completedCountFor(Iterable<PrepTopic> topics) {
    return topics.where(isTopicComplete).length;
  }

  int totalSubtopicCountFor(Iterable<PrepTopic> topics) {
    return topics.fold<int>(0, (sum, topic) {
      final subtopics = subtopicsFor(topic);
      return sum + (subtopics.isEmpty ? 1 : subtopics.length);
    });
  }

  int completedSubtopicCountFor(Iterable<PrepTopic> topics) {
    return topics.fold<int>(0, (sum, topic) {
      final subtopics = subtopicsFor(topic);
      if (subtopics.isEmpty) {
        return sum + (isTopicComplete(topic) ? 1 : 0);
      }
      return sum +
          subtopics.where((subtopic) => isSubtopicComplete(subtopic.id)).length;
    });
  }

  int completedSubtopicCount(PrepTopic topic) {
    return subtopicsFor(
      topic,
    ).where((subtopic) => isSubtopicComplete(subtopic.id)).length;
  }

  double topicCompletion(PrepTopic topic) {
    final subtopics = subtopicsFor(topic);
    if (subtopics.isEmpty) {
      return isTopicComplete(topic) ? 1 : 0;
    }
    return completedSubtopicCount(topic) / subtopics.length;
  }

  double get totalHoursLogged {
    return _topicHours.values.fold<double>(0, (sum, value) => sum + value);
  }

  int get completedMockCount => _mockResults.length;

  double? get bestPercentile {
    if (_mockResults.isEmpty) {
      return null;
    }
    return _mockResults.values
        .map((result) => result.percentile)
        .reduce((a, b) => a > b ? a : b);
  }

  double? get averageMockScore {
    if (_mockResults.isEmpty) {
      return null;
    }
    final total = _mockResults.values.fold<int>(
      0,
      (sum, result) => sum + result.total,
    );
    return total / _mockResults.length;
  }

  double? get averageMockPercentile {
    if (_mockResults.isEmpty) {
      return null;
    }
    final total = _mockResults.values.fold<double>(
      0,
      (sum, result) => sum + result.percentile,
    );
    return total / _mockResults.length;
  }

  void _persistTopics() {
    _preferences.setStringList(
      _completedTopicsKey,
      _completedTopicIds.toList(),
    );
    _preferences.setStringList(
      _completedSubtopicsKey,
      _completedSubtopicIds.toList(),
    );
    _preferences.setString(_topicHoursKey, jsonEncode(_topicHours));
  }

  void _persistStudyDays() {
    _preferences.setStringList(_studyDaysKey, _studyDayKeys.toList());
  }

  void _persistStudyLogs() {
    _preferences.setString(_studyLogsKey, jsonEncode(_studyLogs));
  }

  void _persistMocks() {
    _preferences.setString(
      _mockResultsKey,
      jsonEncode(
        _mockResults.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }

  void _persistCustomMocks() {
    _preferences.setString(
      _customMocksKey,
      jsonEncode(_customMocks.map((mock) => mock.toJson()).toList()),
    );
  }

  void _persistCustomSyllabus() {
    _preferences.setString(_customSyllabusKey, jsonEncode(_customSyllabusJson));
  }

  Map<String, Object> get _customSyllabusJson {
    return {
      'topics': _customTopics.map(_topicToJson).toList(),
      'subtopics': _customSubtopics.map((topicId, subtopics) {
        return MapEntry(topicId, subtopics.map(_subtopicToJson).toList());
      }),
    };
  }

  Map<String, Object> _topicToJson(PrepTopic topic) {
    return {
      'id': topic.id,
      'section': topic.section.name,
      'cluster': topic.cluster,
      'title': topic.title,
      'detail': topic.detail,
      'difficulty': topic.difficulty,
      'weight': topic.weight,
      'priority': topic.priority,
      'plannedHours': topic.plannedHours,
    };
  }

  Map<String, Object> _subtopicToJson(PrepSubtopic subtopic) {
    return {
      'id': subtopic.id,
      'title': subtopic.title,
      'about': subtopic.about,
      'weightage': subtopic.weightage,
      'pastYears': subtopic.pastYears,
      'practiceHint': subtopic.practiceHint,
      'difficulty': subtopic.difficulty,
    };
  }

  List<PrepSubtopic> _customSubtopicsFromTitles(
    String topicId,
    List<String> titles,
    int createdAt,
  ) {
    final cleanTitles = titles
        .map((title) => title.trim())
        .where((title) => title.isNotEmpty);
    return [
      for (final entry in cleanTitles.indexed)
        PrepSubtopic(
          'custom_subtopic_${topicId}_${createdAt}_${entry.$1}',
          entry.$2,
          'Custom subtopic added by you.',
          'Custom coverage',
          'Added manually',
          'Add practice notes as you revise.',
          difficulty: 'Custom',
        ),
    ];
  }

  void _persistPyqs() {
    _preferences.setStringList(_completedPyqsKey, _completedPyqIds.toList());
  }

  double mathSafeHours(PrepTopic topic, double progress) {
    return (topic.plannedHours * progress)
        .clamp(0, topic.plannedHours.toDouble())
        .toDouble();
  }

  String exportBackupJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'completedTopics': _completedTopicIds.toList(),
      'completedSubtopics': _completedSubtopicIds.toList(),
      'topicHours': _topicHours,
      'completedTasks': _completedTaskIds.toList(),
      'taskDate': _preferences.getString(_taskDateKey),
      'studyDays': _studyDayKeys.toList(),
      'studyLogs': _studyLogs,
      'notes': _notes,
      'customMocks': _customMocks.map((mock) => mock.toJson()).toList(),
      'customSyllabus': _customSyllabusJson,
      'completedPyqs': _completedPyqIds.toList(),
      'mockResults': _mockResults.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'darkMode': _darkMode,
    });
  }

  bool importBackupJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      _completedTopicIds
        ..clear()
        ..addAll(_stringListFrom(decoded['completedTopics']));
      _completedSubtopicIds
        ..clear()
        ..addAll(_stringListFrom(decoded['completedSubtopics']));
      _completedTaskIds
        ..clear()
        ..addAll(_stringListFrom(decoded['completedTasks']));
      _studyDayKeys
        ..clear()
        ..addAll(_stringListFrom(decoded['studyDays']));

      _topicHours
        ..clear()
        ..addAll(_doubleMapFrom(decoded['topicHours']));
      _studyLogs
        ..clear()
        ..addAll(_stringMapFrom(decoded['studyLogs']));
      _notes
        ..clear()
        ..addAll(_stringMapFrom(decoded['notes']));

      _customMocks
        ..clear()
        ..addAll(_customMocksFrom(decoded['customMocks']));

      final customSyllabus = _customSyllabusFromObject(
        decoded['customSyllabus'],
      );
      _customTopics
        ..clear()
        ..addAll(customSyllabus.topics);
      _customSubtopics
        ..clear()
        ..addAll(customSyllabus.subtopics);

      _migrateCompletedTopicsToSubtopics();

      _completedPyqIds
        ..clear()
        ..addAll(_stringListFrom(decoded['completedPyqs']));

      _mockResults.clear();
      final rawMocks = decoded['mockResults'];
      if (rawMocks is Map<String, dynamic>) {
        for (final entry in rawMocks.entries) {
          final result = MockResult.fromJson(entry.value);
          if (result != null) {
            _mockResults[entry.key] = result;
          }
        }
      }

      final taskDate = decoded['taskDate'];
      if (taskDate is String) {
        _preferences.setString(_taskDateKey, taskDate);
      }
      _darkMode = decoded['darkMode'] == true;

      _persistTopics();
      _preferences.setStringList(
        _completedTasksKey,
        _completedTaskIds.toList(),
      );
      _persistStudyDays();
      _persistStudyLogs();
      _preferences.setString(_notesKey, jsonEncode(_notes));
      _persistCustomMocks();
      _persistCustomSyllabus();
      _persistPyqs();
      _persistMocks();
      _preferences.setBool(_darkModeKey, _darkMode);
      notifyListeners();
      return true;
    } on FormatException {
      return false;
    }
  }

  List<String> _stringListFrom(Object? value) {
    if (value is! List) {
      return [];
    }
    return value.map((item) => item.toString()).toList();
  }

  Map<String, String> _stringMapFrom(Object? value) {
    if (value is! Map<String, dynamic>) {
      return {};
    }
    return value.map((key, item) => MapEntry(key, item.toString()));
  }

  Map<String, double> _doubleMapFrom(Object? value) {
    if (value is! Map<String, dynamic>) {
      return {};
    }
    return value.map((key, item) {
      if (item is num) {
        return MapEntry(key, item.toDouble());
      }
      return MapEntry(key, 0);
    });
  }

  List<CustomMock> _customMocksFrom(Object? value) {
    if (value is! List) {
      return [];
    }
    return value.map(CustomMock.fromJson).whereType<CustomMock>().toList();
  }
}

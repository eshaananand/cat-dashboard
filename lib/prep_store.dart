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
  Set<String> get completedPyqIds => Set.unmodifiable(_completedPyqIds);
  bool get darkMode => _darkMode;

  void _hydrate() {
    _completedTopicIds
      ..clear()
      ..addAll(_preferences.getStringList(_completedTopicsKey) ?? const []);

    _completedSubtopicIds
      ..clear()
      ..addAll(_preferences.getStringList(_completedSubtopicsKey) ?? const []);

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
    for (final topic in catTopics) {
      if (_completedTopicIds.contains(topic.id) && topic.subtopics.isNotEmpty) {
        for (final subtopic in topic.subtopics) {
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
    if (topic.subtopics.isEmpty) {
      return _completedTopicIds.contains(topic.id);
    }
    return topic.subtopics.every((subtopic) => isSubtopicComplete(subtopic.id));
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
    if (complete) {
      _completedTopicIds.add(topic.id);
      for (final subtopic in topic.subtopics) {
        _completedSubtopicIds.add(subtopic.id);
      }
      _topicHours[topic.id] = hoursFor(
        topic.id,
      ).clamp(topic.plannedHours.toDouble(), topic.plannedHours.toDouble());
    } else {
      _completedTopicIds.remove(topic.id);
      for (final subtopic in topic.subtopics) {
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
      return sum + (topic.subtopics.isEmpty ? 1 : topic.subtopics.length);
    });
  }

  int completedSubtopicCountFor(Iterable<PrepTopic> topics) {
    return topics.fold<int>(0, (sum, topic) {
      if (topic.subtopics.isEmpty) {
        return sum + (isTopicComplete(topic) ? 1 : 0);
      }
      return sum +
          topic.subtopics
              .where((subtopic) => isSubtopicComplete(subtopic.id))
              .length;
    });
  }

  int completedSubtopicCount(PrepTopic topic) {
    return topic.subtopics
        .where((subtopic) => isSubtopicComplete(subtopic.id))
        .length;
  }

  double topicCompletion(PrepTopic topic) {
    if (topic.subtopics.isEmpty) {
      return isTopicComplete(topic) ? 1 : 0;
    }
    return completedSubtopicCount(topic) / topic.subtopics.length;
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

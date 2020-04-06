import 'dart:collection';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';

@immutable
class CalendarDataProvider {
  final UnmodifiableListView<Calendar> calendars;

  /// maps the calendar name to the internal calendar id
  final Map<String, String> calendarNameIdMap;

  CalendarDataProvider(this.calendars)
      : assert(calendars != null),
        calendarNameIdMap = calendars
            .where((calendar) => !calendar.isReadOnly)
            .fold(
                {},
                (Map map, Calendar calendar) =>
                    map..putIfAbsent(calendar.name, () => calendar.id));
}

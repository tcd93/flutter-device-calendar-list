import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:tep/calendars/pages/calendar_event.dart';

enum RecurrenceRuleEndType { Indefinite, MaxOccurrences, SpecifiedEndDate }

/// The data model for Events' _Scoped Model_ state management architecture (implemented with `Provider`)
///
/// **operator==** is overloaded to make `CustomEvent` instances comparable by [index], affects [List] operations
/// such as `contains()`
class CustomEvent extends Event {
  /// The index of this event in displaying list
  final int index;

  operator ==(Object other) => this.hashCode == other.hashCode;
  int get hashCode => this.index ?? 0; //null -> hashCode = 0

  String calendarName;

  // `reminders` & `locations` is not in one of constructor field
  // it is not initialized to empty in the parent class
  List<Reminder> get reminders => super.reminders ?? [];

  String get location => super.location ?? '';

  /// The unique id of each event in the entire phone
  String get eventId => super.eventId;

  bool _isRecurringEvent;

  CustomRecurrenceRule _recurrenceRule;
  CustomRecurrenceRule get recurrenceRule => _recurrenceRule;
  set recurrenceRule(RecurrenceRule value) {
    _recurrenceRule = CustomRecurrenceRule(value);
  }

  /// the "Is recurring?" check box in [CalendarEventPage]
  bool get isRecurringEvent => _isRecurringEvent ?? (super.recurrenceRule != null);
  set isRecurringEvent(bool value) {
    _isRecurringEvent = value;
    _recurrenceRule = value ? defaultRecurrenceRule() : null;
  }

  CustomEvent(Event event, {@required this.index, this.calendarName})
      : super(event.calendarId,
            eventId: event.eventId,
            title: event.title,
            start: event.start,
            end: event.end,
            description: event.description,
            attendees: event.attendees ?? [],
            recurrenceRule: event.recurrenceRule,
            allDay: event.allDay ?? false) {
    if (super.recurrenceRule != null)
      _recurrenceRule = CustomRecurrenceRule(super.recurrenceRule);
  }

  static CustomEvent initDefault(
          {String calendarId, String calendarName, int index}) =>
      CustomEvent(
        Event(
          calendarId,
          start: DateTime.now(),
          end: DateTime.now().add(Duration(hours: 1)),
        ),
        calendarName: calendarName,
        index: index,
      );

  static CustomRecurrenceRule defaultRecurrenceRule() =>
      CustomRecurrenceRule(RecurrenceRule(
        RecurrenceFrequency.Daily,
        monthOfYear: MonthOfYear.January,
        // dayOfMonth: 1,
        // daysOfWeek: List<DayOfWeek>(),
        weekOfMonth: WeekNumber.First,
        // endDate: DateTime.now().add(Duration(hours: 1)),
        interval: 1,
      ));
}

class CustomRecurrenceRule extends RecurrenceRule {
  /// For monthly & yearly occurrence, default false
  ///
  /// Ex: 'Repeat monthly by the 23rd day of current month'
  /// = 'Repeat monthly by the [_recurrenceRule.dayOfMonth] day of current month'
  bool isByDayOfMonth;

  /// For monthly & yearly occurrence, [_isByDayOfMonth] set to false;
  ///
  /// Ex: 'Repeat Monthly on the second Saturday' = 'Repeat Monthly on the [_recurrenceRule.weekOfMonth]
  /// [_selectedDayOfWeek]'
  ///
  /// _Note: For weekly occurrence, use the array [_recurrenceRule.daysOfWeek] instead_
  DayOfWeek selectedDayOfWeek;

  /// Current selected type of [RecurrenceRuleEndType]
  RecurrenceRuleEndType recurrenceRuleEndType;

  CustomRecurrenceRule(RecurrenceRule rr)
      : super(rr.recurrenceFrequency,
            daysOfWeek: rr.daysOfWeek,
            dayOfMonth: rr.dayOfMonth,
            monthOfYear: rr.monthOfYear,
            weekOfMonth: rr.weekOfMonth,
            endDate: rr.endDate,
            interval: rr.interval) {
    //init default values
    isByDayOfMonth = dayOfMonth == null ? false : true;

    selectedDayOfWeek = daysOfWeek?.first ?? DayOfWeek.Monday;

    recurrenceRuleEndType = totalOccurrences != null
        ? RecurrenceRuleEndType.MaxOccurrences
        : endDate != null
            ? RecurrenceRuleEndType.SpecifiedEndDate
            : RecurrenceRuleEndType.Indefinite;
  }
}

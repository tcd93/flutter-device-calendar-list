import 'dart:async';
import 'dart:collection';

import '../common/helpers.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tep/calendars/custom_event.dart';

/// A custom mixin to listen to CalendarEventPage form submit event
mixin CalendarEventNotifier {
  /// A map of <eventId, callback>
  Map<String, VoidCallback> _listeners = Map<String, VoidCallback>();

  void addEventListener(String eventId, VoidCallback callback) {
    _listeners.putIfAbsent(eventId, () => callback);
  }

  void notifyEventListeners(Set<String> eventIds) {
    var matchedKeys = _listeners.keys.where((id) => eventIds.contains(id));
    print('>>>>> Notifying ${matchedKeys.length} listeners');
    for(var key in matchedKeys) {
      _listeners[key]();
    }
  }
}

/// Provider for event(s) data, used for pages under /calendar
class EventDataProvider with ChangeNotifier, CalendarEventNotifier {
  final UnmodifiableListView<Calendar> _calendars;
  final Map<String, String> _calendarNameIdMap;

  List<CustomEvent> events;
  CustomEvent currentEvent;

  EventDataProvider(this._calendars, this._calendarNameIdMap,
      {@required DateTime start, @required DateTime end}) {
    assert(_calendars != null);
    _retrieveCalendarEvents(_calendars, start, end)
        .then((events) => setState((_) => this.events = events));
  }

  @override
  void dispose() {
    events = null;
    super.dispose();
  }

  /// Remove the [event] from [events] list.
  ///
  /// Set [persist] false for mock test
  Future<bool> deleteEvent(CustomEvent event, [bool persist = true]) async {
    if (!persist) {
      events.remove(event);
      return true;
    } else {
      var result = await DeviceCalendarPlugin()
          .deleteEvent(_calendarNameIdMap[event.calendarName], event.eventId);
      if (result.isSuccess && result.data) {
        events.remove(event);
        return true;
      }
    }
    return false;
  }

  ///add new (non-dupplicated) event to the [events] list
  void addEvent(CustomEvent event) {
    //find the closest event (compared by start date) in the event list
    final dateTime = event.start;
    final int index =
        (events.indexWhere((c) => c.start.compareTo(dateTime) <= 0) < 0)
            ? events.length
            : events.indexWhere((c) => c.start.compareTo(dateTime) <= 0);
    events.insert(index, event);
  }

  /// Update UI
  void setState(Function(CustomEvent) fn) {
    assert(fn != null);
    fn(currentEvent);
    notifyListeners();
  }

  /// Retrieve events from a list of [Calendar]
  Future<List<CustomEvent>> _retrieveCalendarEvents(
      UnmodifiableListView<Calendar> calendars,
      DateTime startDate,
      DateTime endDate) async {
    try {
      //map Events in each calendar into a list of CustomEvents
      var futures = calendars.map((Calendar calendar) async {
        final eventList = await DeviceCalendarPlugin().retrieveEvents(
            calendar.id,
            RetrieveEventsParams(startDate: startDate, endDate: endDate));

        var iterable = Helper.enumerate<CustomEvent>(eventList.data, 
          (index, event) => CustomEvent(event, index: index, calendarName: calendar.name));
        return iterable;
      });
      // await for completions then flatten the list
      return (await Future.wait(futures)).expand((l) => l).toList()
        ..sort((event1, event2) =>
            event2.start.compareTo(event1.start)); // sort by date descending
    } on PlatformException catch (e) {
      print('-------------ERROR-------------');
      print(e);
      print('-------------ERROR-------------');
      return [];
    }
  }
}

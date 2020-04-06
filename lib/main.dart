import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tep/calendars/pages/calendar_events.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:tep/providers/calendars_provider.dart';
import 'package:tep/calendars/events_provider.dart';
import 'calendars/pages/calendar_event.dart';
import 'calendars/pages/event_attendee.dart';
import 'calendars/pages/event_reminders.dart';
import 'common/app_routes.dart';

void main() => runApp(RootWidget());

class RootWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final future = _hasPermission().then(_retrieveCalendars);

    return FutureBuilder<UnmodifiableListView<Calendar>>(
      future: future,
      builder: (context, snapshot) =>
          snapshot.connectionState == ConnectionState.waiting
              ? Center(child: CircularProgressIndicator())
              : snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData &&
                      snapshot.data.length > 0
                  ? Provider<CalendarDataProvider>(
                      create: (context) => CalendarDataProvider(snapshot.data), // Root provider
                      lazy: true,
                      child: Consumer<CalendarDataProvider>(
                        builder: (_, provider, widget) => MultiProvider(
                          providers: [
                            // <<< ---- NOTE ---- >>>
                            // Add each feature branch's top providers here
                            // <<< ---- NOTE ---- >>>
                            ChangeNotifierProvider<EventDataProvider>(
                              create: (context) => EventDataProvider(
                                provider.calendars,
                                provider.calendarNameIdMap,
                                //TODO: input by week instead
                                start: DateTime.now().add(Duration(days: -7)),
                                end: DateTime.now().add(Duration(days: 7)),
                              ),
                              child: widget,
                            ),
                          ],
                          // <<< ---- NOTE ---- >>>
                          // Define app routes here
                          // <<< ---- NOTE ---- >>>
                          child: MaterialApp(
                            routes: {
                              AppRoutes.calendarEvents: (context) =>
                                  CalendarEventsPage(),
                            },
                            // ignore: missing_return
                            onGenerateRoute: (settings) {
                              var args = settings.arguments as Map;
                              if (args == null) args = {};

                              switch (settings.name) {
                                case AppRoutes.calendarEvent:
                                  {
                                    return MaterialPageRoute(
                                      builder: (context) =>
                                          CalendarEventPage(args['event']),
                                    );
                                  }
                                  break;
                                case AppRoutes.eventAttendee:
                                  {
                                    return MaterialPageRoute(
                                      builder: (context) => EventAttendeePage(
                                          key: args['key'],
                                          attendee: args['attendee']),
                                    );
                                  }
                                  break;
                                case AppRoutes.eventReminder:
                                  {
                                    return MaterialPageRoute(
                                      builder: (context) => EventRemindersPage(
                                          args['reminders'],
                                          key: args['key']),
                                    );
                                  }
                                  break;
                                default:
                                  {
                                    throw 'route ${settings.name} is not implemented in AppRoutes';
                                  }
                                  break;
                              }
                            },
                          ),
                        ),
                      ),
                    )
                  : Center(child: Text('No data found', textDirection: TextDirection.ltr)),
    );
  }

  Future<void> _hasPermission() async {
    var permissionsGranted = await DeviceCalendarPlugin().hasPermissions();

    if (permissionsGranted.isSuccess && permissionsGranted.data) {
      return;
    }
    else if (permissionsGranted.isSuccess && !permissionsGranted.data) {
      permissionsGranted = await DeviceCalendarPlugin().requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data) {
        throw 'User has not granted app calendar access permission';
      }
    } else
      throw 'App does not have calendar access permission';
  }

  Future<UnmodifiableListView<Calendar>> _retrieveCalendars(_) async {
    return (await DeviceCalendarPlugin().retrieveCalendars()).data;
  }
}

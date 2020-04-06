import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tep/common/app_routes.dart';
import 'package:tep/providers/calendars_provider.dart';
import 'package:tep/calendars/events_provider.dart';

import '../custom_event.dart';
import 'components/event_item.dart';

/// Display a list of weekly events.
///
/// [CalendarEventsPage] is made as Stateful widget is to prevent unnecessary rebuilds
/// of the entire ListView after going into [CalendarEventPage] (even if nothing is changed).
class CalendarEventsPage extends StatefulWidget {
  @override
  _CalendarEventsState createState() => _CalendarEventsState();
}

class _CalendarEventsState extends State<CalendarEventsPage> {
  /// This scroll controller creates a front/back layer fade in/out effect for a long list (blame google for that)
  final ItemScrollController scrollController = ItemScrollController();

  CalendarDataProvider calendarProvider;
  EventDataProvider eventProvider;

  @override
  void initState() {
    calendarProvider =
        Provider.of<CalendarDataProvider>(context, listen: false);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    eventProvider = Provider.of<EventDataProvider>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // print('>>>> Building Events List Page, length: ${eventProvider.events?.length}');

    return Scaffold(
      appBar: AppBar(title: Text('Calendar Events')),
      body: Builder(
        builder: (context) => eventProvider.events == null
            ? const Center(child: CircularProgressIndicator())
            : eventProvider.events.length == 0
                ? const Center(child: Text('No data'))
                : _buildPositionedList(),
      ),
      floatingActionButton: _FloatingButtons(
          onQuickScrollPress: () => _focusEventOn(DateTime.now()),
        ),
    );
  }

  /// Build a [ScrollablePositionedList] of event items
  ScrollablePositionedList _buildPositionedList() =>
      ScrollablePositionedList.builder(
          itemCount: eventProvider.events.length,
          itemBuilder: (BuildContext context, int index) => EventItem(
                calendarEvent: eventProvider.events[index],
                key: ObjectKey(eventProvider.events[index]),
                onDelete: (CustomEvent event, bool isConfirmed) async {
                  if (isConfirmed) {
                    var result = await eventProvider.deleteEvent(
                        event, true /*set 2nd param false for mock testing*/);
                    if (result) {
                      eventProvider.setState((_) {});
                    } else {
                      Scaffold.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Oops, we ran into an issue deleting the event'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ));
                    }
                  }
                },
                onTapped: (CustomEvent event) {
                  Navigator.pushNamed(context, AppRoutes.calendarEvent,
                      arguments: {
                        'event': event,
                      });
                },
              ),
          itemScrollController: scrollController);

  /// Find the event closest the provided date then scroll to that position
  void _focusEventOn(DateTime dateTime) {
    if (eventProvider.events == null || eventProvider.events.length == 0)
      return;
    final int _startIndex = (eventProvider.events
                .indexWhere((c) => c.start.compareTo(dateTime) <= 0) <
            0)
        ? eventProvider.events.length
        : eventProvider.events
                .indexWhere((c) => c.start.compareTo(dateTime) <= 0) -
            1;

    scrollController.scrollTo(
        index: _startIndex,
        duration: Duration(seconds: (_startIndex / 6).ceil()),
        curve: Curves.fastLinearToSlowEaseIn);
  }
}

/// Build `addEvent` floating button to add new calendar event
/// & `quickScroll` floating button to quickly scroll to the nearest-to-current-date event
class _FloatingButtons extends StatelessWidget {
  final VoidCallback onQuickScrollPress;

  const _FloatingButtons({this.onQuickScrollPress});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarDataProvider>(context, listen: false);

    return Column(
      verticalDirection: VerticalDirection.up,
      children: <Widget>[
        FloatingActionButton(
          key: Key('addEventButton'),
          heroTag: null,
          onPressed: () {
            final eventProvider = Provider.of<EventDataProvider>(context, listen: false);
            print('>>>> Creating new event with index ${eventProvider.events.length}');
            Navigator.pushNamed(context, AppRoutes.calendarEvent,
                arguments: {
                  'event': CustomEvent.initDefault(
                      calendarId: provider.calendarNameIdMap.values.first,
                      calendarName: provider.calendarNameIdMap.keys.first,
                      index: eventProvider.events.length,
                    )
                });
          },
          child: Icon(Icons.add),
          tooltip: 'Add new event',
          backgroundColor: Colors.blue[700],
        ),
        const SizedBox(height: 4.0),
        Container(
          width: 50.0,
          height: 50.0,
          child: FloatingActionButton(
            key: Key('findNearestEventButton'),
            heroTag: null,
            onPressed: () =>
                onQuickScrollPress != null ? onQuickScrollPress() : null,
            child: const Icon(Icons.arrow_forward),
            tooltip: 'Scroll to nearst event',
            backgroundColor: const Color.fromRGBO(20, 120, 200, 120),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tep/common/app_routes.dart';
import 'package:tep/providers/calendars_provider.dart';
import 'package:tep/calendars/events_provider.dart';

import '../custom_event.dart';
import 'components/event_item.dart';

/// Display a list of weekly events.
class CalendarEventsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('>>>> Building outer scaffold <<<<');
    return Scaffold(
      appBar: AppBar(title: Text('Calendar Events')),
      body: Builder(
        builder: (context) => _PositionedList(),
      ),
      floatingActionButton: _FloatingButtons(
        onQuickScrollPress: () {
          _focusEventOn(DateTime.now(), context);
        },
      ),
    );
  }

  /// Find the event closest the provided date then scroll to that position
  void _focusEventOn(DateTime dateTime, BuildContext context) {
    final eventProvider = Provider.of<EventDataProvider>(context, listen: false);

    if (eventProvider.events == null || eventProvider.events.length == 0)
      return;
    final int _startIndex = (eventProvider.events
                .indexWhere((c) => c.start.compareTo(dateTime) <= 0) <
            0)
        ? eventProvider.events.length
        : eventProvider.events
                .indexWhere((c) => c.start.compareTo(dateTime) <= 0) -
            1;

    eventProvider.scrollController.scrollTo(
        index: _startIndex,
        duration: Duration(seconds: (_startIndex / 6).ceil()),
        curve: Curves.fastLinearToSlowEaseIn);
  }
}

/// Build a [ScrollablePositionedList] of event items
class _PositionedList extends StatelessWidget {
  const _PositionedList();

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventDataProvider>(context);

    if (eventProvider.events == null)
      return Center(child: CircularProgressIndicator());
    if (eventProvider.events?.length ==0)
      return Center(child: Text('No data'));
    else {
      print('>>>>>>>>>>>>> Building positioned list <<<<<<<<<<<<<');
      print('');

      final scrollController = eventProvider.scrollController;

      return ScrollablePositionedList.builder(
        itemCount: eventProvider.events.length,
        itemBuilder: (BuildContext context, int index) => EventItem(
              event: eventProvider.events[index],
              key: ObjectKey(eventProvider.events[index]),
              onDelete: (CustomEvent event, bool isConfirmed) async {
                if (isConfirmed) {
                  var error = await eventProvider.deleteEvent(event);
                  if (error.isEmpty) {
                    eventProvider.setState((_) {});
                  } else {
                    // TODO: make a global helper function
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ));
                  }
                }
              },
              onTapped: (CustomEvent event) {
                final eventProvider = Provider.of<EventDataProvider>(context, listen: false);
                // provide a deep copy instead of reference to prevent direct modifications
                eventProvider.currentEvent = CustomEvent.clone(event);
                Navigator.pushNamed(context, AppRoutes.calendarEvent);
              },
            ),
        itemScrollController: scrollController);
    }
  }
}

/// Build `addEvent` floating button to add new calendar event
/// & `quickScroll` floating button to quickly scroll to the nearest-to-current-date event
class _FloatingButtons extends StatelessWidget {
  final VoidCallback onQuickScrollPress;

  const _FloatingButtons({this.onQuickScrollPress});

  @override
  Widget build(BuildContext context) {
    return Column(
      verticalDirection: VerticalDirection.up,
      children: <Widget>[
        FloatingActionButton(
          key: Key('addEventButton'),
          heroTag: null,
          onPressed: () { 
            final provider = Provider.of<CalendarDataProvider>(context, listen: false);
            final eventProvider = Provider.of<EventDataProvider>(context, listen: false);
            print('>>>> Creating new event with index ${eventProvider.events.length}');
            eventProvider.currentEvent = CustomEvent.initDefault(
                calendarId: provider.calendarNameIdMap.values.first,
                calendarName: provider.calendarNameIdMap.keys.first,
                index: eventProvider.events.length,
              );
            Navigator.pushNamed(context, AppRoutes.calendarEvent);
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

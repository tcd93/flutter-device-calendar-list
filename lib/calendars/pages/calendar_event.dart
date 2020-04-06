import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tep/common/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tep/providers/calendars_provider.dart';
import 'package:tep/calendars/events_provider.dart';

import 'components/date_time_picker.dart';
import '../custom_event.dart';
import 'components/recurring_event.dart';

/// Display page to add new/edit event
class CalendarEventPage extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final deviceCalendarPlugin = DeviceCalendarPlugin();

  final CustomEvent event;
  final bool autoValidate = false;

  CalendarEventPage(this.event);

  @override
  Widget build(BuildContext context) {
    // print('>>>>>>>> Building New/Edit Event Page');
    final scrollController = ScrollController();

    final calendarNameIdMap =
        Provider.of<CalendarDataProvider>(context, listen: false)
            .calendarNameIdMap;

    final eventProvider = Provider.of<EventDataProvider>(context);
    eventProvider.currentEvent = event;

    final setState = eventProvider.setState;
    final addEvent = eventProvider.addEvent;
    final deleteEvent = eventProvider.deleteEvent;

    var scaffoldContext;

    return GestureDetector(
      onTap: () {
        // remove focus (keyboard popups...) when tapping on other areas
        if (!FocusScope.of(context).hasPrimaryFocus)
          FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(event.eventId?.isEmpty ?? true
              ? 'Create event'
              : 'Edit event ${event.title}'),
        ),
        body: Builder(
          builder: (context) {
            scaffoldContext = context;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              controller: scrollController,
              child: Column(
                children: [
                  Form(
                    autovalidate: autoValidate,
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: DropdownButton<String>(
                            value: event.calendarName,
                            isExpanded: true,
                            icon: Icon(Icons.calendar_today),
                            iconEnabledColor: Colors.blue,
                            elevation: 9,
                            underline:
                                Container(height: 2, color: Colors.black54),
                            onChanged: (String newName) => setState((_) {
                              event.calendarName = newName;
                              event.calendarId = calendarNameIdMap[newName];
                            }),
                            items: calendarNameIdMap.keys
                                .map((String calendarName) =>
                                    DropdownMenuItem<String>(
                                      key: ValueKey(calendarName),
                                      value: calendarName,
                                      child: Text(calendarName,
                                          textAlign: TextAlign.left),
                                    ))
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            initialValue: event.title,
                            autofocus: false,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                            decoration: const InputDecoration(
                                labelText: 'Title',
                                hintText: 'Meeting with Gloria...'),
                            validator: (String value) =>
                                value.isEmpty ? 'Name is required.' : null,
                            onChanged: (String value) => event.title = value,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            initialValue: event.description,
                            autofocus: false,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                            decoration: const InputDecoration(
                                labelText: 'Description',
                                hintText: 'Remember to buy flowers...'),
                            onChanged: (String value) =>
                                event.description = value,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            initialValue: event.location,
                            autofocus: false,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                            decoration: const InputDecoration(
                                labelText: 'Location',
                                hintText: 'Sydney, Australia'),
                            onChanged: (String value) => event.location = value,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            initialValue: event.url?.data?.contentText ?? '',
                            autofocus: false,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                            decoration: const InputDecoration(
                                labelText: 'URL',
                                hintText: 'https://google.com'),
                            onChanged: (String value) =>
                                event.url = Uri.dataFromString(value),
                          ),
                        ),
                        SwitchListTile(
                          value: event.allDay,
                          onChanged: (value) =>
                              setState((_) => event.allDay = value),
                          title: Text('All Day'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: DateTimePicker(
                            labelText: 'From',
                            enableTime: !event.allDay,
                            selectedDate: event.start,
                            selectedTime: TimeOfDay(
                                hour: event.start.hour,
                                minute: event.start.minute),
                            selectDate: (DateTime date) => setState((_) =>
                                event.start = _combineDateWithTime(
                                    date,
                                    TimeOfDay(
                                        hour: event.start.hour,
                                        minute: event.start.minute))),
                            selectTime: (TimeOfDay time) => setState(
                              (_) => event.start =
                                  _combineDateWithTime(event.start, time),
                            ),
                          ),
                        ),
                        if (!event.allDay)
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: DateTimePicker(
                              labelText: 'To',
                              selectedDate: event.end,
                              selectedTime: TimeOfDay(
                                  hour: event.end.hour,
                                  minute: event.end.minute),
                              selectDate: (DateTime date) => setState(
                                (_) => event.end = _combineDateWithTime(
                                    date,
                                    TimeOfDay(
                                        hour: event.end.hour,
                                        minute: event.end.minute)),
                              ),
                              selectTime: (TimeOfDay time) => setState(
                                (_) => event.end =
                                    _combineDateWithTime(event.end, time),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.pushNamed(
                                context, AppRoutes.eventAttendee);
                            if (result != null) event.attendees.add(result);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10.0,
                                children: [
                                  Icon(Icons.people),
                                  Text('Add Attendees')
                                ],
                              ),
                            ),
                          ),
                        ),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount:
                              event.attendees.length, // _attendees.length,
                          itemBuilder: (context, index) {
                            return Container(
                                color: event.attendees[index]
                                        .isOrganiser //_attendees[index].isOrganiser
                                    ? Colors.greenAccent[100]
                                    : Colors.transparent,
                                child: ListTile(
                                    title: GestureDetector(
                                        child: Text(
                                            '${event.attendees[index].emailAddress}'),
                                        onTap: () async {
                                          final result =
                                              await Navigator.pushNamed(context,
                                                  AppRoutes.eventAttendee,
                                                  arguments: {
                                                'attendee': event.attendees[index],
                                              });
                                          if (result != null)
                                            event.attendees[index] = result;
                                        }),
                                    trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Container(
                                            margin: const EdgeInsets.all(10.0),
                                            padding: const EdgeInsets.all(3.0),
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.blueAccent)),
                                            child: Text(
                                                '${event.attendees[index].role.enumToString}'),
                                          ),
                                          IconButton(
                                            padding: const EdgeInsets.all(0),
                                            onPressed: () => setState((_) =>
                                                event.attendees.removeAt(index)),
                                            icon: Icon(
                                              Icons.remove_circle,
                                              color: Colors.redAccent,
                                            ),
                                          )
                                        ])));
                          },
                        ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.pushNamed(
                                context, AppRoutes.eventReminder,
                                arguments: {'reminders': event.reminders});
                            if (result != null) event.reminders = result;
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10.0,
                                children: [
                                  Icon(Icons.alarm),
                                  if (event.reminders.isEmpty)
                                    Text('Add reminders'),
                                  ...event.reminders.map((reminder) => Text(
                                      '${reminder.minutes} minutes before; ')),
                                ],
                              ),
                            ),
                          ),
                        ),
                        CheckboxListTile(
                          value: event.isRecurringEvent,
                          title: Text('Is recurring'),
                          onChanged: (isChecked) => setState((_) {
                            event.isRecurringEvent = isChecked;
                          }),
                        ),
                        if (event.isRecurringEvent)
                          RecurringEvent(
                            event,
                            // scroll to page end when subview is created
                            onEnd: (_) => scrollController.animateTo(
                                scrollController.position.maxScrollExtent,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut),
                          ),
                      ],
                    ),
                  ),
                  if (event.eventId?.isNotEmpty ?? false)
                    RaisedButton(
                      key: Key('deleteEventButton'),
                      textColor: Colors.white,
                      color: Colors.red,
                      child: Text('Delete'),
                      onPressed: () async {
                        var result = await deviceCalendarPlugin.deleteEvent(
                            calendarNameIdMap[event.calendarName],
                            event.eventId);
                        if (result.isSuccess && result.data) deleteEvent(event);
                        Navigator.pop(context, result.isSuccess && result.data);
                      },
                    ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          key: Key('saveEventButton'),
          onPressed: () async {
            final FormState form = _formKey.currentState;
            if (!form.validate()) {
              // autoValidate = true;
              showInSnackBar(
                  'Please fix the errors in red before submitting.', scaffoldContext);
            } else {
              form.save();
              eventProvider.notifyEventListeners(Set<String>.from([event.eventId]));

              if (!eventProvider.events.contains(event)) addEvent(event);

              var createOrEditEventResult =
                await deviceCalendarPlugin.createOrUpdateEvent(event);
              if (createOrEditEventResult.isSuccess) {
                Navigator.pop(context, true);
              } else {
                showInSnackBar(createOrEditEventResult.errorMessages.join(' | '), scaffoldContext);
              }
            }
          },
          child: Icon(Icons.check),
        ),
      ),
    );
  }

  DateTime _combineDateWithTime(DateTime date, TimeOfDay time) {
    if (date == null && time == null) {
      return null;
    }
    final dateWithoutTime =
        DateTime.parse(DateFormat("y-MM-dd 00:00:00").format(date));
    return dateWithoutTime
        .add(Duration(hours: time.hour, minutes: time.minute));
  }

  void showInSnackBar(String value, BuildContext scaffoldContext) {
    Scaffold.of(scaffoldContext).showSnackBar(SnackBar(content: Text(value)));
  }
}

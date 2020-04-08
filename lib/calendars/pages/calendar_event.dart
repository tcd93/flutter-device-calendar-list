import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tep/calendars/custom_event.dart';
import 'package:tep/common/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tep/providers/calendars_provider.dart';
import 'package:tep/calendars/events_provider.dart';

import 'components/date_time_picker.dart';
import 'components/recurring_event.dart';

/// Display page to add new/edit event
class CalendarEventPage extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final bool autoValidate = false;

  @override
  Widget build(BuildContext context) {
    print('###### Building New/Edit Event Page ######');
    print('');
    var scaffoldContext;

    return GestureDetector(
      onTap: () {
        // remove focus (keyboard popups...) when tapping on other areas
        if (!FocusScope.of(context).hasPrimaryFocus)
          FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const _AppBarTitle(),
        ),
        body: Builder(
          builder: (context) {
            scaffoldContext = context;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              primary: true,
              child: Column(
                children: [
                  Form(
                    autovalidate: autoValidate,
                    key: _formKey,
                    child: Column(
                      children: [
                        const _CalendarSelector(),
                        const _TitleInput(),
                        const _DescriptionInput(),
                        const _LocationInput(),
                        const _UrlInput(),
                        const _AllDaySwitch(),
                        const _FromDateSelector(),
                        /* if (!event.allDay) */ const _ToDateSelector(),
                        const _Attendees(),
                        const _Reminders(),
                        const _RecurrenceCheckbox(),
                        /* if (event.recurrenceRule != null) */
                        const RecurringEvent(),
                      ],
                    ),
                  ),
                  /* if (event.eventId?.isNotEmpty ?? false) */
                  const _DeleteEventButton(),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          key: Key('saveEventButton'),
          onPressed: () async {
            final FormState form = _formKey.currentState;
            final eventProvider = Provider.of<EventDataProvider>(context, listen: false);
            final event = eventProvider.currentEvent;

            if (!form.validate()) {
              // autoValidate = true;
              _showInSnackBar('Please fix the errors in red before submitting.',
                  scaffoldContext);
            } else {
              form.save();
              eventProvider.notifyEventListeners(Set<String>.from([event.eventId]));

              String error;
              if (!eventProvider.events.contains(event)) {
                error = await eventProvider.addEvent(event);
              } else {
                error = await eventProvider.updateEvent(event);
              }
              if (error.isEmpty) {
                Navigator.pop(context, true);
              } else {
                _showInSnackBar(error, scaffoldContext);
              }
            }
          },
          child: const Icon(Icons.check),
        ),
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    final event = Provider.of<EventDataProvider>(context, listen: false).currentEvent;
    return Text(event.eventId?.isEmpty ?? true
              ? 'Create event'
              : 'Edit event ${event.title}');
  }
}

class _DeleteEventButton extends StatelessWidget {
  const _DeleteEventButton();

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventDataProvider>(context);
    final event = eventProvider.currentEvent;

    if (event.eventId?.isNotEmpty ?? false) {
      return RaisedButton(
        key: Key('deleteEventButton'),
        textColor: Colors.white,
        color: Colors.red,
        child: Text('Delete'),
        onPressed: () async {
          String error = await eventProvider.deleteEvent(event);
          if (error.isEmpty) {
            Navigator.pop(context, true);
            eventProvider.setState((_) {});
          } else {
            _showInSnackBar(error, context);
          }
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _RecurrenceCheckbox extends StatelessWidget {
  const _RecurrenceCheckbox();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventDataProvider>(context);
    final currentEvent = provider.currentEvent;
    final setState = provider.setState;
    return CheckboxListTile(
      value: currentEvent.recurrenceRule != null,
      title: Text('Is recurring'),
      onChanged: (isChecked) => setState((_) => currentEvent.recurrenceRule =
          isChecked ? CustomEvent.defaultRecurrenceRule() : null),
    );
  }
}

class _Reminders extends StatelessWidget {
  const _Reminders();

  @override
  Widget build(BuildContext context) {
    final event = Provider.of<EventDataProvider>(context).currentEvent;

    return GestureDetector(
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
              if (event.reminders.isEmpty) Text('Add reminders'),
              ...event.reminders.map(
                  (reminder) => Text('${reminder.minutes} minutes before; ')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Attendees extends StatelessWidget {
  const _Attendees();

  @override
  Widget build(BuildContext context) {
    final event = Provider.of<EventDataProvider>(context).currentEvent;
    final setState = Provider.of<EventDataProvider>(context).setState;

    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () async {
            final result =
                await Navigator.pushNamed(context, AppRoutes.eventAttendee);
            if (result != null) event.attendees.add(result);
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10.0,
                children: [Icon(Icons.people), Text('Add Attendees')],
              ),
            ),
          ),
        ),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: event.attendees.length,
          itemBuilder: (context, index) {
            return Container(
                color: event.attendees[index].isOrganiser
                    ? Colors.greenAccent[100]
                    : Colors.transparent,
                child: ListTile(
                    title: GestureDetector(
                        child: Text('${event.attendees[index].emailAddress}'),
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                              context, AppRoutes.eventAttendee,
                              arguments: {
                                'attendee': event.attendees[index],
                              });
                          if (result != null) event.attendees[index] = result;
                        }),
                    trailing:
                        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(10.0),
                        padding: const EdgeInsets.all(3.0),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueAccent)),
                        child:
                            Text('${event.attendees[index].role.enumToString}'),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(0),
                        onPressed: () =>
                            setState((_) => event.attendees.removeAt(index)),
                        icon: Icon(
                          Icons.remove_circle,
                          color: Colors.redAccent,
                        ),
                      )
                    ])));
          },
        ),
      ],
    );
  }
}

class _ToDateSelector extends StatelessWidget {
  const _ToDateSelector();

  @override
  Widget build(BuildContext context) {
    final event = Provider.of<EventDataProvider>(context).currentEvent;
    final setState = Provider.of<EventDataProvider>(context).setState;

    if (!event.allDay) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: DateTimePicker(
          labelText: 'To',
          selectedDate: event.end,
          selectedTime:
              TimeOfDay(hour: event.end.hour, minute: event.end.minute),
          selectDate: (DateTime date) => setState(
            (_) => event.end = _combineDateWithTime(date,
                TimeOfDay(hour: event.end.hour, minute: event.end.minute)),
          ),
          selectTime: (TimeOfDay time) => setState(
            (_) => event.end = _combineDateWithTime(event.end, time),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _FromDateSelector extends StatelessWidget {
  const _FromDateSelector();

  @override
  Widget build(BuildContext context) {
    final event = Provider.of<EventDataProvider>(context).currentEvent;
    final setState = Provider.of<EventDataProvider>(context).setState;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: DateTimePicker(
        labelText: 'From',
        enableTime: !event.allDay,
        selectedDate: event.start,
        selectedTime:
            TimeOfDay(hour: event.start.hour, minute: event.start.minute),
        selectDate: (DateTime date) => setState((_) => event.start =
            _combineDateWithTime(date,
                TimeOfDay(hour: event.start.hour, minute: event.start.minute))),
        selectTime: (TimeOfDay time) => setState(
          (_) => event.start = _combineDateWithTime(event.start, time),
        ),
      ),
    );
  }
}

class _AllDaySwitch extends StatelessWidget {
  const _AllDaySwitch();

  @override
  Widget build(BuildContext context) {
    final event = Provider.of<EventDataProvider>(context).currentEvent;
    final setState = Provider.of<EventDataProvider>(context).setState;

    return SwitchListTile(
      value: event.allDay,
      onChanged: (value) => setState((_) => event.allDay = value),
      title: Text('All Day'),
    );
  }
}

class _UrlInput extends StatelessWidget {
  const _UrlInput();

  @override
  Widget build(BuildContext context) {
    final event =
        Provider.of<EventDataProvider>(context, listen: false).currentEvent;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        initialValue: event.url?.data?.contentText ?? '',
        autofocus: false,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        decoration: const InputDecoration(
            labelText: 'URL', hintText: 'https://google.com'),
        onChanged: (String value) => event.url = Uri.dataFromString(value),
      ),
    );
  }
}

class _LocationInput extends StatelessWidget {
  const _LocationInput();

  @override
  Widget build(BuildContext context) {
    final event =
        Provider.of<EventDataProvider>(context, listen: false).currentEvent;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        initialValue: event.location,
        autofocus: false,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        decoration: const InputDecoration(
            labelText: 'Location', hintText: 'Sydney, Australia'),
        onChanged: (String value) => event.location = value,
      ),
    );
  }
}

class _DescriptionInput extends StatelessWidget {
  const _DescriptionInput();

  @override
  Widget build(BuildContext context) {
    final event =
        Provider.of<EventDataProvider>(context, listen: false).currentEvent;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        initialValue: event.description,
        autofocus: false,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        decoration: const InputDecoration(
            labelText: 'Description', hintText: 'Remember to buy flowers...'),
        onChanged: (String value) => event.description = value,
      ),
    );
  }
}

class _TitleInput extends StatelessWidget {
  const _TitleInput();

  @override
  Widget build(BuildContext context) {
    final event =
        Provider.of<EventDataProvider>(context, listen: false).currentEvent;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        initialValue: event.title,
        autofocus: false,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        decoration: const InputDecoration(
            labelText: 'Title', hintText: 'Meeting with Gloria...'),
        validator: (String value) => value.isEmpty ? 'Name is required.' : null,
        onChanged: (String value) => event.title = value,
      ),
    );
  }
}

class _CalendarSelector extends StatelessWidget {
  const _CalendarSelector();

  @override
  Widget build(BuildContext context) {
    final calendarNameIdMap =
        Provider.of<CalendarDataProvider>(context).calendarNameIdMap;
    final event = Provider.of<EventDataProvider>(context).currentEvent;
    final setState = Provider.of<EventDataProvider>(context).setState;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: DropdownButton<String>(
        value: event.calendarName,
        isExpanded: true,
        icon: const Icon(Icons.calendar_today),
        iconEnabledColor: Colors.blue,
        elevation: 9,
        underline: Container(height: 2, color: Colors.black54),
        onChanged: (String newName) => setState((_) {
          event.calendarName = newName;
          event.calendarId = calendarNameIdMap[newName];
        }),
        items: calendarNameIdMap.keys
            .map((String calendarName) => DropdownMenuItem<String>(
                  key: ValueKey(calendarName),
                  value: calendarName,
                  child: Text(calendarName, textAlign: TextAlign.left),
                ))
            .toList(),
      ),
    );
  }
}

DateTime _combineDateWithTime(DateTime date, TimeOfDay time) {
  if (date == null && time == null) {
    return null;
  }
  final dateWithoutTime =
      DateTime.parse(DateFormat("y-MM-dd 00:00:00").format(date));
  return dateWithoutTime.add(Duration(hours: time.hour, minutes: time.minute));
}

void _showInSnackBar(String value, BuildContext scaffoldContext) {
  Scaffold.of(scaffoldContext).showSnackBar(SnackBar(content: Text(value)));
}
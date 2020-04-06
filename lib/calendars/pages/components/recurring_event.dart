import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tep/calendars/custom_event.dart';
import 'package:tep/calendars/pages/components/date_time_picker.dart';
import 'package:tep/calendars/events_provider.dart';

/// Subview of [CalendarEventPage], only built when "Is recurring" checkbox is true
class RecurringEvent extends StatelessWidget {
  final CustomEvent _currentEvent;
  final CustomRecurrenceRule _rule;
  final Function(Duration) _onEnd;

  RecurringEvent(this._currentEvent, {Function(Duration) onEnd})
      : _onEnd = onEnd,
        assert(_currentEvent != null),
        assert(_currentEvent.recurrenceRule != null),
        _rule = _currentEvent.recurrenceRule;

  @override
  Widget build(BuildContext context) {
    // print('>>>>>>>>>> Building New/Edit Event SubPage');

    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks)
      WidgetsBinding.instance.addPostFrameCallback(_onEnd);

    final provider = Provider.of<EventDataProvider>(context);
    final setState = provider.setState;

    // add extra validations on form save event
    provider.addEventListener(_currentEvent.eventId, _onFormSave);

    return Column(
      children: [
        ListTile(
          leading: Text('Select a Recurrence Type'),
          trailing: DropdownButton<RecurrenceFrequency>(
            onChanged: (selectedFrequency) => setState((_) => _rule.recurrenceFrequency = selectedFrequency),
            value: _rule.recurrenceFrequency,
            items: RecurrenceFrequency.values
                .map((frequency) => DropdownMenuItem(
                      value: frequency,
                      child: _recurrenceFrequencyToText(frequency),
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
          child: Row(
            children: <Widget>[
              Text('Repeat Every '),
              Flexible(
                child: TextFormField(
                  initialValue:
                      _rule.interval?.toString() ?? '1',
                  decoration: const InputDecoration(hintText: '1'),
                  keyboardType: TextInputType.number,
                  autofocus: false,
                  inputFormatters: [
                    WhitelistingTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2)
                  ],
                  validator: (String value) =>
                      (value.isNotEmpty && int.tryParse(value) == null)
                          ? 'Interval needs to be a valid number'
                          : null,
                  textAlign: TextAlign.right,
                  onChanged: (String value) => setState((_) => _rule.interval = int.tryParse(value)),
                ),
              ),
              _recurrenceFrequencyToIntervalText(
                  _rule.recurrenceFrequency),
            ],
          ),
        ),
        if (_rule.recurrenceFrequency ==
            RecurrenceFrequency.Weekly)
          Column(
            children: [
              ...DayOfWeek.values.map(
                (day) => CheckboxListTile(
                  title: Text(day.enumToString),
                  value: _rule.daysOfWeek
                          ?.any((dow) => dow == day) ??
                      false,
                  onChanged: (selected) {
                    setState((_) {
                      _rule.daysOfWeek ??=
                          List<DayOfWeek>();
                      selected
                          ? _rule.daysOfWeek.add(day)
                          : _rule.daysOfWeek.remove(day);
                    });
                  },
                ),
              ),
            ],
          ),
        if (_rule.recurrenceFrequency ==
                RecurrenceFrequency.Monthly ||
            _rule.recurrenceFrequency ==
                RecurrenceFrequency.Yearly)
          SwitchListTile(
            value: _rule.isByDayOfMonth,
            onChanged: (value) =>
                setState((_) => _rule.isByDayOfMonth = value),
            title: Text('By day of the month'),
          ),
        if (_rule.recurrenceFrequency ==
                RecurrenceFrequency.Yearly &&
            _rule.isByDayOfMonth)
          ListTile(
            leading: Text('Month of the year'),
            trailing: DropdownButton<MonthOfYear>(
              onChanged: (value) => setState(
                  (_) => _rule.monthOfYear = value),
              value: _rule.monthOfYear,
              items: MonthOfYear.values
                  .map((month) => DropdownMenuItem(
                        value: month,
                        child: Text(month.enumToString),
                      ))
                  .toList(),
            ),
          ),
        if (_rule.isByDayOfMonth &&
            (_rule.recurrenceFrequency ==
                    RecurrenceFrequency.Monthly ||
                _rule.recurrenceFrequency ==
                    RecurrenceFrequency.Yearly))
          ListTile(
            leading: Text('Day of the month'),
            trailing: DropdownButton<int>(
              onChanged: (value) => setState(
                  (_) => _rule.dayOfMonth = value),
              value: _rule.dayOfMonth,
              items: _getValidDaysOfMonth(
                      _rule.recurrenceFrequency,
                      _rule.monthOfYear)
                  .map((day) => DropdownMenuItem(
                        value: day,
                        child: Text(day.toString()),
                      ))
                  .toList(),
            ),
          ),
        if (!_rule.isByDayOfMonth &&
            (_rule.recurrenceFrequency ==
                    RecurrenceFrequency.Monthly ||
                _rule.recurrenceFrequency ==
                    RecurrenceFrequency.Yearly)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_recurrenceFrequencyToText(
                          _rule.recurrenceFrequency)
                      .data +
                  ' on the '),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: DropdownButton<WeekNumber>(
                    onChanged: (value) => setState((_) =>
                        _rule.weekOfMonth = value),
                    value: _rule.weekOfMonth ??
                        WeekNumber.First,
                    items: WeekNumber.values
                        .map((weekNum) => DropdownMenuItem(
                              value: weekNum,
                              child: Text(weekNum.enumToString),
                            ))
                        .toList(),
                  ),
                ),
                Flexible(
                  child: DropdownButton<DayOfWeek>(
                    onChanged: (value) => setState(
                        (_) => _rule.selectedDayOfWeek = value),
                    value: _rule.selectedDayOfWeek,
                    items: DayOfWeek.values
                        .map((day) => DropdownMenuItem(
                              value: day,
                              child: Text(day.enumToString),
                            ))
                        .toList(),
                  ),
                ),
                if (_rule.recurrenceFrequency ==
                    RecurrenceFrequency.Yearly) ...[
                  Text('of'),
                  Flexible(
                    child: DropdownButton<MonthOfYear>(
                      onChanged: (value) => setState((_) =>
                          _rule.monthOfYear = value),
                      value: _rule.monthOfYear,
                      items: MonthOfYear.values
                          .map((month) => DropdownMenuItem(
                                value: month,
                                child: Text(month.enumToString),
                              ))
                          .toList(),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
        ListTile(
          leading: Text('Event ends'),
          trailing: DropdownButton<RecurrenceRuleEndType>(
            onChanged: (value) =>
                setState((_) => _rule.recurrenceRuleEndType = value),
            value: _rule.recurrenceRuleEndType,
            items: RecurrenceRuleEndType.values
                .map((frequency) => DropdownMenuItem(
                      value: frequency,
                      child: _recurrenceRuleEndTypeToText(frequency),
                    ))
                .toList(),
          ),
        ),
        if (_rule.recurrenceRuleEndType ==
            RecurrenceRuleEndType.MaxOccurrences)
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Row(
              children: <Widget>[
                Text('For the next '),
                Flexible(
                  child: TextFormField(
                    initialValue: _rule.totalOccurrences
                            ?.toString() ??
                        '1',
                    decoration: const InputDecoration(hintText: '1'),
                    keyboardType: TextInputType.number,
                    autofocus: false,
                    inputFormatters: [
                      WhitelistingTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: (value) =>
                        (value.isNotEmpty && int.tryParse(value) == null)
                            ? 'Total occurrences needs to be a valid number'
                            : null,
                    textAlign: TextAlign.right,
                    onChanged: (String value) => setState((_) => _rule.totalOccurrences = int.tryParse(value)),
                  ),
                ),
                Text(' occurrences'),
              ],
            ),
          ),
        if (_rule.recurrenceRuleEndType ==
            RecurrenceRuleEndType.SpecifiedEndDate)
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: DateTimePicker(
              labelText: 'Date',
              enableTime: false,
              selectedDate: _rule.endDate,
              selectDate: (DateTime date) =>
                  setState((_) => _rule.endDate = date),
            ),
          ),
      ],
    );
  }

  /// When user clicks "save" button on the [CalendarEventPage],
  /// **note that this is only called when the subview is built**, [_currentEvent.isRecurring] is always true
  _onFormSave() {
    if (_rule.isByDayOfMonth &&
        (_rule.recurrenceFrequency ==
                RecurrenceFrequency.Monthly ||
            _rule.recurrenceFrequency ==
                RecurrenceFrequency.Yearly)) {
      // Setting day of the week parameters for WeekNumber to avoid clashing with the weekly recurrence values
      _rule.daysOfWeek?.clear();
      _rule.daysOfWeek?.add(_rule.selectedDayOfWeek);
    } else {
      _rule.weekOfMonth = null;
    }

    _rule.endDate =
        _rule.recurrenceRuleEndType ==
                RecurrenceRuleEndType.SpecifiedEndDate
            ? _rule.endDate
            : null;
  }
  // Get total days of a month
  List<int> _getValidDaysOfMonth(
      RecurrenceFrequency frequency, MonthOfYear month) {
    var totalDays = 0;
    // Year frequency: Get total days of the selected month
    // Otherwise, get total days of the current month
    if (frequency == RecurrenceFrequency.Yearly) {
      totalDays = DateTime(DateTime.now().year, month.value + 1, 0).day;
    } else {
      totalDays =
          DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    }

    return List<int>.generate(totalDays, (index) => index);
  }

  Text _recurrenceFrequencyToText(RecurrenceFrequency recurrenceFrequency) {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.Daily:
        return Text('Daily');
      case RecurrenceFrequency.Weekly:
        return Text('Weekly');
      case RecurrenceFrequency.Monthly:
        return Text('Monthly');
      case RecurrenceFrequency.Yearly:
        return Text('Yearly');
      default:
        return Text('');
    }
  }

  Text _recurrenceFrequencyToIntervalText(
      RecurrenceFrequency recurrenceFrequency) {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.Daily:
        return Text(' Day(s)');
      case RecurrenceFrequency.Weekly:
        return Text(' Week(s) on');
      case RecurrenceFrequency.Monthly:
        return Text(' Month(s)');
      case RecurrenceFrequency.Yearly:
        return Text(' Year(s)');
      default:
        return Text('');
    }
  }

  Text _recurrenceRuleEndTypeToText(RecurrenceRuleEndType endType) {
    switch (endType) {
      case RecurrenceRuleEndType.Indefinite:
        return Text('Indefinitely');
      case RecurrenceRuleEndType.MaxOccurrences:
        return Text('After a set number of times');
      case RecurrenceRuleEndType.SpecifiedEndDate:
        return Text('Continues until a specified date');
      default:
        return Text('');
    }
  }
}

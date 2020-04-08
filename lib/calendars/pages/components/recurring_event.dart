import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tep/calendars/custom_event.dart';
import 'package:tep/calendars/pages/components/date_time_picker.dart';
import 'package:tep/calendars/events_provider.dart';

/// Subview of [CalendarEventPage], only built when "Is recurring" checkbox is true
class RecurringEvent extends StatelessWidget {
  const RecurringEvent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventDataProvider>(context);
    final currentEvent = provider.currentEvent;

    if (currentEvent.recurrenceRule == null) {
      return const SizedBox.shrink();
    } else {
      // add extra validations on form save event
      provider.addEventListener(currentEvent.eventId, () => _onFormSave(currentEvent.recurrenceRule));

      return const _Content();
    }
  }

  /// When user clicks "save" button on the [CalendarEventPage],
  /// **note that this is only called when the subview is built**, [currentEvent.isRecurring] is always true
  _onFormSave(CustomRecurrenceRule rule) {
    if (rule.isByDayOfMonth &&
        (rule.recurrenceFrequency == RecurrenceFrequency.Monthly ||
            rule.recurrenceFrequency == RecurrenceFrequency.Yearly)) {
      // Setting day of the week parameters for WeekNumber to avoid clashing with the weekly recurrence values
      rule.daysOfWeek?.clear();
      rule.daysOfWeek?.add(rule.selectedDayOfWeek);
    } else {
      rule.weekOfMonth = null;
    }

    rule.endDate =
        rule.recurrenceRuleEndType == RecurrenceRuleEndType.SpecifiedEndDate
            ? rule.endDate
            : null;
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    print('///////// Building Recurrence Event Content  \\\\\\\\\\\\\\\\\\');
    print('');

    return Column(
      children: [
        const _RecurrenceFrequencyType(),
        const _Interval(),
        /* if (rule.recurrenceFrequency == RecurrenceFrequency.Weekly) */
        const _DaysOfWeekCheckboxes(),
        /* if (rule.recurrenceFrequency == RecurrenceFrequency.Monthly ||
            rule.recurrenceFrequency == RecurrenceFrequency.Yearly) */
        _ByDayOfMonthSwitch(),
        /* if (rule.recurrenceFrequency == RecurrenceFrequency.Yearly &&
            rule.isByDayOfMonth) */
        const _MonthDropdownButton(),
        /* if (rule.isByDayOfMonth &&
            (rule.recurrenceFrequency == RecurrenceFrequency.Monthly ||
                rule.recurrenceFrequency == RecurrenceFrequency.Yearly)) */
        const _ValidDaysDropdownButton(),
        /* if (!rule.isByDayOfMonth &&
            (rule.recurrenceFrequency == RecurrenceFrequency.Monthly ||
                rule.recurrenceFrequency == RecurrenceFrequency.Yearly)) */
        const _MonthlyOrYearlyOccurance(),
        const _RecurrenceRuleEndType(),
        /* if (rule.recurrenceRuleEndType == RecurrenceRuleEndType.MaxOccurrences) */
        const _MaxOcurrences(),
        /* if (rule.recurrenceRuleEndType == RecurrenceRuleEndType.SpecifiedEndDate) */
        const _SpecifiedEndDate(),
      ],
    );
  }
}

class _SpecifiedEndDate extends StatelessWidget {
  const _SpecifiedEndDate();

  @override
  Widget build(BuildContext context) {
    final rule =
        Provider.of<EventDataProvider>(context).currentEvent.recurrenceRule;
    final setState = Provider.of<EventDataProvider>(context).setState;

    if (rule.recurrenceRuleEndType == RecurrenceRuleEndType.SpecifiedEndDate)
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: DateTimePicker(
          labelText: 'Date',
          enableTime: false,
          selectedDate: rule.endDate,
          selectDate: (DateTime date) => setState((_) => rule.endDate = date),
        ),
      );

    return const SizedBox.shrink();
  }
}

class _MaxOcurrences extends StatelessWidget {
  const _MaxOcurrences();

  @override
  Widget build(BuildContext context) {
    final rule =
        Provider.of<EventDataProvider>(context).currentEvent.recurrenceRule;
    final setState = Provider.of<EventDataProvider>(context).setState;

    if (rule.recurrenceRuleEndType == RecurrenceRuleEndType.MaxOccurrences)
      return Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
        child: Row(
          children: <Widget>[
            Text('For the next '),
            Flexible(
              child: TextFormField(
                initialValue: rule.totalOccurrences?.toString() ?? '1',
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
                onChanged: (String value) => setState(
                    (_) => rule.totalOccurrences = int.tryParse(value)),
              ),
            ),
            Text(' occurrences'),
          ],
        ),
      );

    return const SizedBox.shrink();
  }
}

class _RecurrenceRuleEndType extends StatelessWidget {
  const _RecurrenceRuleEndType();

  @override
  Widget build(BuildContext context) {
    final rule =
        Provider.of<EventDataProvider>(context).currentEvent.recurrenceRule;
    final setState = Provider.of<EventDataProvider>(context).setState;

    return ListTile(
      leading: Text('Event ends'),
      trailing: DropdownButton<RecurrenceRuleEndType>(
        onChanged: (value) =>
            setState((_) => rule.recurrenceRuleEndType = value),
        value: rule.recurrenceRuleEndType,
        items: RecurrenceRuleEndType.values
            .map((frequency) => DropdownMenuItem(
                  value: frequency,
                  child: _recurrenceRuleEndTypeToText(frequency),
                ))
            .toList(),
      ),
    );
  }
}

class _MonthlyOrYearlyOccurance extends StatelessWidget {
  const _MonthlyOrYearlyOccurance();

  @override
  Widget build(BuildContext context) {
    final rule =
        Provider.of<EventDataProvider>(context).currentEvent.recurrenceRule;
    final setState = Provider.of<EventDataProvider>(context).setState;

    if (!rule.isByDayOfMonth &&
        (rule.recurrenceFrequency == RecurrenceFrequency.Monthly ||
            rule.recurrenceFrequency == RecurrenceFrequency.Yearly))
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  _recurrenceFrequencyToText(rule.recurrenceFrequency).data +
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
                    onChanged: (value) =>
                        setState((_) => rule.weekOfMonth = value),
                    value: rule.weekOfMonth ?? WeekNumber.First,
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
                    onChanged: (value) =>
                        setState((_) => rule.selectedDayOfWeek = value),
                    value: rule.selectedDayOfWeek,
                    items: DayOfWeek.values
                        .map((day) => DropdownMenuItem(
                              value: day,
                              child: Text(day.enumToString),
                            ))
                        .toList(),
                  ),
                ),
                if (rule.recurrenceFrequency == RecurrenceFrequency.Yearly) ...[
                  Text('of'),
                  Flexible(
                    child: DropdownButton<MonthOfYear>(
                      onChanged: (value) =>
                          setState((_) => rule.monthOfYear = value),
                      value: rule.monthOfYear,
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
      );

    return const SizedBox.shrink();
  }
}

class _ValidDaysDropdownButton extends StatelessWidget {
  const _ValidDaysDropdownButton();

  @override
  Widget build(BuildContext context) {
    final rule =
        Provider.of<EventDataProvider>(context).currentEvent.recurrenceRule;
    final setState = Provider.of<EventDataProvider>(context).setState;
    if (rule.isByDayOfMonth &&
        (rule.recurrenceFrequency == RecurrenceFrequency.Monthly ||
            rule.recurrenceFrequency == RecurrenceFrequency.Yearly))
      return ListTile(
        leading: Text('Day of the month'),
        trailing: DropdownButton<int>(
          onChanged: (value) => setState((_) => rule.dayOfMonth = value),
          value: rule.dayOfMonth,
          items:
              _getValidDaysOfMonth(rule.recurrenceFrequency, rule.monthOfYear)
                  .map((day) => DropdownMenuItem(
                        value: day,
                        child: Text(day.toString()),
                      ))
                  .toList(),
        ),
      );

    return const SizedBox.shrink();
  }
}

class _MonthDropdownButton extends StatelessWidget {
  const _MonthDropdownButton();

  @override
  Widget build(BuildContext context) {
    final rule =
        Provider.of<EventDataProvider>(context).currentEvent.recurrenceRule;
    final setState = Provider.of<EventDataProvider>(context).setState;

    if (rule.recurrenceFrequency == RecurrenceFrequency.Yearly &&
        rule.isByDayOfMonth)
      return ListTile(
        leading: Text('Month of the year'),
        trailing: DropdownButton<MonthOfYear>(
          onChanged: (value) => setState((_) => rule.monthOfYear = value),
          value: rule.monthOfYear,
          items: MonthOfYear.values
              .map((month) => DropdownMenuItem(
                    value: month,
                    child: Text(month.enumToString),
                  ))
              .toList(),
        ),
      );

    return const SizedBox.shrink();
  }
}

class _ByDayOfMonthSwitch extends StatelessWidget {
  const _ByDayOfMonthSwitch();

  @override
  Widget build(BuildContext context) {
    final rule =
        Provider.of<EventDataProvider>(context).currentEvent.recurrenceRule;
    final setState = Provider.of<EventDataProvider>(context).setState;

    if (rule.recurrenceFrequency == RecurrenceFrequency.Monthly ||
        rule.recurrenceFrequency == RecurrenceFrequency.Yearly)
      return SwitchListTile(
        value: rule.isByDayOfMonth,
        onChanged: (value) => setState((_) => rule.isByDayOfMonth = value),
        title: Text('By day of the month'),
      );

    return const SizedBox.shrink();
  }
}

class _DaysOfWeekCheckboxes extends StatelessWidget {
  const _DaysOfWeekCheckboxes();

  @override
  Widget build(BuildContext context) {
    final rule =
        Provider.of<EventDataProvider>(context).currentEvent.recurrenceRule;
    final setState = Provider.of<EventDataProvider>(context).setState;

    if (rule.recurrenceFrequency == RecurrenceFrequency.Weekly)
      return Column(
        children: [
          ...DayOfWeek.values.map(
            (day) => CheckboxListTile(
              title: Text(day.enumToString),
              value: rule.daysOfWeek?.any((dow) => dow == day) ?? false,
              onChanged: (selected) {
                setState((_) {
                  rule.daysOfWeek ??= List<DayOfWeek>();
                  selected
                      ? rule.daysOfWeek.add(day)
                      : rule.daysOfWeek.remove(day);
                });
              },
            ),
          ),
        ],
      );

    return const SizedBox.shrink();
  }
}

class _Interval extends StatelessWidget {
  const _Interval();

  @override
  Widget build(BuildContext context) {
    final rule =
        Provider.of<EventDataProvider>(context).currentEvent.recurrenceRule;
    final setState = Provider.of<EventDataProvider>(context).setState;

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
      child: Row(
        children: <Widget>[
          Text('Repeat Every '),
          Flexible(
            child: TextFormField(
              initialValue: rule.interval?.toString() ?? '1',
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
              onChanged: (String value) =>
                  setState((_) => rule.interval = int.tryParse(value)),
            ),
          ),
          _recurrenceFrequencyToIntervalText(rule.recurrenceFrequency),
        ],
      ),
    );
  }
}

class _RecurrenceFrequencyType extends StatelessWidget {
  const _RecurrenceFrequencyType();

  @override
  Widget build(BuildContext context) {
    final rule =
        Provider.of<EventDataProvider>(context).currentEvent.recurrenceRule;
    final setState = Provider.of<EventDataProvider>(context).setState;

    return ListTile(
      leading: Text('Select a Recurrence Type'),
      trailing: DropdownButton<RecurrenceFrequency>(
        onChanged: (selectedFrequency) =>
            setState((_) => rule.recurrenceFrequency = selectedFrequency),
        value: rule.recurrenceFrequency,
        items: RecurrenceFrequency.values
            .map((frequency) => DropdownMenuItem(
                  value: frequency,
                  child: _recurrenceFrequencyToText(frequency),
                ))
            .toList(),
      ),
    );
  }
}

/// Get total days of a month
List<int> _getValidDaysOfMonth(
    RecurrenceFrequency frequency, MonthOfYear month) {
  var totalDays = 0;
  // Year frequency: Get total days of the selected month
  // Otherwise, get total days of the current month
  if (frequency == RecurrenceFrequency.Yearly) {
    totalDays = DateTime(DateTime.now().year, month.value + 1, 0).day;
  } else {
    totalDays = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
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

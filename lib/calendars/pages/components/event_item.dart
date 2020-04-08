import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tep/calendars/pages/calendar_events.dart';
import 'package:tep/calendars/pages/components/confirm_dialog.dart';
import '../../custom_event.dart';

/// The card widget displayed on [CalendarEventsPage]
/// 
/// made stateful to contain animations
class EventItem extends StatefulWidget {
  final CustomEvent _event;
  final Function(CustomEvent) _onTapped;
  final Function(CustomEvent, bool) _onDelete;

  const EventItem(
      {@required CustomEvent event,
      Key key,
      Function(CustomEvent, bool) onDelete,
      Function(CustomEvent) onTapped})
      : _event = event,
        _onDelete = onDelete,
        _onTapped = onTapped,
        super(key: key);

  @override
  _EventItemState createState() => _EventItemState();
}

class _EventItemState extends State<EventItem> with TickerProviderStateMixin {
  /// Duration in milliseconds of each animation
  static const int _animationDuration = 500;

  /// Slide the item out of view box
  AnimationController _offsetAnimationController;

  /// Tween offset the negative (left side)
  /// then quickly bump to 1.0 (right side)
  Animation<Offset> _offsetAnimation;

  /// After [_offsetAnimationController] is done, "shrink" the item down
  AnimationController _sizeAnimationController;

  /// Tween from 1.0 to 0.0
  Animation<double> _sizeAnimation;

  @override
  void initState() {
    _offsetAnimationController = AnimationController(
      duration: const Duration(milliseconds: _animationDuration),
      vsync: this,
    );

    _sizeAnimationController = AnimationController(
      duration: const Duration(milliseconds: _animationDuration),
      vsync: this,
    );

    _offsetAnimation = TweenSequence([
      TweenSequenceItem(
          tween: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.3, 0))
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25.0),
      TweenSequenceItem(
          tween:
              Tween<Offset>(begin: Offset(-0.3, 0), end: const Offset(1.0, 0.0))
                  .chain(CurveTween(curve: Curves.easeInBack)),
          weight: 75.0),
    ]).animate(_offsetAnimationController);

    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0)
        .chain(CurveTween(curve: Interval(0.2, 0.8, curve: Curves.ease)))
        .animate(_sizeAnimationController);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: ObjectKey(widget._event),
        confirmDismiss: (_) => _showDialog(context),
        background: const Card(
          color: Colors.blueGrey,
          elevation: 10.0,
          margin: EdgeInsets.symmetric(vertical: 24.0),
        ),
        onDismissed: (_) {
          if (widget._onDelete != null)
            widget._onDelete(widget._event, true);
        },
        child: _SizeAnimator(
          sizeAnimation: _sizeAnimation,
          child: _SlideAnimator(
            slideAnimation: _offsetAnimation,
            child: _Content(
              widget._event,
              onTapped: widget._onTapped,
              onDelete: (result) {
                // runs the two animations in order
                // dispose them when done
                // _(disposing them in `dispose()` method cause conflict with other animations)_
                _offsetAnimationController.forward().orCancel.whenComplete(() =>
                    _sizeAnimationController.forward().orCancel.whenComplete(() {
                      _offsetAnimationController.dispose();
                      _sizeAnimationController.dispose();
                      return widget._onDelete(widget._event, result);
                    }));
              },
            ),
          ),
        ),
      );
  }
}

class _SizeAnimator extends AnimatedWidget {
  final Listenable sizeAnimation;
  final Widget child;
  final Axis axis;

  const _SizeAnimator({
    @required Listenable sizeAnimation,
    Key key,
    Widget child,
    Axis axis,
  })  : sizeAnimation = sizeAnimation,
        child = child,
        axis = axis,
        super(listenable: sizeAnimation, key: key);

  @override
  Widget build(BuildContext context) => SizeTransition(
        sizeFactor: sizeAnimation,
        axis: axis ?? Axis.vertical,
        child: child,
      );
}

class _SlideAnimator extends AnimatedWidget {
  final Listenable slideAnimation;
  final Widget child;

  const _SlideAnimator(
      {@required Listenable slideAnimation, Key key, Widget child})
      : slideAnimation = slideAnimation,
        child = child,
        super(listenable: slideAnimation, key: key);

  @override
  Widget build(BuildContext context) => SlideTransition(
        key: key,
        position: slideAnimation,
        child: child,
      );
}

/// The main content
class _Content extends StatelessWidget {
  final _eventFieldNameWidth = 75.0;
  final CustomEvent calendarEvent;

  final Function(CustomEvent) onTapped;
  final Function(bool) onDelete;

  const _Content(this.calendarEvent, {this.onTapped, this.onDelete});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          if (onTapped != null) onTapped(calendarEvent);
        },
        child: Card(
          borderOnForeground: false,
          elevation: 5.0,
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                  title: Text(calendarEvent.title ?? ''),
                  subtitle: Text(calendarEvent.description ?? '')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        children: [
                          Container(
                            width: _eventFieldNameWidth,
                            child: const Text('Starts'),
                          ),
                          Text(calendarEvent == null
                              ? ''
                              : DateFormat.yMd()
                                  .add_jm()
                                  .format(calendarEvent.start)),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 7.5,
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        children: [
                          Container(
                            width: _eventFieldNameWidth,
                            child: const Text('Ends'),
                          ),
                          Text(calendarEvent.end == null
                              ? ''
                              : DateFormat.yMd()
                                  .add_jm()
                                  .format(calendarEvent.end)),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 7.5,
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        children: [
                          Container(
                            width: _eventFieldNameWidth,
                            child: const Text('All day?'),
                          ),
                          Text(calendarEvent.allDay != null &&
                                  calendarEvent.allDay
                              ? 'Yes'
                              : 'No')
                        ],
                      ),
                    ),
                    if (calendarEvent?.location?.isNotEmpty ?? false)
                      const SizedBox(
                        height: 7.5,
                      ),
                    if (calendarEvent?.location?.isNotEmpty ?? false)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          children: [
                            Container(
                              width: _eventFieldNameWidth,
                              child: Text('Location'),
                            ),
                            Expanded(
                              child: Text(
                                calendarEvent.location,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (calendarEvent?.url != null)
                      const SizedBox(
                        height: 7.5,
                      ),
                    if (calendarEvent?.url != null)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          children: [
                            Container(
                              width: _eventFieldNameWidth,
                              child: const Text('URL'),
                            ),
                            Expanded(
                              child: Text(
                                calendarEvent.url.data.contentText ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ),
                    if ((calendarEvent?.attendees?.length ?? 0) > 0)
                      const SizedBox(
                        height: 7.5,
                      ),
                    if ((calendarEvent?.attendees?.length ?? 0) > 0)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          children: [
                            Container(
                              width: _eventFieldNameWidth,
                              child: const Text('Attendees'),
                            ),
                            Expanded(
                              child: Text(
                                calendarEvent.attendees
                                    .map((a) => a.emailAddress ?? a.name)
                                    .join(', '),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              ButtonBar(
                buttonPadding: EdgeInsets.all(0),
                children: [
                  IconButton(
                    onPressed: () {
                      if (onTapped != null) onTapped(calendarEvent);
                    },
                    icon: Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () async {
                      bool result = await _showDialog(context);
                      // play animation and actually delete it when done
                      if (result && onDelete != null) onDelete(result);
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ],
              )
            ],
          ),
        ),
      );
}

/// Display a Yes/No dialog
Future<bool> _showDialog(BuildContext context, {String message}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) =>
        const ConfirmDialog(message: 'Are you sure?'),
  );
}

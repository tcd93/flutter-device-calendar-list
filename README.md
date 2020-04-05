## flutter-device-calendar-example
This is a refactored from [Device Calendar Plugin's example](https://pub.dev/packages/device_calendar) as a simple starter project to learn Flutter

#### Architecture
State management: Mimic *Scoped Model* using *Provider*   
Data model: `CustomEvent`


#### Extra contents:
- Scroll to nearest-to-date event on arrow button press
- Event item animations (slide / press trash bin to delete event)


#### Learnt points:
* _FutureBuilder is only used for building Widgets with **3** states only: `initial -> processing -> done`._ It can not rebuild itself after that (unless you're _overwriting_ the _future_ instance, or calling a async method in the _future_ param, but those are bad practices) If you want to do more with the snapshot data later, like deleting/modifying it & update UI, use _Builder_ or _StreamBuilder_ instead.
* _Don't abuse callbacks_, you may never know if you suddenly need to wrap your widget by another widget, passing callbacks mindlessly through the widget tree is not good, _Provider_ can help with that.
* _dispose AnimationControllers immediately when they are not needed anymore_, it may cause conflicts with otherwise, even when you dispose them in Widget life cycle's `dispose()` method.
* `ValueKey`s are easily duplicated

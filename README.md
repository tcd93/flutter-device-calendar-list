_Example codes (with additional features) of Flutter **[device calendar plugin](https://pub.dev/packages/device_calendar)**, display a list of events & allow interacting with the device's calendar_   
  ![add](https://media.giphy.com/media/UrKU7XuV6NymIB30TU/giphy.gif)
  ![delete](https://media.giphy.com/media/dWCih91YmemwIQkLVk/giphy.gif)

#### Architecture
State management: Mimic *Scoped Model* using *Provider*   
Data model: `CustomEvent`
![img](https://i.imgur.com/IHIFuca.png)

#### Extra contents:
- Scroll to nearest-to-date event on arrow button press
- Event item animations (slide / press trash bin to delete event)   
_note: create/edit events with recurrence rule is not stable_

#### Best practices:
* _`FutureBuilder` is only used for building Widgets with __3__ states only: __initial -> processing -> done__._ It can not rebuild itself after that (unless you're _overwriting_ the _future_ instance, or calling a async method in the _future_ param, but those are bad practices) If you want to do more with the snapshot data later, like deleting/modifying it & update UI, use `Builder`, `StreamBuilder` or `ValueListenableBuilder` instead.
* _Make state management as consistent as possible_, either by using a state management tool (like `Provider`, `InheritedWidget`, `Scoped Model`...) or just passing state data via _constructor_, don't create a mixed mess of both.
  - Note: Passing state objects through the widget tree is _not recommended_ by many as this is extremely non-scalable as the app grows bigger.
* _Don't abuse callbacks_, as the above note mentioned, you may never know if you suddenly need to wrap your widget by another widget (and Flutter is infamous for that), implement some kind of _event notifier/listener_ or use `ValueNotifier` class.
* _Dispose AnimationControllers immediately when they are not needed anymore_, it may cause conflicts with otherwise, even when you dispose them in Widget life cycle's `dispose()` method.
* *Operator overloading*: now this is a pretty grey area, use it with _immutable & unique object only!_
* _Always break down big widget into many smaller ones, don't use function for that._ Creating many scoped _context_ is good, it won't rebuild the entire tree when the something is modified.
* _Push `Provider.of` as far as possible down the widget tree_, so that the bigger ones (usually on the above) won't get rebuilt to often.
* _Remember to utilize `listen: false` in `Provider.of`_

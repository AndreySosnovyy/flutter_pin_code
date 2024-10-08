[//]: # (TODO: add intro image)

**pin** package contains all the backend logic any Flutter application may need:

- handle **PIN code** (set, update, test, remove)
- **biometrics** is also included
- 2 types of easy to configure **timeouts**
- ability to **request again** the PIN if the app was in background for too long
- **skip PIN** checker to not disturb user

If you are also interested in fast implementation of PIN codd related UI, then check
out **pin_ui** package.

<p align="left">
<a href="https://pub.dev/packages/pin"><img src="https://img.shields.io/pub/v/pin.svg?style=flat&colorB=blue&label=pin pub" alt="Pub"></a>
<a href="https://github.com/AndreySosnovyy/flutter_pin_code"><img src="https://img.shields.io/github/stars/andreysosnovyy/flutter_pin_code.svg?&style=flat&logo=github&color=red&label=pin" alt="Star on Github"></a>
</p>

## Features

### Pin

The package provides a controller to handle PIN code lifecycle. It has all the
necessary methods to set, update, remove, test.</br>
> **_NOTE:_** In this package it is called **to test** PIN. Means to validate it,
> check if it is correct.

### Biometrics

This package uses [**local_auth**](https://pub.dev/packages/local_auth) for handling
biometrics. By using PinCodeController you can check if biometrics is available on
current device, set it if so, test it, remove.

> **_NOTE:_** Biometrics may only work on **real devices**!

Also don't forget to [configure your app](#configuration-from-local_auth)
for using biometrics.

### Timeouts

Developer can set the configuration that will **limit the amount of attempts** for user
to enter PIN code. By default, this amount is **infinite**.

There are two types of timeout configurations: **refreshable** and
**non-refreshable**.</br>
The first type gives the user ability to enter pin code infinite number of times,
but protects from brute-force.</br>
The second type only gives user predetermined amount of attempts. After they have been
used, current user session must be terminated and the user navigated to start a new
sign-in process to proof their identity.

### Request Again

Request Again feature brings **more protection** for your app!</br>
It allows to preconfigure (set once by developer in advance) or configure somewhere
in app settings (by user in runtime) a single simple rule: if the app was in the
background for some time, user will have to go through PIN code screen again in case
to go back to the app.

### Skip Pin

This feature is here to make user **experience more smooth and non-distracting**.
Why ask for PIN code if it was just entered a few minutes ago?</br>
Controller can be configured in such way that it will count amount of time gone from
last PIN code entering. If it is less than allowed duration without entering,
the next one can be skipped.</br>
It can be configured by a developer in advance or by user in runtime if such setting
presented somewhere in app settings.

## Getting started

### local_auth configuration

In case you want to work with biometrics, you have to go through all the steps
to configure **local_auth** for [android](https://pub.dev/packages/local_auth#android-integration)
and [ios](https://pub.dev/packages/local_auth#ios-integration)! Otherwise, there
will be unexpected app behavior and crushes when you call biometrics-related methods.
Be sure to configure using guide for appropriate local_auth dependency version in
**pin**'s [pubspec.yaml](https://github.com/AndreySosnovyy/flutter_pin_code/blob/main/pubspec.yaml)!

### Controller initialization

Before calling any method in pin code controller, it must be initialized:

```dart
final controller = PinCodeController();
await controller.initialize(); // <-- async initialization method 
```

### Request Again configuration

Controller handles app life cycle changes. The only thing developer must do is to
provide these changes when they happen. To do so you can add `WidgetsBindingObserver`
mixin somewhere in your app to override these methods: `initState`,
`didChangeAppLifecycleState`,`dispose`. Where you have to do 3 things:

1) Add an observer:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
}
```

2) Provide states to controller:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  controller.onAppLifecycleStateChanged(state);
  super.didChangeAppLifecycleState(state);
}
```

3) Dispose it:

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}
```

</br>If you use this Request again feature you have to _always_ set `onRequestAgain`
callback when your app starts and also _every time_ you set a new config in controller.</br>
Fox example you can do it inside `initState` in your app's class:

```dart
@override
void initState() {
  super.initState();
  if (controller.requestAgainConfig == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await myPinCodeController.setRequestAgainConfig(
        controller.requestAgainConfig!.copyWith(onRequestAgain: requestAgainCallback));
  });
}
```

## Usage

### Logging

When creating an instance of `PinCodeController` pass `logsEnabled` parameter equal
to `true`. It is helpful for debugging purposes as all happening events inside
the controller are covered with logs. Disabled by default.

```dart
final controller = PinCodeController(logsEnabled: true);
```

### </br>Configure Timeouts

Timeout configuration class has 2 named constructors: 
`PinCodeTimeoutConfig.notRefreshable` and `PinCodeTimeoutConfig.refreshable`.
Difference between these two described in [introduction section](#timeouts).

Both of these requires `timeouts` map configuration and a few callbacks
(`onTimeoutEnded`, `onTimeoutStarted` and `onMaxTimeoutsReached` for non-refreshable
configuration). The **map** contains amount of attempts (**value**) before every
timeout in seconds (**key**).</br>
If all timeouts are non-refreshable and all are over, then `onMaxTimeoutsReached`
will be triggered.</br>
If timeouts are refreshable and all are over, then the last **pair**(key, value)
will be used repeatedly, but user will only get one attempt at a time.  

Some more requirements:

- **Max duration is 6 hours** (21600 seconds).
- The **first** timeout duration is **always 0**!
- The **order is not important**, but it's easier to understand if you put timeouts
  in direct order. The important factor is timeout duration: shorter timeout can not
  be used after a longer one. It will always go one by one depending on current
  timeout duration starting from 0.

```dart
final timeoutConfig = PinCodeTimeoutConfig.notRefreshable(
  onTimeoutEnded: () {
    showToast('Timeout has ended, you can test pin code now!');
  },
  onTimeoutStarted: (timeoutDuration) {
    showToast('Timeout has started, you must wait $timeoutDuration '
            'before it ends!');
  },
  onMaxTimeoutsReached: () {
    showToast('Signing the user out and performing navigation '
            'to the auth screen!');
  },
  timeouts: {
    0: 3, // initially you have 3 tries before falling into 60 seconds timeout
    60: 2, // another 2 tries after 60 seconds timeout
    600: 1, // another try after 600 seconds timeout
    // In case of refreshable timeouts you will get one attempt after every 600 seconds
  },
);
```

> **_NOTE:_** The **Timeouts** feature can only be **set in advance**, but not
> while app is already running.

### </br>Configure Request Again

Request Again configuration class constructor requires `secondsBeforeRequestingAgain`.
This main parameter determines how long user can be in background without entering
PIN code again after going to foreground.

If **0 seconds** passed, it will require PIN code every time.

The actual `onRequestAgain` callback, which is called when configured time condition
is true, can be set later after. But it must be for sure set before very first
potential Request Again call.

```dart
await controller.setRequestAgainConfig(
    PinCodeRequestAgainConfig(
    secondsBeforeRequestingAgain: 60,
    onRequestAgain: () {
      // Navigate user to PIN screen without ability to avoid it via back button
      // and add any other logic you need here
    },
  ),
); 
```

> **_NOTE:_** The **Request again** feature can be configured both by developer
> in advance and by user in runtime in application settings if there is such
> setting presented.

### </br>Configure Skip Pin

Skip Pin configuration requires the duration in which potentially there will be no
need to enter PIN code.

Take attention that you as a developer must handle it **manually** by checking
`canSkipPinCodeNow` getter value.</br>
Controller can only automatically handle skips for **Request Again** if you
set `forcedForRequestAgain` to `false` (enabled by default) in configuration.

```dart
await controller.setSkipPinCodeConfig(
    SkipPinCodeConfig(
    duration: const Duration(minutes: 1),
    forcedForRequestAgain: false,
  ),
); 
```

> **_NOTE:_** The **Skip Pin** feature can be configured both by developer
> in advance and by user in runtime in application settings if there is such
> setting presented.

### </br>Testing PIN code and biometrics

If PIN code is set you can **test** (check if correct) it by calling `testPinCode`
method. It will return `true` if it is correct and `false` if it is not.</br>
The same goes for biometrics, but it is called `testBiometrics`.

There also `canTestPinCode`, `isPinSet` and `isBiometricsSet` which can be called
to check if it is set, if it can be tested at this moment and so on.

```dart
if (pinCodeController.isTimeoutRunning) {
  return showToast('You must wait for timeout to end');
}
if (!await pinCodeController.canTestPinCode()) {
  return showToast('You can\'t test PIN CODE now');
}
final isPinCodeCorrect = await pinCodeController.testPinCode(pin);
if (isPinCodeCorrect) {
  // Navigate user to the next screen
} else {
  // Display error on screen or show toast
}
```

### </br>Reacting to events (stream)

You may need to react to PIN code related events (such as successfully entered pin,
newly set configuration or timeout start) in UI: updating view, navigating, showing
toast, etc. One way for implementing that is by **listening to stream** named
`eventsStream` from `PinCodeController`. You can find the list of all events can be
thrown in this stream in enum called `PinCodeEvents`.

```dart
final subscription = controller.eventsStream.listen((event) {
  // Update UI, make analytics record or make custom logs here
});
```

### </br>Exceptions

In runtime if you do something wrong an exception will be thrown. So it is better
to wrap calling some controller methods in try-catch blocks and handle them properly.

You can see the list of all potential exceptions in lib/src/exceptions.

### </br>Disposing

Pin code controller has `dispose` method which is meant to be called when you call
dispose method in view class.

```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

## Additional information

### 👀 See also: [pin_ui](https://pub.dev/packages/pin_ui)

[pin_ui package](https://pub.dev/packages/pin_ui) provides 2 core widgets for
every PIN code screen: highly customizable keyboard called `Pinpad` and `PinIndicator`
with tons of pre-made animations to use in one line of code.</br>

<img src="https://raw.githubusercontent.com/AndreySosnovyy/flutter_pin_code_ui/refs/heads/assets/pinpad_pinindicator_demo.gif" alt="" width="320"/>

**pin + pin_ui** are perfect to work together in pair. Combining these two may
save you days of development and the result will be already perfect even out of
the box.

<p align="left">
<a href="https://pub.dev/packages/pin_ui"><img src="https://img.shields.io/pub/v/pin_ui.svg?style=flat&colorB=blue&label=pin_ui pub" alt="Pub"></a>
<a href="https://github.com/AndreySosnovyy/flutter_pin_code_ui"><img src="https://img.shields.io/github/stars/andreysosnovyy/flutter_pin_code_ui.svg?&style=flat&logo=github&color=red&label=pin_ui" alt="Star on Github"></a>
</p>

### 📱 Examples

This package has an [example](https://github.com/AndreySosnovyy/flutter_pin_code/tree/main/example)
project in it, covering main use cases you may want to try out. Feel free to use it
as a playground or a template of PIN code feature core for your applications!

You can also [share your own examples](#-contributing) for this section.

### 🛠 Contributing

You have an interesting open source example to share with community? Found a bug,
or want to suggest an idea on what feature to add next? You're always welcome!
Fell free to open
an [issue](https://github.com/AndreySosnovyy/flutter_pin_code/issues)
or [pull request](https://github.com/AndreySosnovyy/flutter_pin_code/pulls)
in [GitHub repository](https://github.com/AndreySosnovyy/flutter_pin_code)!
</br>
</br>
</br>

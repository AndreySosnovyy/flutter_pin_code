# pin

**pin** package contains all the backend logic any Flutter application may need:

- Handle **PIN code** (set, update, test, remove)
- **Biometrics** support included
- 2 types of easy-to-configure **timeouts**
- Ability to **request again** the PIN if the app was in background for too long
- **Skip PIN** checker to avoid disturbing the user

If you are also interested in fast implementation of PIN code related UI, check
out the **pin_ui** package.

<p align="left">
<a href="https://pub.dev/packages/pin"><img src="https://img.shields.io/pub/v/pin.svg?style=flat&colorB=blue&label=pin pub" alt="Pub"></a>
<a href="https://github.com/AndreySosnovyy/flutter_pin_code"><img src="https://img.shields.io/github/stars/andreysosnovyy/flutter_pin_code.svg?&style=flat&logo=github&color=red&label=pin" alt="Star on Github"></a>
</p>

## Features

### PIN

The package provides a controller to handle PIN code lifecycle. It has all the
necessary methods to set, update, remove, and test.

> **_NOTE:_** In this package it is called **to test** PIN. This means to validate it,
> to check if it is correct.

### Biometrics

This package uses [**local_auth**](https://pub.dev/packages/local_auth) for handling
biometrics. By using `PinCodeController` you can check if biometrics is available on
the current device, set it if so, test it, and remove it.

> **_NOTE:_** Biometrics may only work on **real devices**!

Also don't forget to [configure your app](#local_auth-configuration)
for using biometrics.

### Timeouts

Developers can set a configuration that will **limit the number of attempts** for the user
to enter PIN code. By default, this number is **infinite**.

There are two types of timeout configurations: **refreshable** and
**non-refreshable**.

The first type gives the user the ability to enter PIN code an infinite number of times,
but protects from brute-force attacks.

The second type only gives the user a predetermined number of attempts. After they have been
used, the current user session must be terminated and the user navigated to start a new
sign-in process to prove their identity.

### Request Again

Request Again feature brings **more protection** for your app!

It allows you to preconfigure (set once by the developer in advance) or configure somewhere
in app settings (by the user at runtime) a single simple rule: if the app was in the
background for some time, the user will have to go through the PIN code screen again in order
to go back to the app.

### Skip PIN

This feature is here to make the user **experience smoother and less distracting**.
Why ask for PIN code if it was just entered a few minutes ago?

The controller can be configured in such a way that it will count the amount of time passed since
the last PIN code entry. If it is less than the allowed duration without entering,
the next one can be skipped.

It can be configured by a developer in advance or by the user at runtime if such a setting
is presented somewhere in app settings.

## Getting Started

### local_auth Configuration

If you want to work with biometrics, you have to go through all the steps
to configure **local_auth** for [Android](https://pub.dev/packages/local_auth#android-integration)
and [iOS](https://pub.dev/packages/local_auth#ios-integration)! Otherwise, there
will be unexpected app behavior and crashes when you call biometrics-related methods.
Be sure to configure using the guide for the appropriate local_auth dependency version in
**pin**'s [pubspec.yaml](https://github.com/AndreySosnovyy/flutter_pin_code/blob/main/pubspec.yaml)!

### Controller Initialization

Before calling any method in the PIN code controller, it must be initialized:

```dart
final controller = PinCodeController();
await controller.initialize(); // <-- async initialization method
```

### Request Again Configuration

The controller handles app lifecycle changes. The only thing the developer must do is to
provide these changes when they happen. To do so, you can add the `WidgetsBindingObserver`
mixin somewhere in your app to override these methods: `initState`,
`didChangeAppLifecycleState`, `dispose`. You have to do 3 things:

1. Add an observer:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
}
```

2. Provide states to controller:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  controller.onAppLifecycleStateChanged(state);
  super.didChangeAppLifecycleState(state);
}
```

3. Dispose it:

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}
```

If you use the Request Again feature, you have to _always_ set the `onRequestAgain`
callback when your app starts and also _every time_ you set a new config in the controller.

For example, you can do it inside `initState` in your app's class:

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

When creating an instance of `PinCodeController`, pass the `logsEnabled` parameter equal
to `true`. It is helpful for debugging purposes as all events happening inside
the controller are covered with logs. Disabled by default.

```dart
final controller = PinCodeController(logsEnabled: true);
```

### Configure Timeouts

The timeout configuration class has 2 named constructors:
`PinCodeTimeoutConfig.notRefreshable` and `PinCodeTimeoutConfig.refreshable`.
The difference between these two is described in the [Timeouts section](#timeouts).

Both of these require a `timeouts` map configuration and a few callbacks
(`onTimeoutEnded`, `onTimeoutStarted` and `onMaxTimeoutsReached` for non-refreshable
configuration). The **map** contains the number of attempts (**value**) before every
timeout in seconds (**key**).

If all timeouts are non-refreshable and all are over, then `onMaxTimeoutsReached`
will be triggered.

If timeouts are refreshable and all are over, then the last **pair** (key, value)
will be used repeatedly, but the user will only get one attempt at a time.

Some more requirements:

- **Max duration is 6 hours** (21600 seconds).
- The **first** timeout duration is **always 0**!
- The **order is not important**, but it's easier to understand if you put timeouts
  in direct order. The important factor is timeout duration: a shorter timeout cannot
  be used after a longer one. It will always go one by one depending on the current
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

> **_NOTE:_** The **Timeouts** feature can only be **set in advance**, not
> while the app is already running.

### Configure Request Again

The Request Again configuration class constructor requires `secondsBeforeRequestingAgain`.
This main parameter determines how long the user can be in background without entering
the PIN code again after going to foreground.

If **0 seconds** is passed, it will require the PIN code every time.

The actual `onRequestAgain` callback, which is called when the configured time condition
is true, can be set later. But it must definitely be set before the very first
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

> **_NOTE:_** The **Request Again** feature can be configured both by the developer
> in advance and by the user at runtime in application settings if such a
> setting is presented.

### Configure Skip PIN

Skip PIN configuration requires the duration during which there will potentially be no
need to enter the PIN code.

Pay attention that you as a developer must handle it **manually** by checking
the `canSkipPinCodeNow` getter value.

The controller can only automatically handle skips for **Request Again** if you
set `forcedForRequestAgain` to `false` (enabled by default) in the configuration.

```dart
await controller.setSkipPinCodeConfig(
  SkipPinCodeConfig(
    duration: const Duration(minutes: 1),
    forcedForRequestAgain: false,
  ),
);
```

> **_NOTE:_** The **Skip PIN** feature can be configured both by the developer
> in advance and by the user at runtime in application settings if such a
> setting is presented.

### Setting PIN Code and Biometrics

To set PIN, use the **async** method `setPinCode`.

To set biometrics, use the **async** method `enableBiometricsIfAvailable`. It doesn't
require any parameters because the biometrics type is chosen automatically by the controller.

There is also a getter named `canSetBiometrics` to check if biometrics can be set
on the current device.

```dart
await controller.setPinCode(pinCodeTextEditingController.text);

if (controller.canSetBiometrics) {
  final biometricsType = await controller.enableBiometricsIfAvailable();
  // You can use biometricsType variable to display messages or determine
  // which icon (Face ID or Fingerprint) to show in UI
}
```

### Testing PIN Code and Biometrics

If PIN code is set, you can **test** (check if correct) it by calling the `testPinCode`
method. It will return `true` if it is correct and `false` if it is not.

The same goes for biometrics, but it is called `testBiometrics`.

There are also `canTestPinCode`, `isPinCodeSet` and `isBiometricsSet` which can be called
to check if it is set, if it can be tested at this moment, and so on.

```dart
if (pinCodeController.isTimeoutRunning) {
  return showToast('You must wait for timeout to end');
}
if (!await pinCodeController.canTestPinCode()) {
  return showToast('You can\'t test PIN code now');
}
final isPinCodeCorrect = await pinCodeController.testPinCode(pin);
if (isPinCodeCorrect) {
  // Navigate user to the next screen
} else {
  // Display error on screen or show toast
}
```

### Reacting to Events (Stream)

You may need to react to PIN code related events (such as successfully entered PIN,
newly set configuration, or timeout start) in the UI: updating the view, navigating, showing
a toast, etc. One way to implement this is by **listening to the stream** named
`eventsStream` from `PinCodeController`. You can find the list of all events that can be
emitted in this stream in the enum called `PinCodeEvents`.

```dart
final subscription = controller.eventsStream.listen((event) {
  // Update UI, make analytics record, or create custom logs here
});
```

### Exceptions

At runtime, if you do something wrong, an exception will be thrown. So it is better
to wrap some controller method calls in try-catch blocks and handle them properly.

You can see the list of all potential exceptions in `lib/src/exceptions`.

### Disposing

The PIN code controller has a `dispose` method which is meant to be called when you call
the dispose method in your view class.

```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

## Additional Information

### See Also: [pin_ui](https://pub.dev/packages/pin_ui)

The [pin_ui package](https://pub.dev/packages/pin_ui) provides 2 core widgets for
every PIN code screen: a highly customizable keyboard called `Pinpad` and `PinIndicator`
with tons of pre-made animations to use in one line of code.

<img src="https://raw.githubusercontent.com/AndreySosnovyy/flutter_pin_code_ui/refs/heads/assets/pinpad_pinindicator_demo.gif" alt="pin_ui demo" width="320"/>

**pin + pin_ui** are perfect to work together. Combining these two may
save you days of development and the result will already be perfect even out of
the box.

<p align="left">
<a href="https://pub.dev/packages/pin_ui"><img src="https://img.shields.io/pub/v/pin_ui.svg?style=flat&colorB=blue&label=pin_ui pub" alt="Pub"></a>
<a href="https://github.com/AndreySosnovyy/flutter_pin_code_ui"><img src="https://img.shields.io/github/stars/andreysosnovyy/flutter_pin_code_ui.svg?&style=flat&logo=github&color=red&label=pin_ui" alt="Star on Github"></a>
</p>

### Examples

This package has an [example](https://github.com/AndreySosnovyy/flutter_pin_code/tree/main/example)
project in it, covering main use cases you may want to try out. Feel free to use it
as a playground or a template for the PIN code feature core in your applications!

Also, there is a [more complete example project](https://github.com/AndreySosnovyy/flutter_pin_example)
that uses both **pin** and **pin_ui** packages.

You can [share your own examples](#contributing) for this section.

### Contributing

Have an interesting open source example to share with the community? Found a bug,
or want to suggest an idea for what feature to add next? You're always welcome!
Feel free to open
an [issue](https://github.com/AndreySosnovyy/flutter_pin_code/issues)
or [pull request](https://github.com/AndreySosnovyy/flutter_pin_code/pulls)
in the [GitHub repository](https://github.com/AndreySosnovyy/flutter_pin_code)!

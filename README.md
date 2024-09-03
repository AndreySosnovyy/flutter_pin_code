[//]: # (TODO: add image)

This package is here to bring easy use of Pin code feature and its related
sub-features.

Take attention that **flutter_pin_code** only provides controller for
handling all needed logic but not any UI-level classes, functions,
widgets or utils!

## Features

### Pin

The package takes responsibility of storing pin code and provides API for
working with it: testing, setting, removing, etc.

### Biometrics

This package uses features from [local_auth](https://pub.dev/packages/local_auth)
handling biometrics. Biometrics may only work on real devices! Using
PinCodeController you can check if biometrics is available on current device,
set it if so, test it, remove.

Also don't forget to [configure your app](#configuration-from-local_auth)
for using biometrics.

### Timeouts

Developer can set the configuration that will limit amount of attempts for user
to enter pin code if needed. By default, this amount is infinite.

There are two types of timeout configurations: refreshable and non-refreshable.
The first one also gives user ability to enter pin code infinite number of times,
but protecting from brute-force. The second one only gives user predetermined
number of attempts, and then it is meant to log them out automatically.

### Request Again

Request Again feature brings more protections for your app! </br>
It allows to preconfigure (set once be developer) or configure somewhere in
app settings (by user in runtime) rules that will request pin code again
after the app is being open from background.

### Skip Pin

This feature is here to make user experience more convenient and smooth.</br>
If you as a developer or user by himself (if you allow so) wants to set a
time in which there will be no need of entering pin code after doing it once,
there is also a special configuration for this case!

## Getting started

### Configuration from local_auth

In case you want to work with biometrics, you have to go through all the steps
to configure local_auth for [android](https://pub.dev/packages/local_auth#android-integration)
and [ios](https://pub.dev/packages/local_auth#ios-integration)! Otherwise, there
will be unexpected app behavior and crushes when you call biometrics-related methods.
Be sure to configure using guide for appropriate local_auth dependency version in 
flutter_pin_code (check in pubspec.yaml)!

### Controller initialization

Before calling any method in pin code controller, it must be initialized!</br>

### Request Again configuration

#### Set onAppLifeCycleStateChanged

Pin code controller handles app life cycle changes. The only thing developer
must do is to provide these changes when they happen. To do so you can add
`WidgetsBindingObserver` mixin to your app and override these 3 methods:
`initState`, `didChangeAppLifecycleState`, `dispose`. Where you have to do
3 things:

1) add observer:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
}
```

2) provide states to controller:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  myPinCodeController.onAppLifecycleStateChanged(state);
  super.didChangeAppLifecycleState(state);
}
```

3) dispose it:

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}
```

#### Reset callback

If you use this feature you have to always set onRequestAgain on app start
and everytime you set config in controller!</br>
You can do something like this in your app class:

```dart
@override
void initState() {
  super.initState();
  if (DI.pinCodeController.requestAgainConfig == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await myPinCodeController.setRequestAgainConfig(
        myPinCodeController.requestAgainConfig!
            .copyWith(onRequestAgain: requestAgainCallback));
  });
}
```

## Usage

### Logging

You can turn on logging while debugging when creating instance of `PinCodeController`
by providing `logsEnabled` parameter. Logs are disabled by default.

### Configuring

As mentioned before you can configure 3 different features in `PinCodeController`.
Two of them are configurable in runtime (means it can be both preset by developer or
by user if developer allow so in app settings or any other place): Request Again
and Skip Pin. Timeout feature can only be set in advance but not while app is
already running.

For every feature there are separate config class: `PinCodeRequestAgainConfig`,
`SkipPinCodeConfig` and `PinCodeTimeoutConfig`.

#### Timeouts

Timeout configuration class has 2 named constructors: `PinCodeTimeoutConfig.notRefreshable`
and `PinCodeTimeoutConfig.refreshable`. Difference between these two described in
[introduction section](#timeouts).

Both of these requires `timeouts` map configuration and some other documented callbacks.
Map containing number of tries before every timeout where key is number of seconds
and value is number of tries. If all timeouts are over, and they are not refreshable,
then onMaxTimeoutsReached will be called. If timeouts are refreshable and the
last configured timeout is over, user will get one attempt at a time.
This logic will repeat infinitely!

Some more requirements:

- Max value is 21600 seconds (6 hours).
- The first timeout duration is always 0!
- The order is not important, but it's easier to understand if you put timeouts
  in direct order. The important factor is timeout duration:
  shorter timeout can not be used after a longer one. It will always go one by one
  depending on current timeout duration starting from 0.

Example: </br>
{ </br>
&nbsp;&nbsp;&nbsp;&nbsp;0: 3, // initially you have 3 tries before falling into 60 seconds timeout </br>
&nbsp;&nbsp;&nbsp;&nbsp;60: 2, // another 2 tries after 60 seconds timeout </br>
&nbsp;&nbsp;&nbsp;&nbsp;600: 1, // another try after 600 seconds timeout </br>
}

#### Request Again

Request Again configuration class constructor requires `secondsBeforeRequestingAgain`.
This main parameter determines how long user can be in background without entering
pin code again after going to foreground.

If 0 seconds provided, it will require pin code every time.

Actual `onRequestAgain` callback (which is called when configured time condition
is true) can be set later after. But it must be for sure set before very first
potential Request Again call.

#### Skip Pin

Skip Pin configuration requires duration in which potentially there will be no
need to enter pin code.

Take attention that you as a developer must handle it manually by checking
`canSkipPinCodeNow` getter. Controller can only automatically handle skips in while
Requesting Again if you set `forcedForRequestAgain` to false (true by default)
in configuration.

### Testing

If previously you have set pin and maybe event biometrics you can test them using
async methods `testPinCode` and `testBiometrics`. They return `true` if test was
successful and `false` in any other case.
You may also want to check if testing is available at the moment. It is possible
by checking via `canTestPinCode` method or other getters from `PinCodeController` class.

### Reacting to events (stream)

You may need to react to pin code related events (such as successfully entered pin,
newly set configuration or timeout start) for UI part of the app: updating view,
navigation, showing toast, etc. One way for implementing that is by listening to
stream named `eventsStream` in `PinCodeController`. You can find the list of all
events can be thrown in this stream in `PinCodeEvents` enum.

### Exceptions

In runtime if you do something wrong and exception will be thrown. So it is better
to wrap calling some controller methods in try-catch blocks and handle them properly.

You can see the list of all potential exceptions in lib/src/exceptions.

### Disposing

Pin code controller has `dispose` method which is meant to be called when you call
dispose method in view class.

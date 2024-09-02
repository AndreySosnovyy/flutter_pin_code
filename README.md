[//]: # (TODO: add image)

[//]: # (TODO: short introduction)
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
handling biometrics. Using PinCodeController you can check if biometrics is
available on current device, set it if so, test it, remove.

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

### Controller initialization

Before calling any method in pin code controller, it must be initialized!</br>
When initializing you can provide 2 reasons in String format in case you use
biometrics. These strings will be used when calling local_auth methods.

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

### Disposing

Pin code controller has `dispose` method which is meant to be called when you call
dispose method in view class.

## Usage

### Configuring

### Testing

### Exceptions

## Ending

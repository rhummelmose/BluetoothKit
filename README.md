# BluetoothKit
Easily communicate between iOS devices using BLE.

[![Build Status](https://travis-ci.org/rhummelmose/BluetoothKit.svg?branch=master)](https://travis-ci.org/rhummelmose/BluetoothKit)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/BluetoothKit.svg)](https://img.shields.io/cocoapods/v/BluetoothKit.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

##Background
Apple mostly did a great job with the CoreBluetooth API, but because it encapsulated the entire Bluetooth 4.0 LE specification, it can be a lot of work to achieve simple tasks like sending data back and forth between iOS devices, without having to worry about the specification and the inner workings of the CoreBluetooth stack.

BluetoothKit tries to address the challenges this may cause by providing a much simpler, modern, closure-based API all implemented in Swift.

##Features

####Common
- More concise Bluetooth LE availability definition with enums.
- Bluetooth LE availability observation allowing multiple observers at once.

####Central
- Scan for remote peripherals for a given time interval.
- Continuously scan for remote peripherals for a give time interval, with an in-between delay until interrupted.
- Connect to remote peripherals with a given time interval as time out.
- Receive any size of data without having to worry about chunking.

####Peripheral
- Start broadcasting with only a single function call.
- Send any size of data to connected remote centrals without having to worry about chunking.

## Requirements
- iOS 8.0+ / OSX 10.10+
- Xcode 7.0+

## Installation

####CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

CocoaPods 0.38.2 is required to build BluetoothKit. It adds support for Xcode 7, Swift 2.0 and embedded frameworks. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate BluetoothKit into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'BluetoothKit', '~> 0.2.0'
```

Then, run the following command:

```bash
$ pod install
```

####Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate BluetoothKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "rasmusth/BluetoothKit" ~> 0.4.0
```

####Manual
Add the BluetoothKit project to your existing project and add BluetoothKit as an embedded binary of your target(s).

##Usage

Below you find some examples of how the framework can be used. Accompanied in the repository you find an example project that demonstrates a usage of the framework in practice. The example project uses [SnapKit](https://github.com/SnapKit/SnapKit) and [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) both of which are great projects. They're bundled in the project and it should all build without further ado.

####Common
Make sure to import the BluetoothKit framework in files that use it.
```swift
import BluetoothKit
```

####Peripheral

Prepare and start a BKPeripheral object with a configuration holding UUIDs uniqueue to your app(s) and an optional local name that will be broadcasted. You can generate UUIDs in the OSX terminal using the command "uuidgen".
```swift
let peripheral = BKPeripheral()
peripheral.delegate = self
do {
	let serviceUUID = NSUUID(UUIDString: "6E6B5C64-FAF7-40AE-9C21-D4933AF45B23")!
	let characteristicUUID = NSUUID(UUIDString: "477A2967-1FAB-4DC5-920A-DEE5DE685A3D")!
	let localName = "My Cool Peripheral"
	let configuration = BKPeripheralConfiguration(dataServiceUUID: serviceUUID, dataServiceCharacteristicUUID: 	characteristicUUID, localName: localName)
	try peripheral.startWithConfiguration(configuration)
	// You are now ready for incoming connections
} catch let error {
	// Handle error.
}
```

Send data to a connected remote central.
```swift
let data = "Hello beloved central!".dataUsingEncoding(NSUTF8StringEncoding)
let remoteCentral = peripheral.connectedRemoteCentrals.first! // Don't do this in the real world :]
peripheral.sendData(data, toRemoteCentral: remoteCentral) { data, remoteCentral, error in
	// Handle error.
	// If no error, the data was all sent!
}
```

####Central
Prepare and start a BKCentral object with a configuration holding the UUIDs you used to configure your BKPeripheral object.
```swift
let central = BKCentral()
central.delegate = self
central.addAvailabilityObserver(self)
do {
	let serviceUUID = NSUUID(UUIDString: "6E6B5C64-FAF7-40AE-9C21-D4933AF45B23")!
	let characteristicUUID = NSUUID(UUIDString: "477A2967-1FAB-4DC5-920A-DEE5DE685A3D")!
	let configuration = BKConfiguration(dataServiceUUID: serviceUUID, dataServiceCharacteristicUUID: characteristicUUID)
	try central.startWithConfiguration(configuration: configuration)
	// Once the availability observer has been positively notified, you're ready to discover and connect to peripherals.
} catch let error {
	// Handle error.
}
```

Scan for peripherals for 3 seconds.
```swift
central.scanWithDuration(3, progressHandler: { newDiscoveries in
	// Handle newDiscoveries, [BKDiscovery].
}, completionHandler: { result, error in
	// Handle error.
	// If no error, handle result, [BKDiscovery].
})
```

Scan continuously for 3 seconds at a time, with an in-between delay of 3 seconds.
```swift
central.scanContinuouslyWithChangeHandler({ changes, discoveries in
	// Handle changes to "availabile" discoveries, [BKDiscoveriesChange].
	// Handle current "available" discoveries, [BKDiscovery].
	// This is where you'd ie. update a table view.
}, stateHandler: { newState in
	// Handle newState, BKCentral.ContinuousScanState.
	// This is where you'd ie. start/stop an activity indicator.
}, duration: 3, inBetweenDelay: 3, errorHandler: { error in
	// Handle error.
})
```

Connect a peripheral with a connection attempt timeout of 3 seconds.
```swift
central.connect(remotePeripheral: peripherals[indexPath.row]) { remotePeripheral, error in
	// Handle error.
	// If no error, you're ready to receive data!
}
```

##License
BluetoothKit is released under the MIT License.

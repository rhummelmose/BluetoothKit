# BluetoothKit
Easily communicate between iOS devices using BLE.

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

## Installation

####Cocoapods
Coming soon.

####Carthage
Coming soon.

####Manual
Add the BluetoothKit project to your existing project and add BluetoothKit as an embedded binary of your target(s).

##Usage

Below you find some examples of how the framework can be used. Accompanied in the repository you find an example project that demonstrates a usage of the framework in practice. The example project uses [SnapKit](https://github.com/SnapKit/SnapKit) and [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) both of which are great projects. They're bundled in the project and it should all build without further ado.

####Common
Make sure to import the BluetoothKit framework in files that use it.
```swift
import BluetoothKit
```

####Central
Prepare and start a BKCentral object.
```swift
let central = BKCentral()
central.delegate = self
do {
	try central.start()
	// You are now ready to discover and connect to peripherals.
} catch let error {
	// Handle error.
}
```

Scan for peripherals for 3 seconds.
```swift
central.scanWithDuration(3, progressHandler: { newDiscoveries in
	// Handle newDiscoveries, [RemotePeripheral].
}, completionHandler: { result, error in
	// Handle error.
	// If no error, handle result, [RemotePeripheral].
})
```

Scan continuously for 3 seconds at a time, with an in-between delay of 3 seconds.
```swift
central.scanContinuouslyWithChangeHandler({ changes, peripherals in
	// Handle changes to "availabile" peripherals, [BKScanChange].
	// Handle current "available" peripherals, [BKRemotePeripheral].
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

####Peripheral

Prepare and start a BKPeripheral object.
```swift
let peripheral = BKPeripheral()
peripheral.delegate = self
do {
	try peripheral.startWithName("Lovely Peripheral")
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

##License
BluetoothKit is released under the MIT License.

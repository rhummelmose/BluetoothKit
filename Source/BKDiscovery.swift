//
//  BluetoothKit
//
//  Copyright (c) 2015 Rasmus Taulborg Hummelmose - https://github.com/rasmusth
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import CoreBluetooth

public func == (lhs: BKDiscovery, rhs: BKDiscovery) -> Bool {
    return lhs.remotePeripheral == rhs.remotePeripheral
}

/**
    A discovery made while scanning, containing a peripheral, the advertisement data and RSSI.
*/
public struct BKDiscovery: Equatable {

    // MARK: Properties

    /// The advertised name derived from the advertisement data.
    public var localName: String? {
        return advertisementData[CBAdvertisementDataLocalNameKey] as? String
    }

    /// The data advertised while the discovery was made.
    public let advertisementData: [String: Any]

    /// The remote peripheral that was discovered.
    public let remotePeripheral: BKRemotePeripheral

    /// The [RSSI (Received signal strength indication)](https://en.wikipedia.org/wiki/Received_signal_strength_indication) value when the discovery was made.
    public let RSSI: Int

    // MARK: Initialization

    public init(advertisementData: [String: Any], remotePeripheral: BKRemotePeripheral, RSSI: Int) {
        self.advertisementData = advertisementData
        self.remotePeripheral = remotePeripheral
        self.RSSI = RSSI
    }

}

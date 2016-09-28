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

import Foundation
import CoreBluetooth

internal protocol BKCBPeripheralDelegate: class {
    func peripheralDidUpdateName(_ peripheral: CBPeripheral)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: NSError?)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
}

internal class BKCBPeripheralDelegateProxy: NSObject, CBPeripheralDelegate {

    // MARK: Properties

    internal weak var delegate: BKCBPeripheralDelegate?

    // MARK: Initialization

    internal init(delegate: BKCBPeripheralDelegate) {
        self.delegate = delegate
    }

    // MARK: CBPeripheralDelegate

    internal func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        // print("peripheralDidUpdateName: \(peripheral)")
        delegate?.peripheralDidUpdateName(peripheral)
    }

    internal func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        // print("peripheral: \(peripheral) didModifyServices invalidatedServices: \(invalidatedServices)")
    }

    internal func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: NSError?) {
        // print("peripheralDidUpdateRSSI: \(peripheral), error: \(error)")
    }

    internal func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        // print("peripheral: \(peripheral) didReadRSSI: \(RSSI), error: \(error)")
    }

    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        // print("peripheral: \(peripheral) didDiscoverServices error: \(error)")
        delegate?.peripheral(peripheral, didDiscoverServices: error)
    }

    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: NSError?) {
        // print("peripheral: \(peripheral) didDiscoverIncludedServicesForService: \(service), error: \(error)")
    }

    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: NSError?) {
        // print("peripheral: \(peripheral) didDiscoverCharacteristicsForService: \(service), error: \(error)")
        delegate?.peripheral(peripheral, didDiscoverCharacteristicsForService: service, error: error)
    }

    internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: NSError?) {
        // print("peripheral: \(peripheral) didUpdateValueForCharacteristic: \(characteristic), error: \(error)")
        delegate?.peripheral(peripheral, didUpdateValueForCharacteristic: characteristic, error: error)
    }

    internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: NSError?) {
        // print("peripheral: \(peripheral), didWriteValueForCharacteristic: \(characteristic), error: \(error)")
    }

    internal func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: NSError?) {
        // print("peripheral: \(peripheral) didUpdateNotificationStateForCharacteristic: \(characteristic), error: \(error)")
    }

    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: NSError?) {
        // print("peripheral: \(peripheral) didDiscoverDescriptorsForCharacteristic: \(characteristic), error: \(error)")
    }

    @nonobjc
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: NSError?) {
        // print("peripheral: \(peripheral) didUpdateValueForDescriptor: \(descriptor), error: \(error)")
    }

    @nonobjc
    internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: NSError?) {
        // print("peripheral: \(peripheral) didWriteValueForDescriptor: \(descriptor), error: \(error)")
    }

}

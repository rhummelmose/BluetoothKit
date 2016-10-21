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

internal protocol BKCBPeripheralManagerDelegate: class {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?)
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?)
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic)
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic)
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest])
    func peripheralManagerIsReadyToUpdateSubscribers(_ peripheral: CBPeripheralManager)
}

internal class BKCBPeripheralManagerDelegateProxy: NSObject, CBPeripheralManagerDelegate {

    // MARK: Properties

    internal weak var delegate: BKCBPeripheralManagerDelegate?

    // MARK: Initialization

    internal init(delegate: BKCBPeripheralManagerDelegate) {
        self.delegate = delegate
    }

    // MARK: CBPeripheralManagerDelegate

    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
//         print("peripheralManagerDidUpdateState: \(peripheral)")
        delegate?.peripheralManagerDidUpdateState(peripheral)
    }

    internal func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
//         print("peripheralManagerDidStartAdvertising: \(peripheral) error: \(error)")
        delegate?.peripheralManagerDidStartAdvertising(peripheral, error: error)
    }

    internal func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
//         print("peripheralManager: \(peripheral) didAddService: \(service) error: \(error)")
        delegate?.peripheralManager(peripheral, didAdd: service, error: error)
    }

    internal func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
//         print("peripheralManager: \(peripheral) central: \(central) didSubscribeToCharacteristic: \(characteristic)")
        delegate?.peripheralManager(peripheral, central: central, didSubscribeToCharacteristic: characteristic)
    }

    internal func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
//         print("peripheralManager: \(peripheral) central: \(central) didUnsubscribeFromCharacteristic: \(characteristic)")
        delegate?.peripheralManager(peripheral, central: central, didUnsubscribeFromCharacteristic: characteristic)
    }

    internal func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
//         print("peripheralManager: \(peripheral) didReceiveReadRequest: \(request)")
    }

    internal func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
//         print("peripheralManager: \(peripheral) didReceiveWriteRequests: \(requests)")
        delegate?.peripheralManager(peripheral, didReceiveWriteRequests: requests)
    }

    internal func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
//         print("peripheralManagerIsReadyToUpdateSubscribers: \(peripheral)")
        delegate?.peripheralManagerIsReadyToUpdateSubscribers(peripheral)
    }

}

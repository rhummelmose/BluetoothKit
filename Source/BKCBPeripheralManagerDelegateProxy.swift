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
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager)
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?)
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?)
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic)
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic)
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager)
}

internal class BKCBPeripheralManagerDelegateProxy: NSObject, CBPeripheralManagerDelegate {
    
    // MARK: Properties
    
    internal weak var delegate: BKCBPeripheralManagerDelegate?
    
    // MARK: Initialization
    
    internal init(delegate: BKCBPeripheralManagerDelegate) {
        self.delegate = delegate
    }
    
    // MARK: CBPeripheralManagerDelegate
    
    internal func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        // print("peripheralManagerDidUpdateState: \(peripheral)")
        delegate?.peripheralManagerDidUpdateState(peripheral)
    }
    
    internal func peripheralManager(peripheral: CBPeripheralManager, willRestoreState dict: [String : AnyObject]) {
        // print("peripheralManager: \(peripheral) willRestoreState: \(dict)")
    }
    
    internal func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        // print("peripheralManagerDidStartAdvertising: \(peripheral) error: \(error)")
        delegate?.peripheralManagerDidStartAdvertising(peripheral, error: error)
    }
    
    internal func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        // print("peripheralManager: \(peripheral) didAddService: \(service) error: \(error)")
        delegate?.peripheralManager(peripheral, didAddService: service, error: error)
    }
    
    internal func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        // print("peripheralManager: \(peripheral) central: \(central) didSubscribeToCharacteristic: \(characteristic)")
        delegate?.peripheralManager(peripheral, central: central, didSubscribeToCharacteristic: characteristic)
    }
    
    internal func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        // print("peripheralManager: \(peripheral) central: \(central) didUnsubscribeFromCharacteristic: \(characteristic)")
        delegate?.peripheralManager(peripheral, central: central, didUnsubscribeFromCharacteristic: characteristic)
    }
    
    internal func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        // print("peripheralManager: \(peripheral) didReceiveReadRequest: \(request)")
    }
    
    internal func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        // print("peripheralManager: \(peripheral) didReceiveWriteRequests: \(requests)")
    }
    
    internal func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        // print("peripheralManagerIsReadyToUpdateSubscribers: \(peripheral)")
        delegate?.peripheralManagerIsReadyToUpdateSubscribers(peripheral)
    }
    
}

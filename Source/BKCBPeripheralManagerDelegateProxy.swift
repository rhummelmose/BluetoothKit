//
//  BKCBPeripheralManagerDelegateProxy.swift
//  BluetoothKit
//
//  Created by Rasmus Taulborg Hummelmose on 25/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
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
    
    // MARK: Initializer
    
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

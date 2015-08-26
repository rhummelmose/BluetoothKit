//
//  BKCBPeripheralDelegateProxy.swift
//  CustomerFacingDisplay
//
//  Created by Rasmus Taulborg Hummelmose on 21/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation
import CoreBluetooth

internal protocol BKCBPeripheralDelegate: class {
    func peripheralDidUpdateName(peripheral: CBPeripheral)
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?)
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?)
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
}

internal class BKCBPeripheralDelegateProxy: NSObject, CBPeripheralDelegate {
    
    // MARK: Internal
    
    internal weak var delegate: BKCBPeripheralDelegate?
    
    internal init(delegate: BKCBPeripheralDelegate) {
        self.delegate = delegate
    }
    
    // MARK: CBPeripheralDelegate
    
    internal func peripheralDidUpdateName(peripheral: CBPeripheral) {
        // print("peripheralDidUpdateName: \(peripheral)")
        delegate?.peripheralDidUpdateName(peripheral)
    }
    
    internal func peripheral(peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        // print("peripheral: \(peripheral) didModifyServices invalidatedServices: \(invalidatedServices)")
    }
    
    internal func peripheralDidUpdateRSSI(peripheral: CBPeripheral, error: NSError?) {
        // print("peripheralDidUpdateRSSI: \(peripheral), error: \(error)")
    }
    
    internal func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        // print("peripheral: \(peripheral) didReadRSSI: \(RSSI), error: \(error)")
    }
    
    internal func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        // print("peripheral: \(peripheral) didDiscoverServices error: \(error)")
        delegate?.peripheral(peripheral, didDiscoverServices: error)
    }
    
    internal func peripheral(peripheral: CBPeripheral, didDiscoverIncludedServicesForService service: CBService, error: NSError?) {
        // print("peripheral: \(peripheral) didDiscoverIncludedServicesForService: \(service), error: \(error)")
    }
    
    internal func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        // print("peripheral: \(peripheral) didDiscoverCharacteristicsForService: \(service), error: \(error)")
        delegate?.peripheral(peripheral, didDiscoverCharacteristicsForService: service, error: error)
    }
    
    internal func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        // print("peripheral: \(peripheral) didUpdateValueForCharacteristic: \(characteristic), error: \(error)")
        delegate?.peripheral(peripheral, didUpdateValueForCharacteristic: characteristic, error: error)
    }
    
    internal func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        // print("peripheral: \(peripheral), didWriteValueForCharacteristic: \(characteristic), error: \(error)")
    }
    
    internal func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        // print("peripheral: \(peripheral) didUpdateNotificationStateForCharacteristic: \(characteristic), error: \(error)")
    }
    
    internal func peripheral(peripheral: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        // print("peripheral: \(peripheral) didDiscoverDescriptorsForCharacteristic: \(characteristic), error: \(error)")
    }
    
    internal func peripheral(peripheral: CBPeripheral, didUpdateValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        // print("peripheral: \(peripheral) didUpdateValueForDescriptor: \(descriptor), error: \(error)")
    }
    
    internal func peripheral(peripheral: CBPeripheral, didWriteValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        // print("peripheral: \(peripheral) didWriteValueForDescriptor: \(descriptor), error: \(error)")
    }
    
}

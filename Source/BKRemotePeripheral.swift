//
//  BKRemotePeripheral.swift
//  CustomerFacingDisplay
//
//  Created by Rasmus Taulborg Hummelmose on 18/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol BKRemotePeripheralDelegate: class {
    func remotePeripheral(remotePeripheral: BKRemotePeripheral, didUpdateName name: String)
    func remotePeripheral(remotePeripheral: BKRemotePeripheral, didReceiveArbitraryData data: NSData)
    // func remotePeripheral(remotePeripheral: BKRemotePeripheral, didReceiveEncodedObject encodedObject: NSCoding, withClassName className: String)
}

public func ==(lhs: BKRemotePeripheral, rhs: BKRemotePeripheral) -> Bool {
    return lhs.identifier.UUIDString == rhs.identifier.UUIDString
}

public class BKRemotePeripheral: BKCBPeripheralDelegate, Equatable {
    
    // MARK: Enums
    
    public enum State {
        case Shallow, Disconnected, Connecting, Connected, Disconnecting
    }
    
    // MARK: Initialization
    
    public init(identifier: NSUUID, peripheral: CBPeripheral?) {
        self.identifier = identifier
        self.peripheralDelegate = BKCBPeripheralDelegateProxy(delegate: self)
        self.peripheral = peripheral
        self.peripheral?.delegate = peripheralDelegate
    }
    
    // MARK: Properties
    
    public weak var delegate: BKRemotePeripheralDelegate?
    public let identifier: NSUUID
    
    public var state: State {
        if peripheral == nil {
            return .Shallow
        }
        switch peripheral!.state {
            case .Disconnected: return .Disconnected
            case .Connecting: return .Connecting
            case .Connected: return .Connected
            case .Disconnecting: return .Disconnecting
        }
    }
    
    public var name: String? {
        return peripheral?.name
    }
    
    internal var peripheral: CBPeripheral? {
        didSet {
            peripheral?.delegate = peripheralDelegate
        }
    }
    
    // MARK: Internal Functions
    
    internal func discoverServices() {
        if peripheral?.services != nil {
            peripheral(peripheral!, didDiscoverServices: nil)
            return
        }
        peripheral?.discoverServices([ CBUUID(string: BKService.DataTransferService.rawValue) ])
    }
    
    // MARK: BKCBPeripheralDelegate
    
    internal func peripheralDidUpdateName(peripheral: CBPeripheral) {
        delegate?.remotePeripheral(self, didUpdateName: name!)
    }
    
    internal func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let services = peripheral.services {
            for service in services {
                if service.characteristics != nil {
                    self.peripheral(peripheral, didDiscoverCharacteristicsForService: service, error: nil)
                    return
                }
                if let knownService = BKService(rawValue: service.UUID.UUIDString) {
                    peripheral.discoverCharacteristics(knownService.characteristicIdentifiers, forService: service)
                }
            }
        }
    }
    
    internal func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for characteristic in service.characteristics as [CBCharacteristic]! {
            peripheral.setNotifyValue(true, forCharacteristic: characteristic)
        }
    }
    
    internal func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let knownCharacteristic = BKService.Characteristic(rawValue: characteristic.UUID.UUIDString) {
            switch knownCharacteristic {
                case .Data: handleReceivedData(characteristic.value!)
            }
        }
    }
    
    // MARK: Private
    
    private var data: NSMutableData?
    private var peripheralDelegate: BKCBPeripheralDelegateProxy!
    
    private func handleReceivedData(receivedData: NSData) {
        if receivedData.isEqualToData(BKService.endOfDataMark) {
            if let finalData = data {
                delegate?.remotePeripheral(self, didReceiveArbitraryData: finalData)
            }
            data = nil
            return
        }
        if let existingData = data {
            existingData.appendData(receivedData)
            return
        }
        data = NSMutableData(data: receivedData)
    }
    
}

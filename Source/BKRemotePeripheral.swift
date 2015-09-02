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

public protocol BKRemotePeripheralDelegate: class {
    func remotePeripheral(remotePeripheral: BKRemotePeripheral, didUpdateName name: String)
    func remotePeripheral(remotePeripheral: BKRemotePeripheral, didReceiveArbitraryData data: NSData)
}

public func ==(lhs: BKRemotePeripheral, rhs: BKRemotePeripheral) -> Bool {
    return lhs.identifier.UUIDString == rhs.identifier.UUIDString
}

public class BKRemotePeripheral: BKCBPeripheralDelegate, Equatable {
    
    // MARK: Enums
    
    public enum State {
        case Shallow, Disconnected, Connecting, Connected, Disconnecting
    }
    
    // MARK: Properties
    
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
    
    public weak var delegate: BKRemotePeripheralDelegate?
    public let identifier: NSUUID
    
    internal var peripheral: CBPeripheral?
    private var data: NSMutableData?
    private var peripheralDelegate: BKCBPeripheralDelegateProxy!
    
    // MARK: Initialization
    
    public init(identifier: NSUUID, peripheral: CBPeripheral?) {
        self.identifier = identifier
        self.peripheralDelegate = BKCBPeripheralDelegateProxy(delegate: self)
        self.peripheral = peripheral
    }
    
    // MARK: Internal Functions
    
    internal func prepareForConnection() {
        peripheral?.delegate = peripheralDelegate
    }
    
    internal func discoverServices() {
        if peripheral?.services != nil {
            peripheral(peripheral!, didDiscoverServices: nil)
            return
        }
        peripheral?.discoverServices([ CBUUID(string: BKService.DataTransferService.rawValue) ])
    }
    
    internal func unsubscribe() {
        guard peripheral?.services != nil else {
            return
        }
        for service in peripheral!.services! {
            guard service.characteristics != nil else {
                continue
            }
            for characteristic in service.characteristics! {
                peripheral?.setNotifyValue(false, forCharacteristic: characteristic)
            }
        }
    }
    
    // MARK: Private Functions
    
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
    
}

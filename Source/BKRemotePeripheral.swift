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

/**
    The delegate of a remote peripheral receives callbacks when asynchronous events occur.
*/
public protocol BKRemotePeripheralDelegate: class {
    /**
        Called when the remote peripheral updated its name.
        - parameter remotePeripheral: The remote peripheral that updated its name.
        - parameter name: The new name.
    */
    func remotePeripheral(remotePeripheral: BKRemotePeripheral, didUpdateName name: String)
}

/**
    Class to represent a remote peripheral that can be connected to by BKCentral objects.
*/
public class BKRemotePeripheral: BKRemotePeer, BKCBPeripheralDelegate {
    
    // MARK: Enums
    
    /**
        Possible states for BKRemotePeripheral objects.
        - Shallow: The peripheral was initialized only with an identifier (used when one wants to connect to a peripheral for which the identifier is known in advance).
        - Disconnected: The peripheral is disconnected.
        - Connecting: The peripheral is currently connecting.
        - Connected: The peripheral is already connected.
        - Disconnecting: The peripheral is currently disconnecting.
    */
    public enum State {
        case Shallow, Disconnected, Connecting, Connected, Disconnecting
    }
    
    // MARK: Properties
    
    /// The current state of the remote peripheral, either shallow or derived from an underlying CBPeripheral object.
    public var state: State {
        if peripheral == nil {
            return .Shallow
        }
        #if os(iOS) || os(tvOS)
        switch peripheral!.state {
            case .Disconnected: return .Disconnected
            case .Connecting: return .Connecting
            case .Connected: return .Connected
            case .Disconnecting: return .Disconnecting
        }
        #else
        switch peripheral!.state {
            case .Disconnected: return .Disconnected
            case .Connecting: return .Connecting
            case .Connected: return .Connected
        }
        #endif
    }
    
    /// The name of the remote peripheral, derived from an underlying CBPeripheral object.
    public var name: String? {
        return peripheral?.name
    }
    
    /// The remote peripheral's delegate.
    public weak var peripheralDelegate: BKRemotePeripheralDelegate?
    
    override internal var maximumUpdateValueLength: Int {
        guard #available(iOS 9, *), let peripheral = peripheral else {
            return super.maximumUpdateValueLength
        }
        #if os(OSX)
            return super.maximumUpdateValueLength
        #else
            return peripheral.maximumWriteValueLengthForType(.WithoutResponse)
        #endif
    }
    
    internal var characteristicData: CBCharacteristic?
    internal var peripheral: CBPeripheral?
    
    private var peripheralDelegateProxy: BKCBPeripheralDelegateProxy!
    
    // MARK: Initialization
    
    public init(identifier: NSUUID, peripheral: CBPeripheral?) {
        super.init(identifier: identifier)
        self.peripheralDelegateProxy = BKCBPeripheralDelegateProxy(delegate: self)
        self.peripheral = peripheral
    }
    
    // MARK: Internal Functions
    
    internal func prepareForConnection() {
        peripheral?.delegate = peripheralDelegateProxy
    }
    
    internal func discoverServices() {
        if peripheral?.services != nil {
            peripheral(peripheral!, didDiscoverServices: nil)
            return
        }
        peripheral?.discoverServices(configuration!.serviceUUIDs)
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
    
    // MARK: BKCBPeripheralDelegate
    
    internal func peripheralDidUpdateName(peripheral: CBPeripheral) {
        peripheralDelegate?.remotePeripheral(self, didUpdateName: name!)
    }
    
    internal func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let services = peripheral.services {
            for service in services {
                if service.characteristics != nil {
                    self.peripheral(peripheral, didDiscoverCharacteristicsForService: service, error: nil)
                } else  {
                    peripheral.discoverCharacteristics(configuration!.characteristicUUIDsForServiceUUID(service.UUID), forService: service)
                }
            }
        }
    }
    
    internal func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if service.UUID == configuration!.dataServiceUUID {
            if let dataCharacteristic = service.characteristics?.filter({ $0.UUID == configuration!.dataServiceCharacteristicUUID }).last {
                characteristicData = dataCharacteristic
                peripheral.setNotifyValue(true, forCharacteristic: dataCharacteristic)
            }
        }
        // TODO: Consider what to do with characteristics from additional services.
    }
    
    internal func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if characteristic.UUID == configuration!.dataServiceCharacteristicUUID {
            handleReceivedData(characteristic.value!)
        }
        // TODO: Consider what to do with new values for characteristics from additional services.
    }
    
}

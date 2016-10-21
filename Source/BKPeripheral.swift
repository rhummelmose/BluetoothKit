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
    The peripheral's delegate is called when asynchronous events occur.
*/

public protocol BKPeripheralDelegate: class {
    /**
        Called when a remote central connects and is ready to receive data.
        - parameter peripheral: The peripheral object to which the remote central connected.
        - parameter remoteCentral: The remote central that connected.
    */
    func peripheral(_ peripheral: BKPeripheral, remoteCentralDidConnect remoteCentral: BKRemoteCentral)
    /**
        Called when a remote central disconnects and can no longer receive data.
        - parameter peripheral: The peripheral object from which the remote central disconnected.
        - parameter remoteCentral: The remote central that disconnected.
    */
    func peripheral(_ peripheral: BKPeripheral, remoteCentralDidDisconnect remoteCentral: BKRemoteCentral)
}

/**
    The class used to take the Bluetooth LE peripheral role. Peripherals can be discovered and connected to by centrals.
    One a central has connected, the peripheral can send data to it.
*/

public class BKPeripheral: BKPeer, BKCBPeripheralManagerDelegate, BKAvailabilityObservable {

    // MARK: Properies

    /// Bluetooth LE availability derived from the underlying CBPeripheralManager object.

    public var availability: BKAvailability {
        #if os(iOS) || os(tvOS)
            if #available(iOS 10.0, tvOS 10.0, *) {
                return BKAvailability(managerState: peripheralManager.state)
            } else {
                return BKAvailability(peripheralManagerState: peripheralManager.peripheralManagerState)
            }
        #else
            return BKAvailability(peripheralManagerState: peripheralManager.state)
        #endif
    }



    /// The configuration that the BKPeripheral object was started with.
    override public var configuration: BKPeripheralConfiguration? {
        return _configuration
    }

    /// The BKPeriheral object's delegate.
    public weak var delegate: BKPeripheralDelegate?

    /// Current availability observers
    public var availabilityObservers = [BKWeakAvailabilityObserver]()

    /// Currently connected remote centrals
    public var connectedRemoteCentrals: [BKRemoteCentral] {
        return connectedRemotePeers.flatMap({
            guard let remoteCentral = $0 as? BKRemoteCentral else {
                return nil
            }
            return remoteCentral
        })
    }

    private var _configuration: BKPeripheralConfiguration!
    private var peripheralManager: CBPeripheralManager!
    private let stateMachine = BKPeripheralStateMachine()
    private var peripheralManagerDelegate: BKCBPeripheralManagerDelegateProxy!
    private var characteristicData: CBMutableCharacteristic!
    private var dataService: CBMutableService!

    // MARK: Initialization

    public override init() {
        super.init()
        peripheralManagerDelegate = BKCBPeripheralManagerDelegateProxy(delegate: self)
    }

    // MARK: Public Functions

    /**
        Starts the BKPeripheral object. Once started the peripheral will be discoverable and possible to connect to
        by remote centrals, provided that Bluetooth LE is available.
        - parameter configuration: A configuration defining the unique identifiers along with the name to be broadcasted.
        - throws: An internal error if the BKPeripheral object was already started.
    */
    public func startWithConfiguration(_ configuration: BKPeripheralConfiguration) throws {
        do {
            try stateMachine.handleEvent(event: .start)
            _configuration = configuration
            peripheralManager = CBPeripheralManager(delegate: peripheralManagerDelegate, queue: nil, options: nil)
        } catch let error {
            throw BKError.internalError(underlyingError: error)
        }
    }

    /**
        Stops the BKPeripheral object.
        - throws: An internal error if the peripheral object wasn't started.
    */
    public func stop() throws {
        do {
            try stateMachine.handleEvent(event: .stop)
            _configuration = nil
            if peripheralManager.isAdvertising {
                peripheralManager.stopAdvertising()
            }
            peripheralManager.removeAllServices()
            peripheralManager = nil
        } catch let error {
            throw BKError.internalError(underlyingError: error)
        }
    }

    // MARK: Private Functions

    private func setUnavailable(_ cause: BKUnavailabilityCause, oldCause: BKUnavailabilityCause?) {
        if oldCause == nil {
            for remotePeer in connectedRemotePeers {
                if let remoteCentral = remotePeer as? BKRemoteCentral {
                    handleDisconnectForRemoteCentral(remoteCentral)
                }
            }
            for availabilityObserver in availabilityObservers {
                availabilityObserver.availabilityObserver?.availabilityObserver(self, availabilityDidChange: .unavailable(cause: cause))
            }
        } else if oldCause != nil && oldCause != cause {
            for availabilityObserver in availabilityObservers {
                availabilityObserver.availabilityObserver?.availabilityObserver(self, unavailabilityCauseDidChange: cause)
            }
        }
    }

    private func setAvailable() {
        for availabilityObserver in availabilityObservers {
            availabilityObserver.availabilityObserver?.availabilityObserver(self, availabilityDidChange: .available)
        }
        if !peripheralManager.isAdvertising {
            dataService = CBMutableService(type: _configuration.dataServiceUUID, primary: true)
            let properties: CBCharacteristicProperties = [ .read, .notify, .writeWithoutResponse, .write ]
            let permissions: CBAttributePermissions = [ .readable, .writeable ]
            characteristicData = CBMutableCharacteristic(type: _configuration.dataServiceCharacteristicUUID, properties: properties, value: nil, permissions: permissions)
            dataService.characteristics = [ characteristicData ]
            peripheralManager.add(dataService)
        }
    }

    internal override func sendData(_ data: Data, toRemotePeer remotePeer: BKRemotePeer) -> Bool {
        guard let remoteCentral = remotePeer as? BKRemoteCentral else {
            return false
        }
        return peripheralManager.updateValue(data, for: characteristicData, onSubscribedCentrals: [ remoteCentral.central ])
    }

    private func handleDisconnectForRemoteCentral(_ remoteCentral: BKRemoteCentral) {
        failSendDataTasksForRemotePeer(remoteCentral)
        connectedRemotePeers.remove(at: connectedRemotePeers.index(of: remoteCentral)!)
        delegate?.peripheral(self, remoteCentralDidDisconnect: remoteCentral)
    }

    // MARK: BKCBPeripheralManagerDelegate

    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown, .resetting:
            break
        case .unsupported, .unauthorized, .poweredOff:
            let newCause: BKUnavailabilityCause
            #if os(iOS) || os(tvOS)
                if #available(iOS 10.0, tvOS 10.0, *) {
                    newCause = BKUnavailabilityCause(managerState: peripheralManager.state)
                } else {
                    newCause = BKUnavailabilityCause(peripheralManagerState: peripheralManager.peripheralManagerState)
                }
            #else
                newCause = BKUnavailabilityCause(peripheralManagerState: peripheralManager.state)
            #endif
            switch stateMachine.state {
                case let .unavailable(cause):
                    let oldCause = cause
                    _ = try? stateMachine.handleEvent(event: .setUnavailable(cause: newCause))
                    setUnavailable(oldCause, oldCause: newCause)
                default:
                    _ = try? stateMachine.handleEvent(event: .setUnavailable(cause: newCause))
                    setUnavailable(newCause, oldCause: nil)
                }
            case .poweredOn:
                let state = stateMachine.state
                _ = try? stateMachine.handleEvent(event: .setAvailable)
                switch state {
                case .starting, .unavailable:
                    setAvailable()
                default:
                    break
            }
        }
    }


    internal func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {

    }

    internal func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if !peripheralManager.isAdvertising {
            var advertisementData: [String: Any] = [ CBAdvertisementDataServiceUUIDsKey: _configuration.serviceUUIDs ]
            if let localName = _configuration.localName {
                advertisementData[CBAdvertisementDataLocalNameKey] = localName
            }
            peripheralManager.startAdvertising(advertisementData)
        }
    }

    internal func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        let remoteCentral = BKRemoteCentral(central: central)
        remoteCentral.configuration = configuration
        connectedRemotePeers.append(remoteCentral)
        delegate?.peripheral(self, remoteCentralDidConnect: remoteCentral)
    }

    internal func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        if let remoteCentral = connectedRemotePeers.filter({ ($0.identifier == central.identifier) }).last as? BKRemoteCentral {
            handleDisconnectForRemoteCentral(remoteCentral)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        for writeRequest in requests {
            guard writeRequest.characteristic.uuid == characteristicData.uuid else {
                continue
            }
            guard let remotePeer = (connectedRemotePeers.filter { $0.identifier == writeRequest.central.identifier } .last),
                  let remoteCentral = remotePeer as? BKRemoteCentral,
                  let data = writeRequest.value else {
                continue
            }
            remoteCentral.handleReceivedData(data)
        }
    }

    internal func peripheralManagerIsReadyToUpdateSubscribers(_ peripheral: CBPeripheralManager) {
        processSendDataTasks()
    }

}

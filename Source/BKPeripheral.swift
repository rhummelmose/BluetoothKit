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
    func peripheral(peripheral: BKPeripheral, remoteCentralDidConnect remoteCentral: BKRemoteCentral)
    /**
        Called when a remote central disconnects and can no longer receive data.
        - parameter peripheral: The peripheral object from which the remote central disconnected.
        - parameter remoteCentral: The remote central that disconnected.
    */
    func peripheral(peripheral: BKPeripheral, remoteCentralDidDisconnect remoteCentral: BKRemoteCentral)
}

/**
    The class used to take the Bluetooth LE peripheral role. Peripherals can be discovered and connected to by centrals.
    One a central has connected, the peripheral can send data to it.
*/
public class BKPeripheral: BKCBPeripheralManagerDelegate, BKAvailabilityObservable {
    
    // MARK: Type Aliases
    
    public typealias SendDataCompletionHandler = ((data: NSData, remoteCentral: BKRemoteCentral, error: Error?) -> Void)
    
    // MARK: Enums
    
    /**
        Errors that can occur while interacting with a BKPeripheral object.
        - InterruptedByUnavailability(cause): The action failed because Bluetooth LE became or was unavailable.
        - RemoteCentralNotConnected: The action failed because the remote central attempted to interact with, was not connected.
        - InternalError(underlyingError): The action failed because of an internal unhandled error, described by the associated underlying error.
    */
    public enum Error: ErrorType {
        case InterruptedByUnavailability(cause: BKUnavailabilityCause)
        case RemoteCentralNotConnected
        case InternalError(underlyingError: ErrorType?)
    }
    
    // MARK: Properies
    
    /// Bluetooth LE availability derived from the underlying CBPeripheralManager object.
    public var availability: BKAvailability {
        return BKAvailability(peripheralManagerState: peripheralManager.state)
    }
    
    /// The configuration that the BKPeripheral object was started with.
    public var configuration: BKPeripheralConfiguration? {
        return _configuration
    }
    
    /// The BKPeriheral object's delegate.
    public weak var delegate: BKPeripheralDelegate?
    
    /// Current availability observers
    public var availabilityObservers = [BKWeakAvailabilityObserver]()
    
    /// Currently connected remote centrals
    public var connectedRemoteCentrals = [BKRemoteCentral]()
    
    private var _configuration: BKPeripheralConfiguration!
    private var peripheralManager: CBPeripheralManager!
    private let stateMachine = BKPeripheralStateMachine()
    private var peripheralManagerDelegate: BKCBPeripheralManagerDelegateProxy!
    private var sendDataTasks = [BKSendDataTask]()
    private var characteristicData: CBMutableCharacteristic!
    private var dataService: CBMutableService!
    
    // MARK: Initialization
    
    public init() {
        peripheralManagerDelegate = BKCBPeripheralManagerDelegateProxy(delegate: self)
    }
    
    // MARK: Public Functions
    
    /**
        Starts the BKPeripheral object. Once started the peripheral will be discoverable and possible to connect to
        by remote centrals, provided that Bluetooth LE is available.
        - parameter configuration: A configuration defining the unique identifiers along with the name to be broadcasted.
        - throws: An internal error if the BKPeripheral object was already started.
    */
    public func startWithConfiguration(configuration: BKPeripheralConfiguration) throws {
        do {
            try stateMachine.handleEvent(.Start)
            _configuration = configuration
            peripheralManager = CBPeripheralManager(delegate: peripheralManagerDelegate, queue: nil, options: nil)
        } catch let error {
            throw Error.InternalError(underlyingError: error)
        }
    }
    
    /**
        Sends data to a connected remote central.
        - parameter data: The data to send.
        - parameter remoteCentral: The destination of the data payload.
        - parameter completionHandler: A completion handler allowing you to react in case the data failed to send or once it was sent succesfully.
    */
    public func sendData(data: NSData, toRemoteCentral remoteCentral: BKRemoteCentral, completionHandler: SendDataCompletionHandler?) {
        guard connectedRemoteCentrals.contains(remoteCentral) else {
            completionHandler?(data: data, remoteCentral: remoteCentral, error: Error.RemoteCentralNotConnected)
            return
        }
        let sendDataTask = BKSendDataTask(data: data, destination: remoteCentral, completionHandler: completionHandler)
        sendDataTasks.append(sendDataTask)
        if sendDataTasks.count == 1 {
            processSendDataTasks()
        }
    }
    
    /**
        Stops the BKPeripheral object.
        - throws: An internal error if the peripheral object wasn't started.
    */
    public func stop() throws {
        do {
            try stateMachine.handleEvent(.Stop)
            _configuration = nil
            if peripheralManager.isAdvertising {
                peripheralManager.stopAdvertising()
            }
            peripheralManager.removeAllServices()
            peripheralManager = nil
        } catch let error {
            throw Error.InternalError(underlyingError: error)
        }
    }
    
    // MARK: Private Functions
    
    private func setUnavailable(cause: BKUnavailabilityCause, oldCause: BKUnavailabilityCause?) {
        if oldCause == nil {
            for remoteCentral in connectedRemoteCentrals {
                handleDisconnectForRemoteCentral(remoteCentral)
            }
            for availabilityObserver in availabilityObservers {
                availabilityObserver.availabilityObserver?.availabilityObserver(self, availabilityDidChange: .Unavailable(cause: cause))
            }
        } else if oldCause != nil && oldCause != cause {
            for availabilityObserver in availabilityObservers {
                availabilityObserver.availabilityObserver?.availabilityObserver(self, unavailabilityCauseDidChange: cause)
            }
        }
    }
    
    private func setAvailable() {
        for availabilityObserver in availabilityObservers {
            availabilityObserver.availabilityObserver?.availabilityObserver(self, availabilityDidChange: .Available)
        }
        if !peripheralManager.isAdvertising {
            dataService = CBMutableService(type: _configuration.dataServiceUUID, primary: true)
            let properties: CBCharacteristicProperties = [ CBCharacteristicProperties.Read, CBCharacteristicProperties.Notify ]
            characteristicData = CBMutableCharacteristic(type: _configuration.dataServiceCharacteristicUUID, properties: properties, value: nil, permissions: CBAttributePermissions.Readable)
            dataService.characteristics = [ characteristicData ]
            peripheralManager.addService(dataService)
        }
    }
    
    private func processSendDataTasks() {
        guard sendDataTasks.count > 0 else {
            return
        }
        let nextTask = sendDataTasks.first!
        if nextTask.sentAllData {
            let sentEndOfDataMark = peripheralManager.updateValue(_configuration.endOfDataMark, forCharacteristic: characteristicData, onSubscribedCentrals: [ nextTask.destination.central ])
            if (sentEndOfDataMark) {
                sendDataTasks.removeAtIndex(sendDataTasks.indexOf(nextTask)!)
                nextTask.completionHandler?(data: nextTask.data, remoteCentral: nextTask.destination, error: nil)
                processSendDataTasks()
            } else {
                return
            }
        }
        let nextPayload = nextTask.nextPayload
        let sentNextPayload = peripheralManager.updateValue(nextPayload, forCharacteristic: characteristicData, onSubscribedCentrals: [ nextTask.destination.central ])
        if sentNextPayload {
            nextTask.offset += nextPayload.length
            processSendDataTasks()
        } else {
            return
        }
    }
    
    private func failSendDataTasksForRemoteCentral(remoteCentral: BKRemoteCentral) {
        for sendDataTask in sendDataTasks.filter({ $0.destination == remoteCentral }) {
            sendDataTasks.removeAtIndex(sendDataTasks.indexOf(sendDataTask)!)
            sendDataTask.completionHandler?(data: sendDataTask.data, remoteCentral: sendDataTask.destination, error: .RemoteCentralNotConnected)
        }
    }
    
    private func handleDisconnectForRemoteCentral(remoteCentral: BKRemoteCentral) {
        failSendDataTasksForRemoteCentral(remoteCentral)
        connectedRemoteCentrals.removeAtIndex(connectedRemoteCentrals.indexOf(remoteCentral)!)
        delegate?.peripheral(self, remoteCentralDidDisconnect: remoteCentral)
    }
    
    // MARK: BKCBPeripheralManagerDelegate
    
    internal func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .Unknown, .Resetting:
            break
        case .Unsupported, .Unauthorized, .PoweredOff:
            let newCause = BKUnavailabilityCause(peripheralManagerState: peripheral.state)
            switch stateMachine.state {
                case let .Unavailable(cause):
                    let oldCause = cause
                    try! stateMachine.handleEvent(.SetUnavailable(cause: newCause))
                    setUnavailable(oldCause, oldCause: newCause)
                default:
                    try! stateMachine.handleEvent(.SetUnavailable(cause: newCause))
                    setUnavailable(newCause, oldCause: nil)
                }
            case .PoweredOn:
                let state = stateMachine.state
                try! stateMachine.handleEvent(.SetAvailable)
                switch state {
                case .Starting, .Unavailable:
                    setAvailable()
                default:
                    break
            }
        }
    }
    
    internal func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {

    }
    
    internal func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        if !peripheralManager.isAdvertising {
            var advertisementData: [String: AnyObject] = [ CBAdvertisementDataServiceUUIDsKey: _configuration.serviceUUIDs ]
            if let localName = _configuration.localName {
                advertisementData[CBAdvertisementDataLocalNameKey] = localName
            }
            peripheralManager.startAdvertising(advertisementData)
        }
    }
    
    internal func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        let remoteCentral = BKRemoteCentral(central: central)
        connectedRemoteCentrals.append(remoteCentral)
        delegate?.peripheral(self, remoteCentralDidConnect: remoteCentral)
    }
    
    internal func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        if let remoteCentral = connectedRemoteCentrals.filter({ $0.central.identifier.isEqual(central.identifier) }).last {
            handleDisconnectForRemoteCentral(remoteCentral)
        }
    }
    
    internal func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        processSendDataTasks()
    }
    
}

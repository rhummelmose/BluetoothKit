//
//  BKPeripheral.swift
//  BluetoothKit
//
//  Created by Rasmus Taulborg Hummelmose on 25/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol BKPeripheralDelegate: class, BKAvailabilityDelegate {
    func peripheral(peripheral: BKPeripheral, remoteCentralDidConnect remoteCentral: BKRemoteCentral)
    func peripheral(peripheral: BKPeripheral, remoteCentralDidDisconnect remoteCentral: BKRemoteCentral)
}

private let singleton = BKPeripheral()

public class BKPeripheral: BKCBPeripheralManagerDelegate {
    
    // MARK: Public Enums
    
    public enum Error: ErrorType {
        case InterruptedByUnavailability(BKUnavailabilityCause)
        case RemoteCentralNotConnected
        case InternalError(underlyingError: ErrorType?)
    }
    
    // MARK: Public Properies
    
    public class var sharedInstance: BKPeripheral {
        return singleton
    }
    
    public var availability: BKAvailability {
        return BKAvailability(peripheralManagerState: peripheralManager.state)
    }
    
    public weak var delegate: BKPeripheralDelegate?
    public var connectedRemoteCentrals = [BKRemoteCentral]()
    
    // MARK: Initialization
    
    public init() {
        peripheralManagerDelegate = BKCBPeripheralManagerDelegateProxy(delegate: self)
    }
    
    // MARK: Public Functions
    
    public func startWithName(name: String?) throws {
        do {
            try stateMachine.handleEvent(.Start)
            self.name = name
            peripheralManager = CBPeripheralManager(delegate: peripheralManagerDelegate, queue: nil, options: nil)
        } catch let error {
            throw Error.InternalError(underlyingError: error)
        }
    }
    
    public func sendData(data: NSData, toRemoteCentral remoteCentral: BKRemoteCentral, completionHandler: ((data: NSData, remoteCentral: BKRemoteCentral, error: Error?) -> Void)?) throws {
        guard connectedRemoteCentrals.contains(remoteCentral) else {
            throw Error.RemoteCentralNotConnected
        }
        let sendDataTask = BKSendDataTask(data: data, destination: remoteCentral, completionHandler: completionHandler)
        sendDataTasks.append(sendDataTask)
        if sendDataTasks.count == 1 {
            processSendDataTasks()
        }
    }
    
    // MARK: Internal Functions
    
    internal func setUnavailable(cause: BKUnavailabilityCause, oldCause: BKUnavailabilityCause?) {
        if oldCause == nil {
            for remoteCentral in connectedRemoteCentrals {
                handleDisconnectForRemoteCentral(remoteCentral)
            }
            delegate?.availabilityObserver(self, availabilityDidChange: .Unavailable(cause: cause))
        } else if oldCause != nil && oldCause != cause {
            delegate?.availabilityObserver(self, unavailabilityCauseDidChange: cause)
        }
    }
    
    internal func setAvailable() {
        delegate?.availabilityObserver(self, availabilityDidChange: .Available)
        if !peripheralManager.isAdvertising {
            service = CBMutableService(type: BKService.DataTransferService.identifier, primary: true)
            let properties: CBCharacteristicProperties = [ CBCharacteristicProperties.Read, CBCharacteristicProperties.Notify ]
            characteristicData = CBMutableCharacteristic(type: BKService.Characteristic.Data.identifier, properties: properties, value: nil, permissions: CBAttributePermissions.Readable)
            service.characteristics = [ characteristicData ]
            peripheralManager.addService(service)
        }
    }
    
    internal func processSendDataTasks() {
        guard sendDataTasks.count > 0 else {
            return
        }
        let nextTask = sendDataTasks.first!
        if nextTask.sentAllData {
            let sentEndOfDataMark = peripheralManager.updateValue(BKService.endOfDataMark, forCharacteristic: characteristicData, onSubscribedCentrals: [ nextTask.destination.central ])
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
    
    internal func failSendDataTasksForRemoteCentral(remoteCentral: BKRemoteCentral) {
        for sendDataTask in sendDataTasks.filter({ $0.destination == remoteCentral }) {
            sendDataTasks.removeAtIndex(sendDataTasks.indexOf(sendDataTask)!)
            sendDataTask.completionHandler?(data: sendDataTask.data, remoteCentral: sendDataTask.destination, error: .RemoteCentralNotConnected)
        }
    }
    
    internal func handleDisconnectForRemoteCentral(remoteCentral: BKRemoteCentral) {
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
        var advertisementDictionary: [String: AnyObject] = [ CBAdvertisementDataServiceUUIDsKey: [ BKService.DataTransferService.identifier ] ]
        if let advertisementName = name {
            advertisementDictionary[CBAdvertisementDataLocalNameKey] = advertisementName
        }
        peripheralManager.startAdvertising(advertisementDictionary)
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
    
    // MARK: Private Properties
    
    private var name: String?
    private var peripheralManager: CBPeripheralManager!
    private let stateMachine = BKPeripheralStateMachine()
    private var peripheralManagerDelegate: BKCBPeripheralManagerDelegateProxy!
    private var sendDataTasks = [BKSendDataTask]()
    private var characteristicData: CBMutableCharacteristic!
    private var service: CBMutableService!
    
}

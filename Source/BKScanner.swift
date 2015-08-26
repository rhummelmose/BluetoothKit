//
//  BKScanner.swift
//  CustomerFacingDisplay
//
//  Created by Rasmus Taulborg Hummelmose on 19/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation
import CoreBluetooth

internal class BKScanner: BKCBCentralManagerDiscoveryDelegate {
    
    // MARK: Internal Implementaiton
    
    internal var centralManager: CBCentralManager!
    
    internal enum Error: ErrorType {
        case NoCentralManagerSet
        case Busy
        case Interrupted
    }
    
    internal func scanWithDuration(duration: NSTimeInterval, progressHandler: ((newDiscovery: BKRemotePeripheral) -> Void )? = nil, completionHandler: ((result: [BKRemotePeripheral]?, error: Error?) -> Void)) throws {
        guard !busy else {
            throw Error.Busy
        }
        guard centralManager != nil else {
            throw Error.NoCentralManagerSet
        }
        busy = true
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        self.discoveredRemotePeripherals = [BKRemotePeripheral]()
        centralManager.scanForPeripheralsWithServices([ BKService.DataTransferService.identifier ], options: nil)
        timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: "timerElapsed", userInfo: nil, repeats: false)
    }
    
    internal func interruptScan() {
        guard busy else {
            return
        }
        self.discoveredRemotePeripherals = nil
        endScan(.Interrupted)
    }
    
    // MARK: BKCBCentralManagerDiscoveryDelegate
    
    internal func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let discoveredRemotePeripheral = BKRemotePeripheral(identifier: peripheral.identifier, peripheral: peripheral)
        discoveredRemotePeripherals?.append(discoveredRemotePeripheral)
        progressHandler?(newDiscovery: discoveredRemotePeripheral)
    }
    
    // MARK: Private Implementation
    
    private var busy = false
    private var progressHandler: ((newDiscovery: BKRemotePeripheral) -> Void )?
    private var completionHandler: ((result: [BKRemotePeripheral]?, error: Error?) -> Void)?
    private var discoveredRemotePeripherals: [BKRemotePeripheral]?
    private var timer: NSTimer?
    
    @objc private func timerElapsed() {
        endScan(nil)
    }
    
    private func endScan(error: Error?) {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
        centralManager.stopScan()
        let completionHandler = self.completionHandler!
        let discoveredRemotePeripherals = self.discoveredRemotePeripherals
        self.progressHandler = nil
        self.completionHandler = nil
        self.discoveredRemotePeripherals = nil
        busy = false
        completionHandler(result: discoveredRemotePeripherals, error: error)
    }
    
}

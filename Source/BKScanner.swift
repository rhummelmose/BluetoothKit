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

internal class BKScanner: BKCBCentralManagerDiscoveryDelegate {
    
    // MARK: Type Aliases
    
    internal typealias ScanCompletionHandler = ((result: [BKDiscovery]?, error: Error?) -> Void)
    
    // MARK: Enums
    
    internal enum Error: ErrorType {
        case NoCentralManagerSet
        case Busy
        case Interrupted
    }
    
    // MARK: Properties
    
    internal var configuration: BKConfiguration!
    internal var centralManager: CBCentralManager!
    private var busy = false
    private var scanHandlers: ( progressHandler: BKCentral.ScanProgressHandler?, completionHandler: ScanCompletionHandler )?
    private var discoveries = [BKDiscovery]()
    private var durationTimer: NSTimer?
    
    // MARK: Internal Functions
    
    internal func scanWithDuration(duration: NSTimeInterval, progressHandler: BKCentral.ScanProgressHandler? = nil, completionHandler: ScanCompletionHandler) throws {
        do {
            try validateForActivity()
            busy = true
            scanHandlers = (progressHandler: progressHandler, completionHandler: completionHandler)
            centralManager.scanForPeripheralsWithServices(configuration.serviceUUIDs, options: nil)
            durationTimer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: "durationTimerElapsed", userInfo: nil, repeats: false)
        } catch let error {
            throw error
        }
    }
    
    internal func interruptScan() {
        guard busy else {
            return
        }
        endScan(.Interrupted)
    }
    
    // MARK: Private Functions
    
    private func validateForActivity() throws {
        guard !busy else {
            throw Error.Busy
        }
        guard centralManager != nil else {
            throw Error.NoCentralManagerSet
        }
    }
    
    @objc private func durationTimerElapsed() {
        endScan(nil)
    }
    
    private func endScan(error: Error?) {
        invalidateTimer()
        centralManager.stopScan()
        let completionHandler = scanHandlers?.completionHandler
        let discoveries = self.discoveries
        scanHandlers = nil
        self.discoveries.removeAll()
        busy = false
        completionHandler?(result: discoveries, error: error)
    }
    
    private func invalidateTimer() {
        if let durationTimer = self.durationTimer {
            durationTimer.invalidate()
            self.durationTimer = nil
        }
    }
    
    // MARK: BKCBCentralManagerDiscoveryDelegate
    
    internal func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String: AnyObject], RSSI: NSNumber) {
        guard busy else {
            return
        }
        let RSSI = Int(RSSI)
        let remotePeripheral = BKRemotePeripheral(identifier: peripheral.identifier, peripheral: peripheral)
        remotePeripheral.configuration = configuration
        let discovery = BKDiscovery(advertisementData: advertisementData, remotePeripheral: remotePeripheral, RSSI: RSSI)
        if !discoveries.contains(discovery) {
            discoveries.append(discovery)
            scanHandlers?.progressHandler?(newDiscoveries: [ discovery ])
        }
    }
    
}

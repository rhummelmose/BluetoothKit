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

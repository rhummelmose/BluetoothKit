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

internal class BKContinousScanner {
    
    // MARK: Type Aliases
    
    internal typealias ErrorHandler = ((error: Error) -> Void)
    internal typealias StateHandler = BKCentral.ContinuousScanStateHandler
    internal typealias ChangeHandler = BKCentral.ContinuousScanChangeHandler
    
    // MARK: Enums
    
    internal enum Error: ErrorType {
        case Busy
        case Interrupted
        case InternalError(underlyingError: ErrorType)
    }
    
    // MARK: Properties
    
    internal var state: BKCentral.ContinuousScanState
    private let scanner: BKScanner
    private var busy = false
    private var maintainedDiscoveries = [BKDiscovery]()
    private var inBetweenDelayTimer: NSTimer?
    private var errorHandler: ErrorHandler?
    private var stateHandler: StateHandler?
    private var changeHandler: ChangeHandler?
    private var duration: NSTimeInterval!
    private var inBetweenDelay: NSTimeInterval!
    
    // MARK: Initialization
    
    internal init(scanner: BKScanner) {
        self.scanner = scanner
        state = .Stopped
    }
    
    // MARK Internal Functions
    
    internal func scanContinuouslyWithChangeHandler(changeHandler: ChangeHandler, stateHandler: StateHandler? = nil, duration: NSTimeInterval = 3, inBetweenDelay: NSTimeInterval = 3, errorHandler: ErrorHandler?) {
        guard !busy else {
            errorHandler?(error: .Busy)
            return
        }
        busy = true
        self.duration = duration
        self.inBetweenDelay = inBetweenDelay
        self.errorHandler = errorHandler
        self.stateHandler = stateHandler
        self.changeHandler = changeHandler
        scan()
    }
    
    internal func interruptScan() {
        scanner.interruptScan()
        endScanning(.Interrupted)
    }
    
    // MARK: Private Functions
    
    private func scan() {
        do {
            state = .Scanning
            stateHandler?(newState: state)
            try scanner.scanWithDuration(duration, progressHandler: { newDiscoveries in
                let actualDiscoveries = newDiscoveries.filter({ !self.maintainedDiscoveries.contains($0) })
                if !actualDiscoveries.isEmpty {
                    self.maintainedDiscoveries += actualDiscoveries
                    let changes = actualDiscoveries.map({ BKDiscoveriesChange.Insert(discovery: $0) })
                    self.changeHandler?(changes: changes, discoveries: self.maintainedDiscoveries)
                }
            }, completionHandler: { result, error in
                guard result != nil && error == nil else {
                    self.endScanning(Error.InternalError(underlyingError: error!))
                    return
                }
                let discoveriesToRemove = self.maintainedDiscoveries.filter({ !result!.contains($0) })
                let changes = discoveriesToRemove.map({ BKDiscoveriesChange.Remove(discovery: $0) })
                for discoveryToRemove in discoveriesToRemove {
                    self.maintainedDiscoveries.removeAtIndex(self.maintainedDiscoveries.indexOf(discoveryToRemove)!)
                }
                self.changeHandler?(changes: changes, discoveries: self.maintainedDiscoveries)
                self.state = .Waiting
                self.stateHandler?(newState: self.state)
                self.inBetweenDelayTimer = NSTimer.scheduledTimerWithTimeInterval(self.inBetweenDelay, target: self, selector: "inBetweenDelayTimerElapsed", userInfo: nil, repeats: false)
            })
        } catch let error {
            endScanning(Error.InternalError(underlyingError: error))
        }
    }
    
    private func reset() {
        inBetweenDelayTimer?.invalidate()
        maintainedDiscoveries.removeAll()
        errorHandler = nil
        stateHandler = nil
        changeHandler = nil
    }
    
    private func endScanning(error: Error?) {
        busy = false
        state = .Stopped
        let errorHandler = self.errorHandler
        let stateHandler = self.stateHandler
        reset()
        stateHandler?(newState: state)
        if let error = error {
            errorHandler?(error: error)
        }
    }
    
    @objc private func inBetweenDelayTimerElapsed() {
        scan()
    }

}

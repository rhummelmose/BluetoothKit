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

    internal typealias ErrorHandler = ((_ error: BKError) -> Void)
    internal typealias StateHandler = BKCentral.ContinuousScanStateHandler
    internal typealias ChangeHandler = BKCentral.ContinuousScanChangeHandler

    // MARK: Enums

    internal enum BKError: Error {
        case busy
        case interrupted
        case internalError(underlyingError: Error)
    }

    // MARK: Properties

    internal var state: BKCentral.ContinuousScanState
    private let scanner: BKScanner
    private var busy = false
    private var maintainedDiscoveries = [BKDiscovery]()
    private var inBetweenDelayTimer: Timer?
    private var errorHandler: ErrorHandler?
    private var stateHandler: StateHandler?
    private var changeHandler: ChangeHandler?
    private var duration: TimeInterval!
    private var inBetweenDelay: TimeInterval!

    // MARK: Initialization

    internal init(scanner: BKScanner) {
        self.scanner = scanner
        state = .stopped
    }

    // MARK Internal Functions

    internal func scanContinuouslyWithChangeHandler(_ changeHandler: @escaping ChangeHandler, stateHandler: StateHandler? = nil, duration: TimeInterval = 3, inBetweenDelay: TimeInterval = 3, errorHandler: ErrorHandler?) {
        guard !busy else {
            errorHandler?(.busy)
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
        endScanning(.interrupted)
    }

    // MARK: Private Functions

    private func scan() {
        do {
            state = .scanning
            stateHandler?(state)
            try scanner.scanWithDuration(duration, progressHandler: { newDiscoveries in
                let actualDiscoveries = newDiscoveries.filter({ !self.maintainedDiscoveries.contains($0) })
                if !actualDiscoveries.isEmpty {
                    self.maintainedDiscoveries += actualDiscoveries
                    let changes = actualDiscoveries.map({ BKDiscoveriesChange.insert(discovery: $0) })
                    self.changeHandler?(changes, self.maintainedDiscoveries)
                }
            }, completionHandler: { result, error in
                guard result != nil && error == nil else {
                    self.endScanning(BKError.internalError(underlyingError: error! as Error))
                    return
                }
                let discoveriesToRemove = self.maintainedDiscoveries.filter({ !result!.contains($0) })
                let changes = discoveriesToRemove.map({ BKDiscoveriesChange.remove(discovery: $0) })
                for discoveryToRemove in discoveriesToRemove {
                    self.maintainedDiscoveries.remove(at: self.maintainedDiscoveries.index(of: discoveryToRemove)!)
                }
                self.changeHandler?(changes, self.maintainedDiscoveries)
                self.state = .waiting
                self.stateHandler?(self.state)
                self.inBetweenDelayTimer = Timer.scheduledTimer(timeInterval: self.inBetweenDelay, target: self, selector: #selector(BKContinousScanner.inBetweenDelayTimerElapsed), userInfo: nil, repeats: false)
            })
        } catch let error {
            endScanning(BKError.internalError(underlyingError: error))
        }
    }

    private func reset() {
        inBetweenDelayTimer?.invalidate()
        maintainedDiscoveries.removeAll()
        errorHandler = nil
        stateHandler = nil
        changeHandler = nil
    }

    private func endScanning(_ error: BKError?) {
        busy = false
        state = .stopped
        let errorHandler = self.errorHandler
        let stateHandler = self.stateHandler
        reset()
        stateHandler?(state)
        if let error = error {
            errorHandler?(error)
        }
    }

    @objc private func inBetweenDelayTimerElapsed() {
        scan()
    }

}

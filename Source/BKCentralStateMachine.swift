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

internal class BKCentralStateMachine {

    // MARK: Enums

    internal enum BKError: Error {
        case transitioning(currentState: State, validStates: [State])
    }

    internal enum State {
        case initialized, starting, unavailable(cause: BKUnavailabilityCause), available, scanning
    }

    internal enum Event {
        case start, setUnavailable(cause: BKUnavailabilityCause), setAvailable, scan, connect, stop
    }

    // MARK: Properties

    internal var state: State

    // MARK: Initialization

    internal init() {
        self.state = .initialized
    }

    // MARK: Functions

    internal func handleEvent(_ event: Event) throws {
        switch event {
        case .start:
            try handleStartEvent(event)
        case .setAvailable:
            try handleSetAvailableEvent(event)
        case let .setUnavailable(newCause):
            try handleSetUnavailableEvent(event, cause: newCause)
        case .scan:
            try handleScanEvent(event)
        case .connect:
            try handleConnectEvent(event)
        case .stop:
            try handleStopEvent(event)
        }
    }

    private func handleStartEvent(_ event: Event) throws {
        switch state {
        case .initialized:
            state = .starting
        default:
            throw BKError.transitioning(currentState: state, validStates: [ .initialized ])
        }
    }

    private func handleSetAvailableEvent(_ event: Event) throws {
        switch state {
        case .initialized:
            throw BKError.transitioning(currentState: state, validStates: [ .starting, .available, .unavailable(cause: nil) ])
        default:
            state = .available
        }
    }

    private func handleSetUnavailableEvent(_ event: Event, cause: BKUnavailabilityCause) throws {
        switch state {
        case .initialized:
            throw BKError.transitioning(currentState: state, validStates: [ .starting, .available, .unavailable(cause: nil) ])
        default:
            state = .unavailable(cause: cause)
        }
    }

    private func handleScanEvent(_ event: Event) throws {
        switch state {
        case .available:
            state = .scanning
        default:
            throw BKError.transitioning(currentState: state, validStates: [ .available ])
        }
    }

    private func handleConnectEvent(_ event: Event) throws {
        switch state {
        case .available, .scanning:
            break
        default:
            throw BKError.transitioning(currentState: state, validStates: [ .available, .scanning ])
        }
    }

    private func handleStopEvent(_ event: Event) throws {
        switch state {
        case .initialized:
            throw BKError.transitioning(currentState: state, validStates: [ .starting, .unavailable(cause: nil), .available, .scanning ])
        default:
            state = .initialized
        }
    }

}

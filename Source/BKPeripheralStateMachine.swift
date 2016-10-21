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

internal class BKPeripheralStateMachine {

    // MARK: Enums

    internal enum BKError: Error {
        case transitioning(currentState: State, validStates: [State])
    }

    internal enum State {
        case initialized, starting, unavailable(cause: BKUnavailabilityCause), available
    }

    internal enum Event {
        case start, setUnavailable(cause: BKUnavailabilityCause), setAvailable, stop
    }

    // MARK: Properties

    internal var state: State

    // MARK: Initialization

    internal init() {
        self.state = .initialized
    }

    // MARK: Functions

    internal func handleEvent(event: Event) throws {
        switch event {
        case .start:
            try handleStartEvent(event: event)
        case .setAvailable:
            try handleSetAvailableEvent(event: event)
        case let .setUnavailable(cause):
            try handleSetUnavailableEvent(event: event, withCause: cause)
        case .stop:
            try handleStopEvent(event: event)
        }
    }

    private func handleStartEvent(event: Event) throws {
        switch state {
        case .initialized:
            state = .starting
        default:
            throw BKError.transitioning(currentState: state, validStates: [ .initialized ])
        }
    }

    private func handleSetAvailableEvent(event: Event) throws {
        switch state {
        case .initialized:
            throw BKError.transitioning(currentState: state, validStates: [ .starting, .available, .unavailable(cause: nil) ])
        default:
            state = .available
        }
    }

    private func handleSetUnavailableEvent(event: Event, withCause cause: BKUnavailabilityCause) throws {
        switch state {
        case .initialized:
            throw BKError.transitioning(currentState: state, validStates: [ .starting, .available, .unavailable(cause: nil) ])
        default:
            state = .unavailable(cause: cause)
        }
    }

    private func handleStopEvent(event: Event) throws {
        switch state {
        case .initialized:
            throw BKError.transitioning(currentState: state, validStates: [ .starting, .available, .unavailable(cause: nil) ])
        default:
            state = .initialized
        }
    }

}

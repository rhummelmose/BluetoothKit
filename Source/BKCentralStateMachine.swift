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
    
    internal enum Error: ErrorProtocol {
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
            case .start: switch state {
                case .initialized: state = .starting
                default: throw Error.transitioning(currentState: state, validStates: [ .initialized ])
            }
            case .setAvailable: switch state {
                case .initialized: throw Error.transitioning(currentState: state, validStates: [ .starting, .available, .unavailable(cause: nil) ])
                default: state = .available
            }
            case let .setUnavailable(newCause): switch state {
                case .initialized: throw Error.transitioning(currentState: state, validStates: [ .starting, .available, .unavailable(cause: nil) ])
                default: state = .unavailable(cause: newCause)
            }
            case .scan: switch state {
                case .available: state = .scanning
                default: throw Error.transitioning(currentState: state, validStates: [ .available ])
            }
            case .connect: switch state {
                case .available, .scanning: break
                default: throw Error.transitioning(currentState: state, validStates: [ .available, .scanning ])
            }
            case .stop: switch state {
                case .initialized: throw Error.transitioning(currentState: state, validStates: [ .starting, .unavailable(cause: nil), .available, .scanning ])
                default: state = .initialized
            }
        }
    }
    
}

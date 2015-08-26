//
//  BKPeripheralStateMachine.swift
//  BluetoothKit
//
//  Created by Rasmus Taulborg Hummelmose on 25/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation

internal class BKPeripheralStateMachine {
    
    // MARK: Enums
    
    internal enum Error: ErrorType {
        case Transitioning(currentState: State, validStates: [State])
    }
    
    internal enum State {
        case Initialized, Starting, Unavailable(cause: BKUnavailabilityCause), Available
    }
    
    internal enum Event {
        case Start, SetUnavailable(cause: BKUnavailabilityCause), SetAvailable
    }
    
    // MARK: Stored Properties
    
    internal var state: State
    
    // MARK: Initialization
    
    internal init() {
        self.state = .Initialized
    }
    
    // MARK: State Machine
    
    internal func handleEvent(event: Event) throws {
        switch event {
            case .Start: switch state {
                case .Initialized: state = .Starting
                default: throw Error.Transitioning(currentState: state, validStates: [ .Initialized ])
            }
            case .SetAvailable: switch state {
                case .Initialized: throw Error.Transitioning(currentState: state, validStates: [ .Starting, .Available, .Unavailable(cause: nil) ])
                default: state = .Available
            }
            case let .SetUnavailable(newCause): switch state {
                case .Initialized: throw Error.Transitioning(currentState: state, validStates: [ .Starting, .Available, .Unavailable(cause: nil) ])
                default: state = .Unavailable(cause: newCause)
            }
        }
    }
    
}

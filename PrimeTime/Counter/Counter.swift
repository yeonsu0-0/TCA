//
//  Counter.swift
//  Counter
//
//  Created by yeonsu on 2023/08/15.
//

public enum CounterAction {
    case decrementTapped
    case incrementTapped
}


public func counterReducer(state: inout Int, action: CounterAction) -> Void {
    switch action {
    case .decrementTapped:
        state -= 1
        
    case .incrementTapped:
        state += 1
    }
}

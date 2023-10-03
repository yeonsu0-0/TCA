//
//  PrimeModal.swift
//  PrimeModal
//
//  Created by yeonsu on 2023/08/15.
//

import ComposableArchitecture
import SwiftUI

public typealias PrimeModalState = (count: Int, favoritePrimes: [Int])

//public struct PrimeModalState {
//    public var count: Int
//    public var favoritePrimes: [Int]
//
//    public init(count: Int, favoritePrimes: [Int]) {
//        self.count = count
//        self.favoritePrimes = favoritePrimes
//      }
//}


public enum PrimeModalAction {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}


public func primeModalReducer(state: inout PrimeModalState, action: PrimeModalAction) -> Void {
    switch action {
    case .saveFavoritePrimeTapped:
        state.favoritePrimes.append(state.count)
        
    case .removeFavoritePrimeTapped:
        state.favoritePrimes.removeAll(where: { $0 == state.count })
    }
}


public struct IsPrimeModalView: View {
    @ObservedObject var store: Store<PrimeModalState, PrimeModalAction>
    
    public init(store: Store<PrimeModalState, PrimeModalAction>) {
      self.store = store
    }
    
    public var body: some View {
        VStack {
            if isPrime(self.store.value.count) {
                Text("\(self.store.value.count) is prime😻")
                if self.store.value.favoritePrimes.contains(self.store.value.count) {
                    Button("Remove to/from favorite primes") {
                        self.store.send(.removeFavoritePrimeTapped)
                    }
                } else {
                    Button("Save to favorite primes") {
                        self.store.send(.saveFavoritePrimeTapped)
                        }
                }
            } else {
                Text("\(self.store.value.count) is not prime👻")
            }
            
        }
    }
}


private func isPrime (_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}


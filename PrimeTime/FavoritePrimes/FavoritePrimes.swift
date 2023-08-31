//
//  FavoritePrimes.swift
//  FavoritePrimes
//
//  Created by yeonsu on 2023/08/15.
//

import ComposableArchitecture
import SwiftUI

public enum FavoritePrimesAction {
    case deleteFavoritePrimes(IndexSet)
}

public func favoritePrimesReducer(state: inout [Int], action: FavoritePrimesAction) {
    switch action {
    case let .deleteFavoritePrimes(indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
    }
}

public struct FavoritePrimesView: View {
    @ObservedObject var store: Store<[Int], FavoritePrimesAction>
    // @Binding var favoritePrimes: [Int]
    // @Binding var activityFeed: [AppState.Activity]
    
    public init(store: Store<[Int], FavoritePrimesAction>) {
      self.store = store
    }
    
    public var body: some View {
        List {
            ForEach(self.store.value, id: \.self) { prime in
                Text("\(prime)")
            }.onDelete { indexSet in
                self.store.send(.deleteFavoritePrimes(indexSet))
            }
        }
        .navigationBarTitle(Text("Favorite Primes"))
    }
}

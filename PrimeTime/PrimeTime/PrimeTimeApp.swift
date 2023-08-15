//
//  PrimeTimeApp.swift
//  PrimeTime
//
//  Created by yeonsu on 2023/08/15.
//

import SwiftUI
import ComposableArchitecture

@main
struct MyPrimeNumberApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialValue: AppState(), reducer: appReducer))
        }
    }
}


import SwiftUI
import PlaygroundSupport


struct ContentView: View {
    @ObservedObject var state: AppState
    var body: some View {
        NavigationView {
            List{
                NavigationLink(destination: CounterView(state: self.state)) {
                    Text("Counter demo")
                }
                NavigationLink(destination: EmptyView()) {
                    Text("Favorite primes")
                }
            }
            .navigationTitle("State Management")
        }
    }
}

private func ordinal(_ n: Int) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .ordinal
  return formatter.string(for: n) ?? ""
}

import Combine

class AppState: ObservableObject {
    @Published var count = 0
    
    var didChange = PassthroughSubject<Void, Never>()
}

struct CounterView: View {
    // @State var count: Int = 0
    // @State: 상태가 업데이트 될 때마다 뷰 랜더링
    // 화면이 바뀌면(뒤로 가거나 다른 화면으로 넘어갈 때)상태가 저장되지 않음

    // @ObservedObject(AppState 클래스에서 ObservableObject 프로토콜 채택해야 함)
    @ObservedObject var state: AppState
    
    
    var body: some View {

        VStack {
            HStack {
                Button(action: {self.state.count -= 1}) {
                    Text("-")
                }
                Text("\(self.state.count)")
                Button(action: {self.state.count += 1}) {
                    Text("+")
                }
            }
            Button (action: {}) {
                Text("Is this prime?")
            }
            Button (action: {}) {
                Text("What is the \(ordinal(self.state.count))th prime?")
            }
        }.font(.title).navigationTitle("Counter demo")
    }
}

PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView(state: AppState()).frame(width: 392.0, height: 740))

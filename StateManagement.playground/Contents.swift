
import SwiftUI
import PlaygroundSupport

struct WolframAlphaResult: Decodable {
    let queryresult: QueryResult
    
    struct QueryResult: Decodable {
        let pods: [Pod]
        
        struct Pod: Decodable {
            let primary: Bool?
            let subpods: [SubPod]
            
            struct SubPod: Decodable {
                let plaintext: String
            }
        }
    }
}


func wolframAlpha(query: String, callback: @escaping (WolframAlphaResult?) -> Void) -> Void {
    var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
    components.queryItems = [
        URLQueryItem(name: "input", value: query),
        URLQueryItem(name: "format", value: "plaintext"),
        URLQueryItem(name: "output", value: "JSON"),
        URLQueryItem(name: "appid", value: ""),
    ]
    
    URLSession.shared.dataTask(with: components.url(relativeTo: nil)!) { data, response, error in
        callback(
            data
                .flatMap { try? JSONDecoder().decode(WolframAlphaResult.self, from: $0) }
        )
    }
    .resume()
}


func nthPrime(_ n: Int, callback: @escaping (Int?) -> Void) -> Void {
    wolframAlpha(query: "prime \(n)") { result in
        callback(
            result
                .flatMap {
                    $0.queryresult
                        .pods
                        .first(where: { $0.primary == .some(true) })?
                        .subpods
                        .first?
                        .plaintext
                }
                .flatMap(Int.init)
        )
    }
}

nthPrime(2) { p in print(p as Any) }
// 7919

struct ContentView: View {
    @ObservedObject var state: AppState
    var body: some View {
        NavigationView {
            List{
                NavigationLink(destination: CounterView(state: self.state)) {
                    Text("Counter demo")
                }
                NavigationLink(destination: FavoritePrimes(state: self.state)) {
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
    @Published var favoritePrimes: [Int] = []
    @Published var loggedInUser: User?
    @Published var activityFeed: [Activity] = []
    
    var didChange = PassthroughSubject<Void, Never>()
    
    struct Activity {
        let timestamp: Date
        let type: ActivityType
        
        enum ActivityType {
            case addedFavoritePrime(Int)
            case removedFavoritePrime(Int)
        }
    }
    
    struct User {
        let id: Int
        let name: String
        let bio: String
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


struct CounterView: View {
    // @State var count: Int = 0
    // @State: 상태가 업데이트 될 때마다 뷰 랜더링
    // 화면이 바뀌면(뒤로 가거나 다른 화면으로 넘어갈 때)상태가 저장되지 않음
    
    // @ObservedObject(AppState 클래스에서 ObservableObject 프로토콜 채택해야 함)
    @ObservedObject var state: AppState
    
    // 모달 상태 추적(로컬)
    @State var isPrimeModalShown: Bool = false
    @State var alertNthPrime: Int?
    @State var isAlertShown = false
    @State var isNthPrimeButtonDisabled = false
    
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
            Button (action: {self.isPrimeModalShown = true}) {
                Text("Is this prime?")
            }
            Button (action: self.nthPrimeButtonAction) {
                
                //                { self.isNthPrimeButtonDisabled = true
                //                  nthPrime(self.state.count) { prime in
                //                    self.alertNthPrime = prime
                //                    self.isAlertShown = true
                //                    self.isNthPrimeButtonDisabled = false }}
                
                Text("What is the \(ordinal(self.state.count)) prime?")
            }
            .disabled(self.isNthPrimeButtonDisabled)
        }
        .font(.title)
        .navigationTitle("Counter demo")
        .sheet(isPresented: $isPrimeModalShown, onDismiss: {
            self.isPrimeModalShown = false
        }) {
            IsPrimeModalView(state: self.state)
        }
        .alert(isPresented: $isAlertShown) {
            Alert(title: Text("The \(ordinal(self.state.count)) prime is API 대체"))
        }
    }
    func nthPrimeButtonAction() {
        self.isNthPrimeButtonDisabled = true
        nthPrime(self.state.count) { prime in
            self.alertNthPrime = prime
            self.isAlertShown = true
            self.isNthPrimeButtonDisabled = false
        }
    }
}

struct IsPrimeModalView: View {
    @ObservedObject var state: AppState
    var body: some View {
        VStack {
            if isPrime(self.state.count) {
                Text("\(self.state.count) is prime😻")
                if self.state.favoritePrimes.contains(self.state.count) {
                    Button(action: { self.state.favoritePrimes.removeAll(where: { $0 == self.state.count})
                        self.state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(self.state.count)))
                    }) {
                        Text("Remove to/from favorite primes")
                    }
                } else {
                    Button(action: {self.state.favoritePrimes.append(self.state.count)
                        self.state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(self.state.count)))}) {
                            Text("Save to favorite primes")
                        }
                }
            } else {
                Text("\(self.state.count) is not prime👻")
            }
            
        }
    }
}



struct FavoritePrimes: View {
    @ObservedObject var state: AppState
    @Binding var favoritePrimes: [Int]
    @Binding var activityFeed: [AppState.Activity]
    
    var body: some View {
        List {
            ForEach(self.state.favoritePrimes, id: \.self) { prime in
                Text("\(prime)")
            }.onDelete { indexSet in
                for index in indexSet {
                    let prime = self.state.favoritePrimes[index]
                    self.state.favoritePrimes.remove(at: index)
                    self.state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
                }
            }
        }
        .navigationBarTitle(Text("Favorite Primes"))
    }
}

extension AppState {
    func addFavoritePrime() {
        self.favoritePrimes.append(self.count)
        self.activityFeed.append(Activity(timestamp: Date(), type: .addedFavoritePrime(self.count)))
    }
    
    func removeFavoritePrime(_ prime: Int) {
        self.favoritePrimes.removeAll(where: { $0 == prime })
        self.activityFeed.append(Activity(timestamp: Date(), type: .removedFavoritePrime(prime)))
    }
    
    func removeFavoritePrime() {
        self.removeFavoritePrime(self.count)
    }
    
    func removeFavoritePrimes(at indexSet: IndexSet) {
        for index in indexSet {
            self.removeFavoritePrime(self.favoritePrimes[index])
        }
    }
}

PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView(state: AppState()).frame(width: 392.0, height: 740))

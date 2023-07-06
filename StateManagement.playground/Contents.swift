
import SwiftUI
import PlaygroundSupport
import Combine

// Combine으로부터 분리 + 값 타입으로 만들기 위해 AppState를 class -> struct로 변경
// 더 이상 @Published로 변수들을 선언하지 않아도 됨
// ObservableObject를 준수하기 위해서 구조체를 감싸는 클래스를 새로 선언해야함(Store)

struct AppState {
    var count = 0
    var favoritePrimes: [Int] = []
    var loggedInUser: User?
    var activityFeed: [Activity] = []
    
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


// Store 클래스의 역할: 값 유형을 래핑해서 관찰자에게 훅 제공
// AppState에 대해서는 알 필요가 없기 떄문에 제네릭 타입으로 선언
final class Store<Value, Action>: ObservableObject {
    let reducer: (inout Value, Action) -> Void
    @Published var value: Value
    
    init(initialValue: Value, reducer: @escaping (inout Value, Action) -> Void) {
      self.value = initialValue
      self.reducer = reducer
    }
    
    func send(_ action: Action) {
        self.reducer(&self.value, action)
    }
}
// Store<AppState>
// AppState에 변경이 발생하는 즉시 무언가 변경되었음을 알려주는 객체



// 사용자 액션 타입 지정
enum CounterAction {
    case decrementTapped
    case incrementTapped
}
enum PrimeModalAction {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}
enum FavoritePrimesAction {
    case deleteFavoritePrimes(IndexSet)
}
enum AppAction {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
    case favoritePrimes(FavoritePrimesAction)
}



//func appReducer(state: inout AppState, action: AppAction) -> Void {
//    switch action {
//    case .counter(.decrementTapped):
//        state.count -= 1
//    case .counter(.incrementTapped):
//        state.count += 1
//    case .primeModal(.saveFavoritePrimeTapped):
//        state.favoritePrimes.append(state.count)
//        state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))
//    case .primeModal(.removeFavoritePrimeTapped):
//        state.favoritePrimes.removeAll(where: { $0 == state.count })
//        state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))
//    case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
//        for index in indexSet {
//          let prime = state.favoritePrimes[index]
//          state.favoritePrimes.remove(at: index)
//          state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
//        }
//    }
//}


// appReducer 분리

// func counterReducer(state: inout AppState, action: AppAction) -> Void {
// state: inout AppState와 같이 전체 상태를 가져올 필요 없음
func counterReducer(state: inout Int, action: AppAction) -> Void {
  switch action {
  case .counter(.decrementTapped):
    // state.count -= 1
      state -= 1

  case .counter(.incrementTapped):
    state += 1

  default:
    break
  }
}

func primeModalReducer(state: inout AppState, action: AppAction) -> Void {
  switch action {
  case .primeModal(.saveFavoritePrimeTapped):
    state.favoritePrimes.append(state.count)
    state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))

  case .primeModal(.removeFavoritePrimeTapped):
    state.favoritePrimes.removeAll(where: { $0 == state.count })
    state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))

  default:
    break
  }
}


struct FavoritePrimesState {
    var favoritePrimes: [Int]
    var activityFeed: [AppState.Activity]
}


func favoritePrimesReducer(state: inout FavoritePrimesState, action: AppAction) -> Void {
  switch action {
  case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
    for index in indexSet {
      state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.favoritePrimes[index])))
      state.favoritePrimes.remove(at: index)
    }

  default:
    break
  }
}


func combine<Value, Action>(
    _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    
    return { value, action in
        for reducer in reducers {
            reducer(&value, action)
        }
    }
}


// pullback 정의
func pullback<LocalValue, GlobalValue, Action>(
    _ reducer: @escaping (inout LocalValue, Action) -> Void,
    // _ f: @escaping (GlobalValue) -> LocalValue  // LocalValue와 GlobalValue 제네릭 연결
    // get: @escaping (GlobalValue) -> LocalValue,
    // set: @escaping (inout GlobalValue, LocalValue) -> Void
    value: WritableKeyPath<GlobalValue, LocalValue>     // get, set KeyPath
) -> (inout GlobalValue, Action) -> Void {
    
    return { globalValue, action in
        // var localValue = get(globalValue)
        reducer(&globalValue[keyPath: value], action)
        // set(&globalValue, localValue)
    }
}


extension AppState {
    var favoritePrimesState: FavoritePrimesState {
        get {
            return FavoritePrimesState(favoritePrimes: self.favoritePrimes, activityFeed: self.activityFeed)
        }
        set {
            self.activityFeed = newValue.activityFeed
            self.favoritePrimes = newValue.favoritePrimes
        }
    }
}


let _appReducer = combine(
    pullback(counterReducer, value: \.count),
    primeModalReducer,
    pullback(favoritePrimesReducer, value: \.favoritePrimesState)
)

let appReducer = pullback(_appReducer, value: \.self)



// let state = AppState()
// print(counterReducer(state: state, action: .incrementTapped))

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


private func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}


private func isPrime (_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}



struct ContentView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    var body: some View {
        NavigationView {
            List{
                NavigationLink(destination: CounterView(store: self.store)) {
                    Text("Counter demo")
                }
                NavigationLink(
                    destination: FavoritePrimesView(
                        store: self.store,
                        favoritePrimes: self.$store.value.favoritePrimes,
                        activityFeed: self.$store.value.activityFeed
                    )
                ) {
                    Text("Favorite primes")
                }
            }
            .navigationTitle("State Management")
        }
    }
}


struct CounterView: View {
    // @State var count: Int = 0
    // @State: 상태가 업데이트 될 때마다 뷰 랜더링
    // 화면이 바뀌면(뒤로 가거나 다른 화면으로 넘어갈 때)상태가 저장되지 않음
    
    // @ObservedObject(AppState 클래스에서 ObservableObject 프로토콜 채택해야 함)
    @ObservedObject var store: Store<AppState, AppAction>
    // 모달 상태 추적(로컬)
    @State var isPrimeModalShown: Bool = false
    @State var alertNthPrime: Int?
    @State var isAlertShown = false
    @State var isNthPrimeButtonDisabled = false
    
    var body: some View {
        
        VStack {
            HStack {
                Button("-") {
                    // 상태 변화를 reducer에 격리하고, store에서 send 메서드를 호출하여 수행
                    // reducer를 거치지 않으면 앱의 상태를 변경하는 것이 불가능하게 할 수 있음
                    self.store.send(.counter(.decrementTapped))
                    // self.store.value = counterReducer(state: self.store.value, action: .decrementTapped)
                    // self.store.value.count -= 1}
                }
                Text("\(self.store.value.count)")
                Button("+") {
                    self.store.send(.counter(.incrementTapped))
                    // self.store.value = counterReducer(value: &self.store.value, action: .incrementTapped)
                }
            }
            Button (action: {self.isPrimeModalShown = true}) {
                Text("Is this prime?")
            }
            Button (action: self.nthPrimeButtonAction) {
                
                //                { self.isNthPrimeButtonDisabled = true
                //                  nthPrime(self.store.value.count) { prime in
                //                    self.alertNthPrime = prime
                //                    self.isAlertShown = true
                //                    self.isNthPrimeButtonDisabled = false }}
                
                Text("What is the \(ordinal(self.store.value.count)) prime?")
            }
            .disabled(self.isNthPrimeButtonDisabled)
        }
        .font(.title)
        .navigationTitle("Counter demo")
        .sheet(isPresented: $isPrimeModalShown, onDismiss: {
            self.isPrimeModalShown = false
        }) {
            IsPrimeModalView(store: self.store)
        }
        .alert(isPresented: $isAlertShown) {
            Alert(title: Text("The \(ordinal(self.store.value.count)) prime is API 대체"))
        }
    }
    func nthPrimeButtonAction() {
        self.isNthPrimeButtonDisabled = true
        nthPrime(self.store.value.count) { prime in
            self.alertNthPrime = prime
            self.isAlertShown = true
            self.isNthPrimeButtonDisabled = false
        }
    }
}

struct IsPrimeModalView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    var body: some View {
        VStack {
            if isPrime(self.store.value.count) {
                Text("\(self.store.value.count) is prime😻")
                if self.store.value.favoritePrimes.contains(self.store.value.count) {
                    Button("Remove to/from favorite primes") {
                        self.store.send(.primeModal(.removeFavoritePrimeTapped))
                    }
                } else {
                    Button("Save to favorite primes") {
                        self.store.send(.primeModal(.saveFavoritePrimeTapped))
                        }
                }
            } else {
                Text("\(self.store.value.count) is not prime👻")
            }
            
        }
    }
}



struct FavoritePrimesView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    @Binding var favoritePrimes: [Int]
    @Binding var activityFeed: [AppState.Activity]
    
    var body: some View {
        List {
            ForEach(self.store.value.favoritePrimes, id: \.self) { prime in
                Text("\(prime)")
            }.onDelete { indexSet in
                self.store.send(.favoritePrimes(.deleteFavoritePrimes(indexSet)))
            }
        }
        .navigationBarTitle(Text("Favorite Primes"))
    }
}

extension AppState {
    mutating func addFavoritePrime() {
        self.favoritePrimes.append(self.count)
        self.activityFeed.append(Activity(timestamp: Date(), type: .addedFavoritePrime(self.count)))
    }
    
    mutating func removeFavoritePrime(_ prime: Int) {
        self.favoritePrimes.removeAll(where: { $0 == prime })
        self.activityFeed.append(Activity(timestamp: Date(), type: .removedFavoritePrime(prime)))
    }
    
    mutating func removeFavoritePrime() {
        self.removeFavoritePrime(self.count)
    }
    
    mutating func removeFavoritePrimes(at indexSet: IndexSet) {
        for index in indexSet {
            self.removeFavoritePrime(self.favoritePrimes[index])
        }
    }
}

PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView(store: Store(initialValue: AppState(), reducer: appReducer)).frame(width: 392.0, height: 740))

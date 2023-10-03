//
//  ContentView.swift
//  PrimeTime
//
//  Created by yeonsu on 2023/08/15.
//
import SwiftUI
import Combine
import ComposableArchitecture
import FavoritePrimes
import Counter
import PrimeModal

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






// Store<AppState>
// AppState에 변경이 발생하는 즉시 무언가 변경되었음을 알려주는 객체



// 사용자 액션 타입 지정


enum AppAction {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
    case favoritePrimes(FavoritePrimesAction)
    
    // enum properties
    // 프로퍼티를 사용하는 경우 AppAction 열거형에 있는 모든 케이스의 관련 데이터에 대한 인스턴스 액세스 가능
    var counter: CounterAction? {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
        set {
            guard case .counter = self, let newValue = newValue else { return }
            self = .counter(newValue)
          }
    }
    var primeModal: PrimeModalAction? {
        get {
            guard case let .primeModal(value) = self else { return nil }
            return value
        }
        set {
            guard case .primeModal = self, let newValue = newValue else { return }
            self = .primeModal(newValue)
        }
    }
    var favoritePrimes: FavoritePrimesAction? {
        get {
            guard case let .favoritePrimes(value) = self else { return nil }
            return value
        }
        set {
            guard case .favoritePrimes = self, let newValue = newValue else { return }
            self = .favoritePrimes(newValue)
        }
    }
}

let someAction = AppAction.counter(.incrementTapped)
// someAction.counter  // Optional(incrememtTapped)
// someAction.favoritePrimes   // nil

// 각 열거형 케이스에 대한 key path를 얻을 수 있다
// \AppAction.counter  // WritableKeyPath<AppAction, CounterAction?>



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

// 만약 CounterAction 열거형에 새로운 액션을 추가하는 경우 default문 때문에 컴파일러 오류가 발생하지 않고, reducer에 해당하는 액션이 자동으로 무시됨 -> .counter 액션을 먼저 추출, action: AppAction -> CounterAction)






//struct FavoritePrimesState {
//    var favoritePrimes: [Int]
//    var activityFeed: [AppState.Activity]
//}








// pullback 정의
/* =========== < Before action pullback > ===========
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
*/



//extension AppState {
//    var favoritePrimesState: FavoritePrimesState {
//        get {
//            return FavoritePrimesState(favoritePrimes: self.favoritePrimes, activityFeed: self.activityFeed)
//        }
//        set {
//            self.activityFeed = newValue.activityFeed
//            self.favoritePrimes = newValue.favoritePrimes
//        }
//    }
//}


// 열거형에서의 keyPath 개념(컴파일러에서 자동 제공X, 비슷한 개념)
// key path의 핵심은 루트에서 값을 가져오는(get) 수단을 제공하고, 루트 내부에 값을 설정하여(set) 변경된 새로운 루트를 제공한다.
// 일부 열거형 유형의 경우 값을 가져와 열거형의 케이스 중 하나에 포함시키거나 열거형의 값을 가져와 케이스 중 하나에서 관련된 데이터를 추출할 수 있다.
struct EnumKeyPath<Root, Value> {
  let embed: (Value) -> Root
  let extract: (Root) -> Value?
}

// \AppAction.counter // EnumKeyPath<AppAction, CounterAction>

// 예를 들어 AppAction 열거형에서 케이스의 연관 데이터에서 값을 가져와서 열거형에 붙일 수 있다.
// AppAction.counter(CounterAction.incrementTapped)    // setter

// getter (열거형 값을 가져와서 특정 케이스의 값을 추출할 수 있다)
//let action = AppAction.favoritePrimes(.deleteFavoritePrimes([1]))
//let favoritePrimesAction: FavoritePrimesAction?
//switch action {
//case let .favoritePrimes(action):
//  favoritePrimesAction = action
//default:
//  favoritePrimesAction = nil
//}


func activityFeed(
    _ reducer: @escaping (inout AppState, AppAction) -> Void
) -> (inout AppState, AppAction) -> Void {
    
    return { state, action in
        switch action {
        case .counter(_):
            break
            
        case .primeModal(.removeFavoritePrimeTapped):
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))
            
        case .primeModal(.saveFavoritePrimeTapped):
            state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))
            
        case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
            for index in indexSet {
                state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.favoritePrimes[index])))
            }
        }
        reducer(&state, action)
    }
}


extension AppState {
    var primeModal: PrimeModalState {
        get {
            PrimeModalState(
                count: self.count,
                favoritePrimes: self.favoritePrimes
            )
        }
        set {
            self.count = newValue.count
            self.favoritePrimes = newValue.favoritePrimes
        }
    }
}
    

let _appReducer: (inout AppState, AppAction) -> Void = combine(
    pullback(counterReducer, value: \.count, action: \.counter),
    pullback(primeModalReducer, value: \.primeModal, action: \.primeModal),
    pullback(favoritePrimesReducer, value: \.favoritePrimes, action: \.favoritePrimes)
)
let appReducer = pullback(_appReducer, value: \.self, action: \.self)



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

// nthPrime(2) { p in print(p as Any) }
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
                NavigationLink(
                    "Counter demo",
                    destination: CounterView(
                        store: self.store.view(value: { ($0.count, $0.favoritePrimes)}, action: { $0 }
                                              )
                    )
                )
                NavigationLink(
                    destination: FavoritePrimesView(
                        store: self.store.view(
                              value: { $0.favoritePrimes },
                              action: { .favoritePrimes($0) }
                            )
                    )
                ) {
                    Text("Favorite primes")
                }
            }
            .navigationTitle("State Management")
        }
    }
}


typealias CounterViewState = (count: Int, favoritePrimes: [Int])
struct CounterView: View {
    // @State var count: Int = 0
    // @State: 상태가 업데이트 될 때마다 뷰 랜더링
    // 화면이 바뀌면(뒤로 가거나 다른 화면으로 넘어갈 때)상태가 저장되지 않음
    
    // @ObservedObject(AppState 클래스에서 ObservableObject 프로토콜 채택해야 함)
    @ObservedObject var store: Store<CounterViewState, AppAction>
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
            IsPrimeModalView(
                store: self.store .view(
                    value: { ($0.count, $0.favoritePrimes) },
                    action: { .primeModal($0) }
                )
            )
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(
                initialValue: AppState(),
                reducer: appReducer
                )
            )
    }
}

//
//  ComposableArchitecture.swift
//  ComposableArchitecture
//
//  Created by yeonsu on 2023/08/15.
//



// Store 클래스의 역할: 값 유형을 래핑해서 관찰자에게 훅 제공
// AppState에 대해서는 알 필요가 없기 떄문에 제네릭 타입으로 선언
public final class Store<Value, Action>: ObservableObject {
    private let reducer: (inout Value, Action) -> Void
    @Published public var value: Value
    
    public init(initialValue: Value, reducer: @escaping (inout Value, Action) -> Void) {
      self.value = initialValue
      self.reducer = reducer
    }
    
    public func send(_ action: Action) {
        self.reducer(&self.value, action)
        print("Action: \(action)")
        print("Value:")
        dump(self.value)
        print("---")
    }
}


public func combine<Value, Action>(
    _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    
    return { value, action in
        for reducer in reducers {
            reducer(&value, action)
        }
    }
}


/* =========== < After action pullback > =========== */
// Global action이 들어올 때 key path를 사용하여 Local Action을 추출하려고 시도
// -> 성공: reducer로 전달, 실패: 아무것도 안 함
public func pullback<GlobalValue, LocalValue, GlobalAction, LocalAction>(
    _ reducer: @escaping (inout LocalValue, LocalAction) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> (inout GlobalValue, GlobalAction) -> Void {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return }
        reducer(&globalValue[keyPath: value], localAction)
    }
}


public func logging<Value, Action>(
  _ reducer: @escaping (inout Value, Action) -> Void
) -> (inout Value, Action) -> Void {
  return { value, action in
    reducer(&value, action)
    print("Action: \(action)")
    print("State:")
    dump(value)
    print("---")
  }
}

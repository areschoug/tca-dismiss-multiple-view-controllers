import Combine
import ComposableArchitecture
import UIKit

@Reducer
struct FeatureA: Reducer {
	struct State: Equatable {
		@PresentationState var destination: Destination.State?
	}

	enum Action {
		case destination(PresentationAction<Destination.Action>)
		case viewWillAppear
		case buttonClicked
	}

	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .destination(.presented(.featureB(.destination(.presented(.featureC(.closeEverything)))))):
				state.destination = nil
				return .none
			case .destination:
				return .none
			case .viewWillAppear:
				return .none
			case .buttonClicked:
				state.destination = .featureB(FeatureB.State())
				return .none
			}
		}.ifLet(\.$destination, action: \.destination) {
			Destination()
		}
	}

	@Reducer
	struct Destination: Reducer {
		enum State: Equatable {
			case featureB(FeatureB.State)
		}

		enum Action {
			case featureB(FeatureB.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.featureB, action: \.featureB) {
				FeatureB()
			}
		}
	}
}

class ViewControllerA: UIViewController {
	let store: StoreOf<FeatureA>
	let viewStore: ViewStoreOf<FeatureA>

	var cancellables: Set<AnyCancellable> = []

	var button = UIButton(type: .system)

	required init?(coder: NSCoder) {
		let store = Store(initialState: FeatureA.State(), reducer: FeatureA.init)
		self.store = store
		viewStore = ViewStore(store, observe: { $0 })
		super.init(coder: coder)
	}

	deinit {
		print("ViewControllerA: deinit")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewStore.send(.viewWillAppear)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .white

		button.frame = .init(x: 10, y: 100, width: view.frame.width - 20, height: 44)
		button.setTitle("Present B", for: .normal)
		button.addAction(UIAction { [weak self] _ in
			self?.viewStore.send(.buttonClicked)
		}, for: .touchUpInside)
		view.addSubview(button)

		viewStore.publisher.$destination
			.removeDuplicates { $0.id == $1.id }
			.sink { [weak self] destinationState in
				guard let self else { return }

				switch destinationState.wrappedValue {
				case .featureB(let state):
					let viewControllerB = ViewControllerB(
						store: self.store.scope(state: {
							$0.destination?.featureB ?? state
						}, action: { childAction in
							.destination(.presented(.featureB(childAction)))
						}))

					self.present(viewControllerB, animated: true)
				case .none:
					self.dismiss(animated: true)
				}
			}.store(in: &cancellables)
	}
}

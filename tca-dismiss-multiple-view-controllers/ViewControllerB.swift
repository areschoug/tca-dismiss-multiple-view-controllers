import Combine
import ComposableArchitecture
import UIKit

@Reducer
struct FeatureB: Reducer {
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
			case .destination:
				return .none
			case .viewWillAppear:
				return .none
			case .buttonClicked:
				state.destination = .featureC(FeatureC.State())
				return .none
			}
		}.ifLet(\.$destination, action: \.destination) {
			Destination()
		}
	}

	@Reducer
	struct Destination: Reducer {
		enum State: Equatable {
			case featureC(FeatureC.State)
		}

		enum Action {
			case featureC(FeatureC.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.featureC, action: \.featureC) {
				FeatureC()
			}
		}
	}
}

class ViewControllerB: UIViewController {
	let store: StoreOf<FeatureB>
	let viewStore: ViewStoreOf<FeatureB>
	let button = UIButton(type: .system)

	var cancellables: Set<AnyCancellable> = []

	init(store: StoreOf<FeatureB>) {
		self.store = store
		viewStore = ViewStore(store, observe: { $0 })
		super.init(nibName: nil, bundle: nil)
		modalPresentationStyle = .fullScreen
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		print("ViewControllerB: deinit")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewStore.send(.viewWillAppear)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .systemPink

		button.frame = .init(x: 10, y: 100, width: view.frame.width - 20, height: 44)
		button.setTitle("Present C", for: .normal)
		button.addAction(UIAction { [weak self] _ in
			self?.viewStore.send(.buttonClicked)
		}, for: .touchUpInside)
		view.addSubview(button)

		viewStore.publisher.$destination
			.removeDuplicates { $0.id == $1.id }
			.sink { [weak self] destinationState in
				guard let self else { return }
				
				switch destinationState.wrappedValue {
				case .featureC(let state):
					let viewControllerC = ViewControllerC(store:
						self.store.scope(state: {
							$0.destination?.featureC ?? state
						}, action: {
							.destination(.presented(.featureC($0)))
						}))

					self.present(viewControllerC, animated: true)
				case .none:
					self.dismiss(animated: true)
				}
			}.store(in: &cancellables)
	}
}

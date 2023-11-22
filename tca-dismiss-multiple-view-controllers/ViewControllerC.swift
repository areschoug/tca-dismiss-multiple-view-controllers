import Combine
import ComposableArchitecture
import UIKit

@Reducer
struct FeatureC: Reducer {
	struct State: Equatable {}

	enum Action {
		case viewWillAppear
		case buttonClicked
		case closeEverything
	}

	var body: some ReducerOf<Self> {
		Reduce { _, action in
			switch action {
			case .viewWillAppear:
				return .none
			case .buttonClicked:
				return .send(.closeEverything)
			case .closeEverything:
				return .none
			}
		}
	}
}

class ViewControllerC: UIViewController {
	let store: StoreOf<FeatureC>
	let viewStore: ViewStoreOf<FeatureC>

	let button = UIButton(type: .system)

	init(store: StoreOf<FeatureC>) {
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
		print("ViewControllerC: deinit")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemYellow

		button.frame = .init(x: 10, y: 100, width: view.frame.width - 20, height: 44)
		button.setTitle("Close everything", for: .normal)
		button.addAction(UIAction { [weak self] _ in
			self?.viewStore.send(.buttonClicked)
		}, for: .touchUpInside)
		view.addSubview(button)
	}
}

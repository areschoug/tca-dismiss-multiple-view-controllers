import Foundation

// The content of this file is copied from the ComposableArchitecture library (because it’s not public),
// and we need the `PresentationState.id` property for our `ViewController.present` TCA conveniences.
@_spi(Reflection) import CasePaths
@_spi(Internals) import ComposableArchitecture
extension PresentationState {
	var id: PresentationID? {
		wrappedValue.map(PresentationID.init(base:))
	}
}

struct PresentationID: Hashable, Sendable {
	private let identifier: AnyHashableSendable?
	private let tag: UInt32?
	private let type: Any.Type
	init<Base>(base: Base) {
		tag = EnumMetadata(Base.self)?.tag(of: base)
		if let id = _identifiableID(base) ?? EnumMetadata.project(base).flatMap(_identifiableID) {
			identifier = AnyHashableSendable(id)
		} else {
			identifier = nil
		}
		type = Base.self
	}

	var id: Self { self }
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.identifier == rhs.identifier
			&& lhs.tag == rhs.tag
			&& lhs.type == rhs.type
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(identifier)
		hasher.combine(tag)
		hasher.combine(ObjectIdentifier(type))
	}
}

public struct AnyHashableSendable: Hashable, @unchecked Sendable {
	public let base: AnyHashable
	init<Base: Hashable & Sendable>(_ base: Base) {
		self.base = base
	}
}

func _identifiableID(_ value: Any) -> AnyHashable? {
	func open(_ value: some Identifiable) -> AnyHashable {
		value.id
	}
	guard let value = value as? any Identifiable else { return nil }
	return open(value)
}

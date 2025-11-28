import Foundation

/// Canonical destinations that the app can deep link to from widgets, Siri, or URLs.
public enum DeepLinkDestination: Equatable, Sendable {
    public enum PlantTab: String, Sendable {
        case overview
        case watering
        case diagnostics
        case diary
    }

    case garden
    case plantDetail(id: UUID, tab: PlantTab? = nil)
    case createPlant
    case watering(plantID: UUID?)
    case diagnostics(plantID: UUID?)

    /// URL used to open the destination from widgets.
    public var url: URL {
        var components = URLComponents()
        components.scheme = "grobro"

        switch self {
        case .garden:
            components.host = "garden"
        case .createPlant:
            components.host = "create-plant"
        case let .plantDetail(id, tab):
            components.host = "plant"
            components.path = "/\(id.uuidString)"
            if let tab {
                components.queryItems = [
                    URLQueryItem(name: "tab", value: tab.rawValue)
                ]
            }
        case let .watering(plantID):
            components.host = "watering"
            if let plantID {
                components.path = "/\(plantID.uuidString)"
            }
        case let .diagnostics(plantID):
            components.host = "diagnostics"
            if let plantID {
                components.path = "/\(plantID.uuidString)"
            }
        }

        return components.url ?? URL(string: "grobro://garden")!
    }

    /// Attempts to parse a destination from a URL that uses the `grobro://` scheme.
    public init?(url: URL) {
        guard url.scheme == "grobro" else { return nil }
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "garden":
            self = .garden
        case "create-plant":
            self = .createPlant
        case "plant":
            guard let idComponent = pathComponents.first,
                  let uuid = UUID(uuidString: idComponent) else {
                return nil
            }
            let tabValue = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first { $0.name == "tab" }?
                .value
            let tab = tabValue.flatMap(PlantTab.init(rawValue:))
            self = .plantDetail(id: uuid, tab: tab)
        case "watering":
            let uuid = pathComponents.first.flatMap(UUID.init(uuidString:))
            self = .watering(plantID: uuid)
        case "diagnostics":
            let uuid = pathComponents.first.flatMap(UUID.init(uuidString:))
            self = .diagnostics(plantID: uuid)
        default:
            return nil
        }
    }
}

import Foundation

/// Client for interacting with the (unofficial) AC Infinity cloud API.
/// All calls are async/await and return simple domain models.
@MainActor
public final class ACInfinityAPIClient {

    public enum APIError: Error {
        case invalidResponse
        case unauthorized
        case rateLimited
        case decodingFailed
    }

    private struct LoginRequest: Encodable {
        let email: String
        let password: String
    }

    private struct LoginResponse: Decodable {
        let token: String
    }

    private struct DevicesResponse: Decodable {
        let devices: [DevicePayload]
    }

    private struct DevicePayload: Decodable {
        let id: String
        let name: String
        let type: String
    }

    private struct SensorResponse: Decodable {
        let temperature: Double
        let humidity: Double
        let vpd: Double
    }

    private let session: URLSession
    private let baseURL = URL(string: "https://api.acinfinity.com/api")!

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Logs in with email/password and returns an auth token.
    public func login(email: String, password: String) async throws -> String {
        let url = baseURL.appendingPathComponent("user/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response)

        guard let login = try? JSONDecoder().decode(LoginResponse.self, from: data) else {
            throw APIError.decodingFailed
        }

        return login.token
    }

    /// Fetches all devices for the authenticated user.
    public func fetchDevices(token: String) async throws -> [ACInfinityAPIDevice] {
        let url = baseURL.appendingPathComponent("user/devices")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response)

        guard let decoded = try? JSONDecoder().decode(DevicesResponse.self, from: data) else {
            throw APIError.decodingFailed
        }

        return decoded.devices.map { ACInfinityAPIDevice(id: $0.id, name: $0.name, type: $0.type) }
    }

    /// Fetches sensor readings for a specific device.
    public func fetchSensorReading(token: String, deviceId: String) async throws -> ACInfinitySensorReading {
        let url = baseURL.appendingPathComponent("device/\(deviceId)/sensors")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response)

        guard let decoded = try? JSONDecoder().decode(SensorResponse.self, from: data) else {
            throw APIError.decodingFailed
        }

        return ACInfinitySensorReading(
            temperatureFahrenheit: decoded.temperature,
            humidityPercent: decoded.humidity,
            vpdKilopascal: decoded.vpd
        )
    }

    private static func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200..<300:
            return
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.invalidResponse
        }
    }
}

// MARK: - DeviceIntegrationClient Conformance

extension ACInfinityAPIClient: DeviceIntegrationClient {
    public func authenticate(email: String, password: String) async throws -> String {
        try await login(email: email, password: password)
    }
}

import Foundation

public protocol VivosunAPIProviding: Sendable {
    func authenticate(email: String, password: String) async throws -> String
    func fetchDevices(token: String) async throws -> [VivosunDevice]
    func fetchSensorReading(token: String, deviceId: String) async throws -> VivosunSensorReading
}

/// Client responsible for communicating with the (unofficial) Vivosun SmartGrow API.
public final class VivosunAPIClient: DeviceIntegrationClient, VivosunAPIProviding, Sendable {

    public enum APIError: Error, LocalizedError {
        case invalidResponse
        case unauthorized
        case rateLimited
        case decodingFailed

        public var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "The Vivosun service returned an unexpected response."
            case .unauthorized:
                return "Invalid Vivosun credentials."
            case .rateLimited:
                return "Vivosun temporarily rate limited the request. Try again later."
            case .decodingFailed:
                return "Unable to decode Vivosun response."
            }
        }
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
        let location: String?
        let status: String?
    }

    private struct SensorResponse: Decodable {
        let temperatureFahrenheit: Double?
        let humidityPercent: Double?
        let vpd: Double?

        enum CodingKeys: String, CodingKey {
            case temperatureFahrenheit = "temperature_f"
            case humidityPercent = "humidity_percent"
            case vpd
        }
    }

    private let session: URLSession
    private let baseURL = URL(string: "https://api.vivosun.com/v1")!

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - DeviceIntegrationClient

    public func authenticate(email: String, password: String) async throws -> String {
        try await login(email: email, password: password)
    }

    public func fetchDevices(token: String) async throws -> [VivosunDevice] {
        let url = baseURL.appendingPathComponent("devices")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response)

        guard let decoded = try? JSONDecoder().decode(DevicesResponse.self, from: data) else {
            throw APIError.decodingFailed
        }

        return decoded.devices.map { payload in
            VivosunDevice(
                id: payload.id,
                name: payload.name,
                deviceType: VivosunDevice.DeviceType(rawValue: payload.type.lowercased()) ?? .unknown,
                location: payload.location,
                isOnline: (payload.status ?? "").lowercased() == "online"
            )
        }
    }

    public func fetchSensorReading(token: String, deviceId: String) async throws -> VivosunSensorReading {
        let url = baseURL.appendingPathComponent("devices/\(deviceId)/sensors")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response)

        guard let decoded = try? JSONDecoder().decode(SensorResponse.self, from: data) else {
            throw APIError.decodingFailed
        }

        return VivosunSensorReading(
            temperatureFahrenheit: decoded.temperatureFahrenheit,
            humidityPercent: decoded.humidityPercent,
            vpdKilopascal: decoded.vpd
        )
    }

    // MARK: - Private

    private func login(email: String, password: String) async throws -> String {
        let url = baseURL.appendingPathComponent("auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LoginRequest(email: email, password: password))

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response)

        guard let login = try? JSONDecoder().decode(LoginResponse.self, from: data) else {
            throw APIError.decodingFailed
        }

        return login.token
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

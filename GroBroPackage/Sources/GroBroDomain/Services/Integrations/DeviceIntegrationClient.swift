import Foundation

/// Protocol describing the operations required from an environmental device integration client.
public protocol DeviceIntegrationClient {
    associatedtype Device: Identifiable & Sendable
    associatedtype Reading: Sendable

    func authenticate(email: String, password: String) async throws -> String
    func fetchDevices(token: String) async throws -> [Device]
    func fetchSensorReading(token: String, deviceId: String) async throws -> Reading
}

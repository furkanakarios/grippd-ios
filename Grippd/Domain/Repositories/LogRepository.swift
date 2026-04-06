import Foundation

protocol LogRepositoryProtocol {
    func fetchLogs(contentKey: String) async throws -> [LogEntry]
    func addLog(_ entry: LogEntry) async throws
    func deleteLog(id: String) async throws
}

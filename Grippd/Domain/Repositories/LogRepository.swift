import Foundation

protocol LogRepositoryProtocol {
    func fetchLogs(userID: UUID, contentID: UUID?) async throws -> [LogEntry]
    func addLog(_ entry: LogEntry) async throws -> LogEntry
    func updateLog(_ entry: LogEntry) async throws -> LogEntry
    func deleteLog(id: UUID) async throws
}

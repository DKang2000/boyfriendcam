import Foundation

actor SessionStore {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let rootDirectoryURL: URL
    private let historyFileURL: URL
    private let capturesDirectoryURL: URL

    init(rootDirectoryURL: URL? = nil) {
        let baseURL = rootDirectoryURL ?? Self.defaultRootDirectoryURL()

        self.rootDirectoryURL = baseURL
        historyFileURL = baseURL.appendingPathComponent("session-history.json")
        capturesDirectoryURL = baseURL.appendingPathComponent("captures", isDirectory: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    static func defaultRootDirectoryURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BoyfriendCamNative", isDirectory: true)
    }

    static func capturesDirectoryURL() -> URL {
        defaultRootDirectoryURL().appendingPathComponent("captures", isDirectory: true)
    }

    func loadSessions() throws -> [CaptureSessionRecord] {
        try ensureDirectories()

        guard FileManager.default.fileExists(atPath: historyFileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: historyFileURL)
        let sessions = try decoder.decode([CaptureSessionRecord].self, from: data)
        return sessions.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func saveSession(_ session: CaptureSessionRecord) throws {
        var sessions = try loadSessions()

        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }

        try persist(sessions)
    }

    func deleteSession(id: UUID) throws {
        var sessions = try loadSessions()

        guard let index = sessions.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = sessions.remove(at: index)
        try persist(sessions)

        for frame in removed.frames {
            try? FileManager.default.removeItem(at: frame.fileURL)
        }
    }

    private func persist(_ sessions: [CaptureSessionRecord]) throws {
        try ensureDirectories()
        let signpost = PerformanceSignposts.beginInterval("history_write")
        defer { PerformanceSignposts.endInterval("history_write", signpost) }

        let data = try encoder.encode(sessions.sorted(by: { $0.createdAt > $1.createdAt }))
        try data.write(to: historyFileURL, options: .atomic)
    }

    private func ensureDirectories() throws {
        try FileManager.default.createDirectory(
            at: rootDirectoryURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: capturesDirectoryURL,
            withIntermediateDirectories: true
        )
    }
}

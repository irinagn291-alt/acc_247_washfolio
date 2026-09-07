import Foundation

/// Role: Year document. Typed transport failures. This product has no remote catalog.
enum FolioClientError: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Year document. Sends one HTTP request. Injected so tests never hit the network.
protocol FolioTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Year document. URLSession-backed transport with a 15 s timeout and the app User-Agent.
struct FolioSessionTransport: FolioTransport {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": FolioClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Year document. Accepts a JSON number or a numeric string. Missing values stay nil.
struct FlexibleDouble: Sendable, Equatable {
    var value: Double?
}

extension FlexibleDouble: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Role: Year document. Owns URLSession. Offline folio; this is the transport seam only.
actor FolioClient {
    static let userAgent = "Washfolio/1.0 (iOS; +https://washfolio.pro)"

    private let transport: any FolioTransport

    init(transport: any FolioTransport) {
        self.transport = transport
    }

    init() {
        self.transport = FolioSessionTransport()
    }

    func getJSON<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let data = try await fetch(makeRequest(url: url))
        do {
            return try JSONDecoder().decode(DTO.self, from: data)
        } catch is CancellationError {
            throw FolioClientError.cancelled
        } catch {
            throw FolioClientError.decoding
        }
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let error as FolioClientError {
            throw error
        } catch is CancellationError {
            throw FolioClientError.cancelled
        } catch {
            if isCancelled(error) {
                throw FolioClientError.cancelled
            }
            guard isTransient(error) else { throw FolioClientError.transport }
            do {
                return try await send(request)
            } catch let error as FolioClientError {
                throw error
            } catch is CancellationError {
                throw FolioClientError.cancelled
            } catch {
                if isCancelled(error) { throw FolioClientError.cancelled }
                throw FolioClientError.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FolioClientError.invalidResponse
        }
        if http.statusCode == 404 {
            throw FolioClientError.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw FolioClientError.transport
        }
        return data
    }
}

private func isTransient(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .notConnectedToInternet,
         .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

private func isCancelled(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    return (error as? URLError)?.code == .cancelled
}

import Foundation
import HTTPUtils

final class HTTPClientSpy: HTTPClient {
    private var stubs = [Result]()
    private(set) var messages = [Message]()
    
    enum Message: Equatable {
        case execute(EQRequest)
    }
    
    func stub(_ result: HTTPClient.Result) {
        stubs.append(result)
    }
    
    func execute(request: URLRequest) async throws -> Response {
        messages.append(.execute(.wrap(request)))
        return try stubs[messages.count - 1].get()
    }
}

extension HTTPClientSpy.Message: CustomStringConvertible {
    var description: String {
        switch self {
        case let .execute(request): return "execute(\(request.url.absoluteString))"
        }
    }
}

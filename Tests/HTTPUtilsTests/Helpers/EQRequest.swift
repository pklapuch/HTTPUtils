import Foundation

/// Equatable wrapper for `URLSession`
/// Compares `url` and `httpMethod`
///
struct EQRequest: Equatable {
    private(set) var request: URLRequest
    
    init(_ request: URLRequest) {
        self.request = request
    }
    
    static func wrap(_ request: URLRequest) -> EQRequest {
        return EQRequest(request)
    }
    
    var url: URL {
        return request.url!
    }
    
    static func ==(lhs: EQRequest, rhs: EQRequest) -> Bool {
        guard lhs.request.url == rhs.request.url else { return false }
        guard lhs.request.httpMethod == rhs.request.httpMethod else { return false }
        return true
    }
}


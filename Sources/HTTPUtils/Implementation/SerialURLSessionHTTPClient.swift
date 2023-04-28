//
//  SerialURLSessionHTTPClient.swift
//  
//
//  Created by Pawel Klapuch on 4/28/23.
//

import Foundation

public actor SerialURLSessionHTTPClient: HTTPClient {
    private typealias URLSessionResponse = (data: Data, urlResponse: URLResponse)
    
    private let session: URLSession
    private var operations = [CancellableOperation]()
    private var currentTask: Task<Void, Never>?
    
    public struct UnexpectedResponseRepresentation: Error {
        public init() { }
    }
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func execute(request: URLRequest) async throws -> Response {
        let operation = CancellableOperation(session: session, request: request)
        operations.append(operation)
        
        return try await withTaskCancellationHandler(operation: {
            return try await withCheckedThrowingContinuation { continuation in
                Task {
                    await operation.setContinuation(continuation)
                    startNextOperation()
                }
            }
        }, onCancel: {
            Task {
                await currentTask?.cancel()
                for operation in (await operations) {
                    await operation.cancel()
                }
            }
        })
    }
    
    private func startNextOperation() {
        guard currentTask == nil else { return }
        guard !operations.isEmpty else { return }
        
        let operation = operations.removeFirst()
        
        currentTask = Task {
            await operation.start()
            currentTask = nil
            startNextOperation()
        }
    }

    private static func parse(_ resopnse: URLSessionResponse) throws -> Response {
        guard let httpResponse = resopnse.urlResponse as? HTTPURLResponse else {
            throw URLSessionHTTPClient.UnexpectedResponseRepresentation()
        }
        
        return (resopnse.data, httpResponse)
    }
}

private actor CancellableOperation {
    private typealias URLSessionResponse = (data: Data, urlResponse: URLResponse)
    
    private let session: URLSession
    private let request: URLRequest
    
    private var completed = false
    private var continuation: CheckedContinuation<HTTPClient.Response, Error>?
    
    
    init(session: URLSession, request: URLRequest) {
        self.session = session
        self.request = request
    }
    
    func setContinuation(_ continuation: CheckedContinuation<HTTPClient.Response, Error>) {
        self.continuation = continuation
    }
    
    func start() async {
        guard !completed else {
            complete(with: .failure(cancelledError))
            return
        }
        
        do {
            let response = try await session.data(for: request)
            complete(with: .success(try Self.parse(response)))
        } catch {
            complete(with: .failure(error))
        }
    }
    
    func cancel() {
        guard !completed else { return }
        completed = true
        
        print("cancel: \(request.url?.absoluteString ?? "--")")
        continuation?.resume(throwing: cancelledError)
    }
    
    private func complete(with result: HTTPClient.Result) {
        guard !completed else { return }
        completed = true
        
        continuation?.resume(with: result)
    }

    private static func parse(_ resopnse: (data: Data, urlResponse: URLResponse)) throws -> HTTPClient.Response {
        guard let httpResponse = resopnse.urlResponse as? HTTPURLResponse else {
            throw URLSessionHTTPClient.UnexpectedResponseRepresentation()
        }
        
        return (resopnse.data, httpResponse)
    }
    
    private var cancelledError: Error {
        return NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
    }
}

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
    
    private var currentTaskID: UUID?
    private var currentTask: Task<Void, Never>?
    
    public struct UnexpectedResponseRepresentation: Error {
        public init() { }
    }
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func execute(request: URLRequest) async throws -> Response {
        let uuid = UUID()
        let operation = CancellableOperation(uuid: uuid, session: session, request: request)
        operations.append(operation)
        
        return try await withTaskCancellationHandler(operation: {
            return try await withCheckedThrowingContinuation { continuation in
                Task {
                    await operation.setContinuation(continuation)
                    startNextOperation()
                }
            }
        }, onCancel: {
            Task { await didCancelTask(with: uuid) }
        })
    }
    
    private func startNextOperation() {
        guard currentTask == nil else { return }
        guard !operations.isEmpty else { return }
        
        let operation = operations.removeFirst()
        currentTaskID = operation.uuid
        currentTask = Task {
            await operation.start()
            currentTask = nil
            startNextOperation()
        }
    }
    
    private func didCancelTask(with id: UUID) async {
        if currentTaskID == id {
            currentTask?.cancel()
        } else if let index = operations.firstIndex(where: { $0.uuid == id }) {
            await operations[index].cancel()
            operations.remove(at: index)
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
    
    let uuid: UUID
    private let session: URLSession
    private let request: URLRequest
    
    private var completed = false
    private var continuation: CheckedContinuation<HTTPClient.Response, Error>?
    
    init(uuid: UUID, session: URLSession, request: URLRequest) {
        self.uuid = uuid
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

//
//  HTTPClientWithContinuationSpy.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation
import HTTPUtils

actor HTTPClientWithContinuationSpy: HTTPClient {
    typealias OperationIndex = Int
    
    private var executeContinuations = [ContinuationWrapper]()
    private var executeObserver: ((URLRequest, OperationIndex) -> Void)?
    private var cancelObserer: ((URLRequest) -> Void)?
    private(set) var messages = [Message]()
    
    enum Message: Equatable {
        case execute(EQRequest)
    }
    
    func observeExecute(_ block: @escaping (URLRequest, OperationIndex) -> Void) {
        executeObserver = block
    }
    
    func observeCancel(_ block: @escaping (URLRequest) -> Void) {
        cancelObserer = block
    }
    
    func completeExecute(with result: HTTPClient.Result, at index: Int = 0) {
        Task { await executeContinuations[index].resume(with: result) }
    }
    
    func execute(request: URLRequest) async throws -> HTTPClient.Response {
        messages.append(.execute(.wrap(request)))
        let wrapper = ContinuationWrapper()

        return try await withTaskCancellationHandler(operation: {
            return try await withCheckedThrowingContinuation { continuation in
                Task {
                    await wrapper.start(withContinuation: continuation)
                    executeContinuations.append(wrapper)
                    executeObserver?(request, executeContinuations.count - 1)
                }
            }
        }, onCancel: {
            Task {
                await wrapper.cancel(NSError(domain: "cancelled", code: 0))
                await cancelObserer?(request)
            }
        })
    }
    
    func reset() {
        messages.removeAll()
        executeContinuations.removeAll()
        executeObserver = nil
    }
}

extension HTTPClientWithContinuationSpy.Message: CustomStringConvertible {
    var description: String {
        switch self {
        case let .execute(request): return "execute(\(request.url.absoluteString))"
        }
    }
}

private actor ContinuationWrapper {
    typealias Continuation = CheckedContinuation<HTTPClient.Response, Error>

    private(set) var taskContinuation: Continuation?
    private var completed = false

    func start(withContinuation continuation: Continuation) {
        taskContinuation = continuation
    }

    func resume(with result: Result<HTTPClient.Response, Error>) {
        guard !completed else { return }
        completed = true
        taskContinuation?.resume(with: result)
    }

    func cancel(_ error: Error) {
        guard !completed else { return }
        completed = true
        taskContinuation?.resume(throwing: error)
    }
}

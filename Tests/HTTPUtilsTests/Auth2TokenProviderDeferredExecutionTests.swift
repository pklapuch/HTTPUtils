//
//  Auth2TokenProviderDeferredExecutionTests.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import XCTest

final class Auth2TokenProviderDeferredExecutionTests: XCTestCase {
    /// Test 1
    /// Ensure that when `getToken` is called while `refresh token` is being execute, `getToken` method does not return until `refresh token` operation has completed
    
    /// Test 2
    /// Ensure that when `refreshToken` is called while there is already `refresh token` in progress, method waits for completion of current `refresh token` operation
    
    /// Test 3
    /// Ensure that when`cancelRefreshToken` is called while `refresh token` is in progress, `refresh token` task gets cancelled
}

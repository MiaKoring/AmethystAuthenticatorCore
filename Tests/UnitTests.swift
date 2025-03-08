//
//  UnitTests.swift
//  AmethystAuthenticatorCore
//
//  Created by Mia Koring on 08.03.25.
//

import XCTest
@testable import AmethystAuthenticatorCore

class UnitTests: XCTestCase {
    func testCheckAllowedUsername() throws {
        do {
            //succeeds if it doesn't throw
            try Account.checkUsername(username: "tester",
                                      service: "amethystbrowser.de",
                                      allAccounts: [Account(service: "google.com", username: "tester", totp: false)])
        } catch {
            XCTFail()
        }
    }
    
    func testCheckForbiddenSuffixUsername() throws {
        do {
            try Account.checkUsername(username: "tester({#totp})",
                                      service: "amethystbrowser.de",
                                      allAccounts: [Account(service: "google.com", username: "tester", totp: false)])
            XCTFail("should have thrown")
        } catch {
            guard let error = error as? AAuthenticationError else {
                XCTFail("Only a AAuthenticationError should be thrown here")
                return
            }
            XCTAssertTrue(error == AAuthenticationError.usernameHasReservedSuffix)
        }
    }
    
    func testCheckDuplicateUsernameOnService() throws {
        do {
            try Account.checkUsername(username: "tester",
                                      service: "amethystbrowser.de",
                                      allAccounts: [Account(service: "amethystbrowser.de", username: "tester", totp: false)])
            XCTFail("should have thrown")
        } catch {
            guard let error = error as? AAuthenticationError else {
                XCTFail("Only a AAuthenticationError should be thrown here")
                return
            }
            XCTAssertTrue(error == AAuthenticationError.usernameAlreadyInUseOnService)
        }
    }
}

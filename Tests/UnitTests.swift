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
                                      allAccounts: [Account(service: "google.com", username: "tester", totp: false, strength: 0.7)])
            XCTFail("should have thrown")
        } catch {
            guard let error = error as? AAuthenticationError else {
                XCTFail("Only a AAuthenticationError should be thrown here")
                return
            }
            XCTAssertTrue(error == AAuthenticationError.usernameHasReservedSuffix)
        }
    }
    
    func testTitleFetch() async throws {
        let title = try await Account.getTitle(from: "google.com")
        XCTAssertTrue(title == "Google")
    }
    
    
    func testFaviconFetch() async throws {
        let image = try await Account.getImage(for: "google.com")
        XCTAssertTrue(image != nil)
    }
    
    func testCheckDuplicateUsernameOnService() throws {
        do {
            try Account.checkUsername(username: "tester",
                                      service: "amethystbrowser.de",
                                      allAccounts: [Account(service: "amethystbrowser.de", username: "tester", totp: false, strength: 0.7)])
            XCTFail("should have thrown")
        } catch {
            guard let error = error as? AAuthenticationError else {
                XCTFail("Only a AAuthenticationError should be thrown here")
                return
            }
            XCTAssertTrue(error == AAuthenticationError.usernameAlreadyInUseOnService)
        }
    }
    
    func testCheckDuplicateUsernameOnServiceWithIDExclusion() throws {
        do {
            let account = Account(service: "amethystbrowser.de", username: "tester", totp: false, strength: 0.7)
            try Account.checkUsername(username: "tester",
                                      service: "amethystbrowser.de",
                                      allAccounts: [account], excludedID: account.id)
        } catch {
            XCTFail("shouldn't throw")
        }
    }
    
    func testPasswordGenerator() {
        let generator = PasswordGenerator()
        let password = generator.generatePassword()
        print(password)
        let segmentlessPassword = generator.generatePassword(insertSegments: false)
        print(segmentlessPassword)
        XCTAssertTrue(generator.isValidPassword(segmentlessPassword))
        XCTAssertTrue(generator.isValidPassword(password))
    }
    
    func testIsValidPassword() {
        let generator = PasswordGenerator()
        XCTAssertFalse(generator.isValidPassword("aBadjp-"))
        XCTAssertTrue(generator.isValidPassword("aB1"))
    }
}

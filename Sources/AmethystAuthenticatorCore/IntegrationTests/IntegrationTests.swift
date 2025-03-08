//
//  IntegrationTests.swift
//  AmethystAuthenticatorCore
//
//  Created by Mia Koring on 08.03.25.
//

import SwiftData
import KeychainAccess

public typealias IntegrationtTestResult = Result<Bool, AIntegrationTestError>

public class IntegrationTests {
    var modelContainer: ModelContainer
    let testUsername = "tester"
    let testSite = "test.com"
    let testPassword = "test123"
    let testNotes = "testnotes"
    let testTotpSecret = "JBSWY3DPEHPK3PXP"
    let newTestTotpSecret = "5QXK64OSGNYKX75R"
    let testAccountsWithoutCollision = [
        Account(service: "google.com", username: "tester", totp: false)
    ]
    var testAccountsWithCollision: [Account] {
        [Account(service: testSite, username: testUsername, totp: false)]
    }
    
    public init() {
        self.modelContainer = try! ModelContainer(for: Account.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
    
    public func tearDown() async throws {
        try modelContainer.erase()
        let keychain = Keychain.create(for: testSite)
        try keychain.removeAll()
    }
    
    func testAccountCreationWithoutCollision() throws {
        let _ = try Account(service: testSite,
                          username: testUsername,
                          notes: testNotes,
                          password: testPassword,
                          allAccounts: testAccountsWithoutCollision)
    }
    
    func testAccountCreationWithCollision() throws {
        do {
            let _ = try Account(service: testSite,
                                username: testUsername,
                                notes: testNotes,
                                password: testPassword,
                                allAccounts: testAccountsWithCollision)
        } catch {
            guard let error = error as? AAuthenticationError else {
                throw AIntegrationTestError.withMessage("unexpected error: \(error)")
            }
            try assertTrue(error == AAuthenticationError.usernameAlreadyInUseOnService, messageOnFail: "Wrong error")
        }
    }
    
    func testAccountCreationWithSuffix() throws {
        do {
            let _ = try Account(service: testSite,
                                username: testUsername + "({#totp})",
                                notes: testNotes,
                                password: testPassword,
                                allAccounts: testAccountsWithoutCollision)
            try assertTrue(false, messageOnFail: "Didn't throw")
        } catch {
            guard let error = error as? AAuthenticationError else {
                throw AIntegrationTestError.withMessage("unexpected error: \(error)")
            }
            try assertTrue(error == AAuthenticationError.usernameHasReservedSuffix, messageOnFail: "Wrong error")
        }
    }
    
    @MainActor
    func testAccountProperties() throws {
        let acc = try Account(service: testSite,
                          username: testUsername,
                          notes: testNotes,
                          password: testPassword,
                          allAccounts: testAccountsWithoutCollision)
        //test after initialization
        try assertTrue(acc.password == testPassword, messageOnFail: "Password not equal")
        
        //set totp secret and verify
        acc.setTOTPSecret(to: testTotpSecret)
        print("\n\nTOTP-Code:\(acc.getCurrentTOTPCode() ?? "Empty")")
        try assertTrue(acc.getTOTPSecret() == testTotpSecret, messageOnFail: "TOTP Code is empty")
        
        //change username and check everything still is accessible
        try acc.setUsername(to: "\(testUsername)1", allAccounts: testAccountsWithoutCollision, context: modelContainer.mainContext)
        try assertTrue(acc.password == testPassword, messageOnFail: "stored and expected password are different after username change")
        print("\n\nTOTP-Code:\(acc.getCurrentTOTPCode() ?? "Empty")")
        try assertTrue(acc.getTOTPSecret() == testTotpSecret, messageOnFail: "stored and expected totp secret are different after username change")
        
        //test removing totp secret works
        acc.removeTOTPSecret()
        try assertTrue(acc.getTOTPSecret() == nil, messageOnFail: "Failed to remove totp secret")
        
        //test changing totp secret works
        acc.setTOTPSecret(to: newTestTotpSecret)
        try assertTrue(acc.getTOTPSecret() == newTestTotpSecret, messageOnFail: "stored and expected totp are different after totp change")
        
        //test changing password works
        acc.password = testPassword + "4"
        try assertTrue(acc.password == testPassword + "4", messageOnFail: "stored and expected password are different after password change")
        
        //test getting and setting comment works
        try assertTrue(acc.getComment() == testNotes, messageOnFail: "stored and expected comment are different")
        acc.setComment(to: testNotes + "1")
        try assertTrue(acc.getComment() == testNotes + "1", messageOnFail: "stored and expected comment are different after change")
        
        //test deletion and restoration
        acc.delete()
        try assertTrue(acc.deletedAt != nil, messageOnFail: "Account isn't marked as deleted")
        acc.restore()
        try assertTrue(acc.deletedAt == nil, messageOnFail: "Account isn't restored")
        
        //test keychaindata deletion
        acc.deleteCorrespondingKeychainData()
        try assertTrue(acc.password == nil && acc.getTOTPSecret() == nil, messageOnFail: "Corresponding keychaindata wasn't deleted")
    }
    
    private func assertTrue(_ value: Bool, messageOnFail: String) throws {
        if !value {
            throw AIntegrationTestError.withMessage(messageOnFail)
        }
    }
    
    public enum TestCases: String, CaseIterable {
        case testAccountCreationWithoutCollision
        case testAccountCreationWithCollision
        case testAccountCreationWithSuffix
        case testAccountProperties
    }
}

public enum AIntegrationTestError: Error {
    case withMessage(String)
}

public extension IntegrationTests.TestCases {
    @MainActor
    var test: () -> IntegrationtTestResult {
        switch self {
        case .testAccountCreationWithoutCollision:
            {
                do {
                    try IntegrationTests().testAccountCreationWithoutCollision()
                    return .success(true)
                } catch {
                    guard let error = error as? AIntegrationTestError else {
                        return.failure(.withMessage("unknown error: \(error.localizedDescription)"))
                    }
                    return .failure(error)
                }
            }
        case .testAccountCreationWithCollision:
            {
                do {
                    try IntegrationTests().testAccountCreationWithCollision()
                    return .success(true)
                } catch {
                    guard let error = error as? AIntegrationTestError else {
                        return.failure(.withMessage("unknown error: \(error.localizedDescription)"))
                    }
                    return .failure(error)
                }
            }
        case .testAccountCreationWithSuffix:
            {
                do {
                    try IntegrationTests().testAccountCreationWithSuffix()
                    return .success(true)
                } catch {
                    guard let error = error as? AIntegrationTestError else {
                        return.failure(.withMessage("unknown error: \(error.localizedDescription)"))
                    }
                    return .failure(error)
                }
            }
        case .testAccountProperties:
            {
                do {
                    try IntegrationTests().testAccountProperties()
                    return .success(true)
                } catch {
                    guard let error = error as? AIntegrationTestError else {
                        return.failure(.withMessage("unknown error: \(error.localizedDescription)"))
                    }
                    return .failure(error)
                }
            }
        }
    }
}

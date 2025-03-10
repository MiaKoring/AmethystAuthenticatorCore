//
//  MigrationTests.swift
//  AmethystAuthenticatorCore
//
//  Created by Mia Koring on 09.03.25.
//

import XCTest
import SwiftData
@testable import AmethystAuthenticatorCore

final class MigrationTests: XCTestCase {
    // Temporäre URL für die Test-Datenbank
    func getTempStoreURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("test_store.sqlite")
    }
    
    func testMigrationV0_1_0toV0_2_0() async throws {
        let storeURL = getTempStoreURL()
        
        do {
            let container = try ModelContainer(for: AAuthenticatorModelSchema_V0_1_0.Account.self, configurations: ModelConfiguration(url: storeURL))
            let context = ModelContext(container)
            
            let account = AAuthenticatorModelSchema_V0_1_0.Account(service: "google.com", username: "test", totp: false)
            context.insert(account)
            try context.save()
        }
        
        do {
            let container = try ModelContainer(for: AAuthenticatorModelSchema_V0_2_0.Account.self, migrationPlan: AAuthenticatorMigrations.self, configurations: ModelConfiguration(url: storeURL))
            let context = ModelContext(container)
            
            guard let new = try context.fetch(FetchDescriptor<AAuthenticatorModelSchema_V0_2_0.Account>()).first else {
                XCTFail("Wasn't migrated")
                return
            }
            XCTAssertTrue(new.totp == false)
            XCTAssertTrue(new.isDeleted == false)
            XCTAssertTrue(new.aliases == [])
            XCTAssertTrue(new.username == "test")
            XCTAssertTrue(new.service == "google.com")
            XCTAssertTrue(new.image == nil)
            XCTAssertTrue(new.editedAt == nil)
            XCTAssertTrue(new.title == nil)
        }
    }
    
    func testMigrationV0_2_0toV0_3_0() async throws {
        let storeURL = getTempStoreURL()
        
        do {
            let container = try ModelContainer(for: AAuthenticatorModelSchema_V0_2_0.Account.self, configurations: ModelConfiguration(url: storeURL))
            let context = ModelContext(container)
            
            let account = AAuthenticatorModelSchema_V0_2_0.Account(service: "google.com", username: "test", totp: false)
            context.insert(account)
            try context.save()
        }
        
        do {
            let container = try ModelContainer(for: AAuthenticatorModelSchema_V0_3_0.Account.self, migrationPlan: AAuthenticatorMigrations.self, configurations: ModelConfiguration(url: storeURL))
            let context = ModelContext(container)
            
            guard let new = try context.fetch(FetchDescriptor<AAuthenticatorModelSchema_V0_3_0.Account>()).first else {
                XCTFail("Wasn't migrated")
                return
            }
            XCTAssertTrue(new.totp == false)
            XCTAssertTrue(new.isDeleted == false)
            XCTAssertTrue(new.aliases == [])
            XCTAssertTrue(new.username == "test")
            XCTAssertTrue(new.service == "google.com")
            XCTAssertTrue(new.image == nil)
            XCTAssertTrue(new.editedAt == nil)
            XCTAssertTrue(new.title == nil)
            XCTAssertTrue(new.strength == nil)
        }
    }
    
    // Aufräumen nach Tests
    override func tearDown() {
        super.tearDown()
        
        // Testdatenbank löschen
        let storeURL = getTempStoreURL()
        try? FileManager.default.removeItem(at: storeURL)
    }
}

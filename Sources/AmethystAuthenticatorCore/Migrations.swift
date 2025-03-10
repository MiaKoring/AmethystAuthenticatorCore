//
//  Migrations.swift
//  AmethystAuthenticatorBackend
//
//  Created by Mia Koring on 08.03.25.
//

@preconcurrency import SwiftData

public typealias Account = AAuthenticatorModelSchema_V0_3_0.Account

public enum AAuthenticatorMigrations: SchemaMigrationPlan {
    public static let schemas: [any VersionedSchema.Type] = [
        AAuthenticatorModelSchema_V0_1_0.self,
        AAuthenticatorModelSchema_V0_2_0.self,
        AAuthenticatorModelSchema_V0_3_0.self
    ]
    
    public static let stages: [MigrationStage] = [
        v0_1_0tov0_2_0,
        v0_2_0tov0_3_0
    ]
    
    public static let v0_1_0tov0_2_0: MigrationStage = .custom(fromVersion: AAuthenticatorModelSchema_V0_1_0.self, toVersion: AAuthenticatorModelSchema_V0_2_0.self, willMigrate: { context in
        let res = try context.fetch(FetchDescriptor<AAuthenticatorModelSchema_V0_1_0.Account>())
        for item in res {
            context.delete(item)
            let account = AAuthenticatorModelSchema_V0_2_0.Account(id: item.id, service: item.service, aliases: item.aliases, username: item.username, totp: item.totp, createdAt: item.createdAt, editedAt: nil, deletedAt: item.deletedAt)
            context.insert(account)
        }
        
    }, didMigrate: nil)
    
    public static let v0_2_0tov0_3_0: MigrationStage = .custom(fromVersion: AAuthenticatorModelSchema_V0_2_0.self, toVersion: AAuthenticatorModelSchema_V0_3_0.self, willMigrate: { context in
        let res = try context.fetch(FetchDescriptor<AAuthenticatorModelSchema_V0_2_0.Account>())
        for item in res {
            context.delete(item)
            let account = AAuthenticatorModelSchema_V0_3_0.Account(id: item.id, service: item.service, aliases: item.aliases, username: item.username, totp: item.totp, createdAt: item.createdAt, editedAt: nil, deletedAt: item.deletedAt, strength: nil)
            context.insert(account)
        }
    }, didMigrate: nil)
    
}

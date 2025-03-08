//
//  Migrations.swift
//  AmethystAuthenticatorBackend
//
//  Created by Mia Koring on 08.03.25.
//

@preconcurrency import SwiftData

public typealias Account = AAuthenticatorModelSchema_V0_1_0.Account

enum AAuthenticatorMigrations: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [AAuthenticatorModelSchema_V0_1_0.self]
    
    static let stages: [MigrationStage] = []
}

//
//  Migrations.swift
//  AmethystAuthenticatorBackend
//
//  Created by Mia Koring on 08.03.25.
//

@preconcurrency import SwiftData

public typealias Account = AAuthenticatorModelSchema_V0_1_0.Account

public enum AAuthenticatorMigrations: SchemaMigrationPlan {
    public static let schemas: [any VersionedSchema.Type] = [AAuthenticatorModelSchema_V0_1_0.self]
    
    public static let stages: [MigrationStage] = []
}

//
//  Models.swift
//  AmethystAuthenticatorModels
//
//  Created by Mia Koring on 07.03.25.
//

@preconcurrency import SwiftData
import Foundation
@preconcurrency import KeychainAccess
import SwiftOTP

public enum AAuthenticatorModelSchema_V0_1_0: VersionedSchema {
    public static let models: [any PersistentModel.Type] = [Account.self]
    
    public static let versionIdentifier: Schema.Version = Schema.Version(0, 1, 0)
    
    @Model
    public final class Account {
        public private(set) var id: UUID
        public private(set) var service: String
        /**
         alternative domains where this account can be used to log in
         */
        public var aliases: [String]
        public private(set) var username: String
        var password: String? {
            get {
                getPassword()
            }
            set {
                setPassword(to: newValue)
            }
        }
        public private(set) var totp: Bool
        public private(set) var createdAt: Date = Date.now
        public private(set) var deletedAt: Date? = nil
        
        /**
         initializer for swiftdata
         */
        public init(id: UUID = UUID(), services: String, aliases: [String] = [], username: String, totp: Bool, createdAt: Date = Date(), deletedAt: Date? = nil) {
            self.id = id
            self.service = services
            self.aliases = aliases
            self.username = username
            self.totp = totp
            self.createdAt = createdAt
            self.deletedAt = deletedAt
        }
        
        /**
         throws AAuthenticationError or a Keychain related Error
         */
        public convenience init(service: String, username: String, notes: String, password: String, totp: Bool = false, allAccounts: [Account]) throws {
            try Account.checkUsername(username: username, service: service, allAccounts: allAccounts)
            self.init(services: service, username: username, totp: totp)
            try saveToKeychain(service: service, username: username, password: password, notes: notes)
        }
        
        
        public func delete() {
            self.deletedAt = Date.now
        }
        
        public func restore() {
            self.deletedAt = nil
        }
        
        /**
         call before romoving from SwiftData to delete data irrevocable
         */
        public func deleteCorrespondingKeychainData() {
            let keychain = Keychain.create(for: self.service)
            keychain[self.username] = nil
            keychain["\(self.username)({#totp})"] = nil
        }
        
        // initial save to keychain on creation
        private func saveToKeychain(service: String, username: String, password: String, notes: String) throws {
            if self.service != service {
                let keychain = Keychain.create(for: service)
                keychain[username] = nil
            }
            let keychain = Keychain.create(for: service)
            try keychain
                .comment(notes)
                .set(password, key: username)
        }
        
        /**
         change Username, automatically updates the storage in the keychain to the new name
         */
        public func setUsername(to newValue: String, allAccounts: [Account]) throws {
            try Account.checkUsername(username: newValue, service: self.service, allAccounts: allAccounts)
            
            let keychain = Keychain.create(for: self.service)
            let comment = keychain[attributes: self.username]?.comment
            let password = keychain[self.username]
            let totp = keychain["\(self.username)({#totp})"]
            
            keychain[self.username] = nil
            keychain["\(self.username)({#totp})"] = nil
            
            if let password {
                try keychain
                    .comment(comment ?? "")
                    .set(password, key: newValue)
            }
            if let totp {
                try keychain
                    .comment(comment ?? "")
                    .set(totp, key: "\(newValue)({#totp})")
            }
        }
        
        public func getPassword() -> String? {
            let keychain = Keychain.create(for: self.service)
            return keychain[self.username]
        }
        
        public func setPassword(to newValue: String?) {
            let keychain = Keychain.create(for: self.service)
            keychain[self.username] = newValue
        }
        
        public func setTOTPSecret(to secret: String) {
            let keychain = Keychain.create(for: self.service)
            keychain["\(self.username)({#totp})"] = secret
            self.totp = true
        }
        
        public func getTOTPSecret() -> String? {
            let keychain = Keychain.create(for: self.service)
            return keychain["\(self.username)({#totp})"]
        }
        
        public func getCurrentTOTPCode() -> String? {
            guard let secret = getTOTPSecret(),
                  let base32DecodedData = base32DecodeToData(secret),
                  let totp = TOTP(secret: base32DecodedData) else {
                return nil
            }
            return totp.generate(time: Date.now)
        }
        
        public func removeTOTPSecret() {
            let keychain = Keychain.create(for: self.service)
            keychain["\(self.username)({#totp})"] = nil
            self.totp = false
        }
        
        
        private static func checkUsername(username: String, service: String, allAccounts: [Account]) throws {
            //reserved for internal use, to save and retrieve OTP secrets
            guard !username.hasSuffix("({#totp})") else {
                throw AAuthenticationError.usernameHasReservedSuffix
            }
            guard !allAccounts.contains(where: {
                $0.service == service && $0.username == username
            }) else {
                throw AAuthenticationError.usernameAlreadyInUseOnService
            }
        }
        
    }
}

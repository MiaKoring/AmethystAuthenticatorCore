//
//  V0_3_0.swift
//  AmethystAuthenticatorCore
//
//  Created by Mia Koring on 10.03.25.
//

@preconcurrency import SwiftData
import Foundation
@preconcurrency import KeychainAccess
import SwiftOTP
import SwiftUI

public enum AAuthenticatorModelSchema_V0_3_0: VersionedSchema {
    public static let models: [any PersistentModel.Type] = [Account.self]
    
    public static let versionIdentifier: Schema.Version = Schema.Version(0, 3, 0)
    
    @Model
    public final class Account {
        public private(set) var id: UUID = UUID()
        public private(set) var service: String = ""
        /**
         alternative domains where this account can be used to log in
         */
        public var aliases: [String] = []
        public private(set) var username: String = ""
        public var password: String? {
            get {
                getPassword()
            }
            set {
                setPassword(to: newValue)
            }
        }
        
        public var comment: String? {
            get {
                getComment()
            }
            set {
                setComment(to: newValue ?? "")
            }
        }
        
        public private(set) var totp: Bool = false
        public private(set) var createdAt: Date = Date.now
        public private(set) var editedAt: Date?
        public private(set) var deletedAt: Date? = nil
        public private(set) var image: Data?
        public private(set) var title: String?
        public var strength: Double?
        
        /**
         initializer for swiftdata
         */
        public init(id: UUID = UUID(), service: String, aliases: [String] = [], username: String, totp: Bool, createdAt: Date = Date(), editedAt: Date? = nil, deletedAt: Date? = nil, image: Data? = nil, title: String? = nil, strength: Double? = nil) {
            self.id = id
            self.service = service
            self.aliases = aliases
            self.username = username
            self.totp = totp
            self.createdAt = createdAt
            self.editedAt = editedAt
            self.deletedAt = deletedAt
            self.image = image
            self.title = title
            self.strength = strength
        }
        
        /**
         throws AAuthenticationError or a Keychain related Error
         */
        public convenience init(service: String, username: String, comment: String, password: String, totp: Bool = false, allAccounts: [Account], strength: Double?) throws {
            try Account.checkUsername(username: username, service: service, allAccounts: allAccounts)
            
            self.init(service: service, username: username, totp: totp, strength: strength)
            try saveToKeychain(service: service, username: username, password: password, comment: comment)
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
        private func saveToKeychain(service: String, username: String, password: String, comment: String) throws {
            if self.service != service {
                let keychain = Keychain.create(for: service)
                keychain[username] = nil
            }
            let keychain = Keychain.create(for: service)
            try keychain
                .comment(comment)
                .set(password, key: username)
        }
        
        /**
         change Username, automatically updates the storage in the keychain to the new name
         */
        public func setUsername(to newValue: String, allAccounts: [Account], context: ModelContext) throws {
            let keychain = Keychain.create(for: self.service)
            
            let comment = keychain[attributes: self.username]?.comment
            let password = keychain[self.username]
            let totp = keychain["\(self.username)({#totp})"]
            
            do {
                try context.transaction {
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
                    try Account.checkUsername(username: newValue, service: self.service, allAccounts: allAccounts)
                    self.username = newValue
                }
                self.editedAt = Date.now
            } catch {
                keychain[newValue] = nil
                keychain["\(newValue)({#totp})"] = nil
                
                if let password {
                    try keychain
                        .comment(comment ?? "")
                        .set(password, key: self.username)
                }
                if let totp {
                    try keychain
                        .comment(comment ?? "")
                        .set(totp, key: "\(self.username)({#totp})")
                }
            }
        }
        
        public func getPassword() -> String? {
            let keychain = Keychain.create(for: self.service)
            return keychain[self.username]
        }
        
        public func setPassword(to newValue: String?) {
            self.editedAt = Date.now
            let keychain = Keychain.create(for: self.service)
            keychain[self.username] = newValue
        }
        
        public func setTOTPSecret(to secret: String) {
            self.editedAt = Date.now
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
            self.editedAt = Date.now
            let keychain = Keychain.create(for: self.service)
            keychain["\(self.username)({#totp})"] = nil
            self.totp = false
        }
        
        public func getComment() -> String? {
            let keychain = Keychain.create(for: self.service)
            return keychain[attributes: self.username]?.comment
        }
        
        public func setComment(to newComment: String) {
            self.editedAt = Date.now
            let keychain = Keychain.create(for: self.service).comment(newComment)
            keychain[self.username] = self.password
        }
        
        public func setImage(to imageData: Data?) {
            self.editedAt = Date.now
            self.image = imageData
        }
        
        public func setTitle(to newTitle: String) {
            self.editedAt = Date.now
            self.title = newTitle
        }
        
        
        static func checkUsername(username: String, service: String, allAccounts: [Account]) throws {
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
        
        public static func getTitle(from urlString: String) async throws -> String? {
            guard let url = URL(string: "https://\(urlString)") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            // extractTitle
            if let titleRange = htmlString.range(of: "<title>"),
               let titleEndRange = htmlString.range(of: "</title>") {
                let startIndex = titleRange.upperBound
                let endIndex = titleEndRange.lowerBound
                return String(htmlString[startIndex..<endIndex])
            } else {
                return nil
            }
        }
        
        public static func getImage(for urlString: String) async throws -> Data? {
            guard let url = URL(string: "https://\(urlString)")?.appending(path: "favicon.ico") else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
#if os(macOS)
            guard let _ = NSImage(data: data) else {
                return nil
            }
            return data
#elseif canImport(UIKit)
            guard let _ = UIImage(data: data) else {
                return nil
            }
            return data
#else
            return nil
#endif
        }
        
    }
}

//
//  KeychainCreator.swift
//  AmethystAuthenticatorModels
//
//  Created by Mia Koring on 08.03.25.
//

import KeychainAccess

public extension Keychain {
    /**
     Returns the keychain configuration used for Amethyst Authenticator
        icloud sync: enabled, accessibility: when unlocked
     */
    static func create(for server: String) -> Keychain {
        let keychain = self.init(service: server)
        return keychain
            .synchronizable(true)
            .accessibility(.whenUnlocked)
    }
}

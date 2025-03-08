//
//  KeychainCreator.swift
//  AmethystAuthenticatorModels
//
//  Created by Mia Koring on 08.03.25.
//

import KeychainAccess

extension Keychain {
    /**
     Returns the keychain configuration used for Amethyst Authenticator
        icloud sync: enabled, accessibility: when unlocked
     */
    public static func create(for server: String) -> Keychain {
        let keychain = self.init(server: server, protocolType: .https, authenticationType: .htmlForm)
        return keychain
            .synchronizable(true)
            .accessibility(.whenUnlocked)
    }
}

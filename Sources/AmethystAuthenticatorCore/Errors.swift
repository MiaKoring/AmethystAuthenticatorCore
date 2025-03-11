//
//  Errors.swift
//  AmethystAuthenticatorModels
//
//  Created by Mia Koring on 07.03.25.
//

public enum AAuthenticationError: String, Error {
    case usernameHasReservedSuffix = "Usernames ending with \"({#totp})\" are reserved for internal use."
    case usernameAlreadyInUseOnService = "The given username already has a corresponding password saved for the current service."
    case somethingWentWrongOnKeychain = "Something went wrong in a keychain operation"
}

public extension AAuthenticationError {
    var localizedDescription: String {
        self.rawValue
    }
}

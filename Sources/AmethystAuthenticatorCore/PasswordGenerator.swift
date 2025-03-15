//
//  PasswordGenerator.swift
//  AmethystAuthenticatorCore
//
//  Created by Mia Koring on 15.03.25.
//

import Foundation

public struct PasswordGenerator {
    // Constants for character sets
    private let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
    private let numbers = "1234567890"
    private let specialCharacters = "-_.!:;,#$%^&*"
    
    // Configuration
    private let segmentLength = 6
    private let segmentCount = 3
    
    public init(){}
    
    /// Generates a password in the format XXXXXX-XXXXXX-XXXXXX
    /// - Returns: A random password
    public func generatePassword(insertSegments: Bool = true) -> String {
        var segments = [String]()
        
        // Place at least one uppercase letter, one lowercase letter, and one number
        var requiredChars = {
            if !insertSegments {
                return [
                    uppercaseLetters.randomElement()!,
                    lowercaseLetters.randomElement()!,
                    numbers.randomElement()!
                ]
            }
            return [
                uppercaseLetters.randomElement()!,
                lowercaseLetters.randomElement()!,
                numbers.randomElement()!,
                specialCharacters.randomElement()!
            ]
        }()
        
        // All available characters for the remaining positions
        let allChars = uppercaseLetters + lowercaseLetters + numbers + (insertSegments ? "": specialCharacters)
        
        // Generate each segment
        for _ in 0..<segmentCount {
            var segmentChars = [Character]()
            
            // Add random characters
            for _ in 0..<segmentLength {
                segmentChars.append(allChars.randomElement()!)
            }
            
            // Replace random positions with required characters, if any
            if !requiredChars.isEmpty {
                let randomPosition = Int.random(in: 0..<segmentLength)
                segmentChars[randomPosition] = requiredChars.removeFirst()
            }
            
            // Shuffle the characters within the segment
            segmentChars.shuffle()
            
            // Add the segment to the list
            segments.append(String(segmentChars))
        }
        
        // Shuffle the segments to ensure the required characters are well distributed
        segments.shuffle()
        
        // Join the segments with hyphens
        return insertSegments ? segments.joined(separator: "-") : segments.joined()
    }
    
    /// Validates if a password meets the requirements
    /// - Parameter password: The password to validate
    /// - Returns: `true` if the password meets the requirements
    public func isValidPassword(_ password: String) -> Bool {
        let uppercaseCheck = password.rangeOfCharacter(from: CharacterSet(charactersIn: uppercaseLetters)) != nil
        let lowercaseCheck = password.rangeOfCharacter(from: CharacterSet(charactersIn: lowercaseLetters)) != nil
        let numberCheck = password.rangeOfCharacter(from: CharacterSet(charactersIn: numbers)) != nil
        
        return uppercaseCheck && lowercaseCheck && numberCheck 
    }
}

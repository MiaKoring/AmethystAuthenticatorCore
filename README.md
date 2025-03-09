# AmethystAuthenticatorCore

Core of the Password-Manager used in [Amethyst Browser](https://amethystbrowser.de) [[repo]](https://codeberg.org/miakoring/Amethyst) and the Amethyst Authenticator App

### TLDR;
AmethystAuthenticationCore handles all the logic of managing Passwords and TOTP Secrets and storing them safely in the keychain. When building a Password-Manager, you will only need to build the GUI around it.

### License
This package is licensed under MIT, read more in the LICENSE File

### Requirements
- Swift 6 compatible
- macOS 15
- iOS 18
- activated Keychain sharing

### Purpose

AmethystAuthenticatorCore contains the SwiftData-Models, Migrations and Functions that handle all the data.
<br>It provides a safe way of of storing and retrieving Passwords and Secrets. Its built for iCloud Sync of the Keychain and SwiftData Models. 
<br>Any app that uses this package will require the [Keychain Sharing Entitlement](https://developer.apple.com/documentation/xcode/configuring-keychain-sharing/)
<br>I have not tested it without the App Group entitlement, so keep in mind that it might not work without it.

### Install
Install the package via SwiftPackageManager.
<br>Add

```
https://codeberg.org/miakoring/AmethystAuthenticatorCore.git
```

to the Package Dependencies of your App.

### Use 
First import it:

```swift
import AmethystAuthenticatorCore
```

then, specify use of the model like this (example):

1. #### Create a Container (SwiftData needs to be imported)
	Not shared through AppGroup
	
   ```swift
   let container = try! ModelContainer(for: Account.self, migrationPlan: AAuthenticatorMigrations.self)
   ```
   
   Shared through AppGroup
   
   ```swift
   let groupDBURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "YOURTEAMIDENTIFIER.com.yourcompany.yourappgroup")!.appendingPathComponent("shared.sqlite")
   let configuration = ModelConfiguration(url: groupDBURL)
   let container = try! ModelContainer(for: Account.self, migrationPlan: AAuthenticatorMigrations.self, configurations: configuration)
   ```
2. #### Specify use of container
   ```swift
   @main
   struct YourApp: App {
		var body: some Scene {
        	WindowGroup {
            	ContentView()
                	.modelContainer(container)
        	}
    	}
   }

   ```
3. #### Create an Account
	**ONLY** use the convenience init. The other one is not safe and only to get used by SwiftData. DO NOT use it outside of testing code. It requires an array of all stored accounts to check for collision.
	
	```swift
	let account = Account(service: "yourcompany.com", //the website to which the account belongs
	 	username: "example@yourcompany.com", 
	  	comment: "", //automatically get saved to the Keychain
	  	password: "password", //automatically get saved to the Keychain
	  	allAccounts: allStoredAccounts)
	modelContext.insert(account)
	```
4. #### Get/Set Password
	Either use 
	
	```swift
	let password = account.password
	account.password = "newPassword"
	```
	or
	
	```swift
	account.getPassword()
	account.setPassword(to: "newPassword")
	```
5. #### Get/Set Username

	```swift
	let username = account.username
	try account.setUsername(to: "newUsername", allAccounts: allAccounts, context: modelContext) //Context and allAccounts are required for collision protection and concurrency safety
	```

6. #### Get/Set TOTP

	```swift
	account.removeTOTPSecret() //deletes TOTP secret fromt the keychain
	account.setTOTPSecret(to: "New Base32 encoded secret")
	account.getCurrentTOTPCode() //returns totp code of the time of calling
	account.getTOTPSecret()
	```
7. #### Get/Set comment
   
   Either use 
	
	```swift
	let comment = account.comment
	account.comment = "New Comment"
	```
	or
	
	```swift
	account.getComment()
	account.setComment(to: "New Comment")
	```
8. #### Get/Set Aliases
	Aliases are domains, that differ from the main one (account.service) on which the username and password also work. For example apple.com and alias idmsa.apple.com
	
	```swift
	account.aliases = ["alias.com"]
	account.aliases.append("new.alias.com")
	let aliases = account.aliases
	```
	
### Test

The Library contains both unit and integration tests. Unfortunately, because the Library requires entitlements for use, integration-testing it only works in a real app.
<br>Clone

```
https://codeberg.org/miakoring/AmethystAuthenticatorCoreIntegrationTests.git
```
and add your local version of this repository as Package Dependency.
Then run it. Detailed errors will get printed to the console, in the app you can run single or all tests and see if they succeed or not.


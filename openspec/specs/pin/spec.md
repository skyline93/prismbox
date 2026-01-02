# pin Specification

## Purpose
TBD - created by archiving change decouple-pin-service. Update Purpose after archive.
## Requirements
### Requirement: PIN Authentication Service

The system SHALL provide a PIN authentication service that handles PIN code verification, setting, and changing through backend API interactions.

#### Scenario: Set PIN for a resource
- **WHEN** a user sets a PIN for a resource (e.g., album, folder)
- **AND** the PIN is 6 digits
- **THEN** the PIN is sent to the backend API for storage
- **AND** existing session tokens for the resource are invalidated

#### Scenario: Verify PIN and obtain session token
- **WHEN** a user provides a PIN to unlock a resource
- **AND** the PIN is correct
- **THEN** a session token is returned from the backend
- **AND** the session token is securely stored locally
- **AND** the token expiration time is recorded

#### Scenario: Change PIN for a resource
- **WHEN** a user changes a PIN for a resource
- **AND** the old PIN is correct
- **AND** the new PIN is 6 digits
- **THEN** the new PIN is sent to the backend API
- **AND** all existing session tokens are invalidated

### Requirement: PIN Session Storage Service

The system SHALL provide a session storage service that securely stores and retrieves session tokens using encrypted storage.

#### Scenario: Store session token with encryption
- **WHEN** a session token is saved for a resource
- **AND** a password is provided
- **THEN** the token is encrypted using a key derived from the password
- **AND** the encrypted token is stored in secure storage
- **AND** the expiration time is stored separately

#### Scenario: Retrieve valid session token
- **WHEN** a session token is retrieved for a resource
- **AND** the token exists in storage
- **AND** the token has not expired
- **THEN** the token is decrypted and returned
- **AND** if the token has expired, it is deleted from storage

#### Scenario: Delete session token
- **WHEN** a session token is deleted for a resource
- **THEN** the encrypted token and expiration time are removed from storage
- **AND** any cached encryption keys are deleted

### Requirement: PIN Key Derivation Service

The system SHALL provide a key derivation service that generates encryption keys from PIN codes using PBKDF2 algorithm.

#### Scenario: Derive encryption key from PIN
- **WHEN** a key is derived from a PIN for a resource
- **THEN** PBKDF2 algorithm is used with SHA-256
- **AND** a unique salt is generated or retrieved for the resource
- **AND** the salt is stored in secure storage
- **AND** a 32-byte key is returned

#### Scenario: Cache derived key for performance
- **WHEN** a key is derived from a PIN
- **THEN** the key may be cached in secure storage
- **AND** the cached key can be retrieved for subsequent operations
- **AND** the cached key can be deleted when the session ends

### Requirement: PIN Token Encryption Service

The system SHALL provide a token encryption service that encrypts and decrypts session tokens using AES encryption.

#### Scenario: Encrypt session token
- **WHEN** a session token is encrypted with a key
- **THEN** AES encryption is used
- **AND** a random IV is generated
- **AND** the encrypted token includes integrity verification (HMAC)
- **AND** the result is Base64 encoded

#### Scenario: Decrypt session token
- **WHEN** an encrypted session token is decrypted with the correct key
- **THEN** the integrity is verified
- **AND** the original token is returned
- **AND** if integrity check fails, an error is raised

### Requirement: PIN Access Control Service

The system SHALL provide an access control service that manages resource unlock/lock states and automatic locking.

#### Scenario: Unlock resource with valid session
- **WHEN** a resource is unlocked
- **AND** a valid session token exists
- **THEN** the resource is marked as unlocked
- **AND** an automatic lock timer is started based on configured timeout
- **AND** the unlock state is tracked in memory

#### Scenario: Automatic lock on timeout
- **WHEN** a resource is unlocked
- **AND** the configured timeout period elapses
- **THEN** the resource is automatically locked
- **AND** the unlock state is cleared from memory
- **AND** the lock timer is cancelled

#### Scenario: Lock on application background
- **WHEN** the application enters background state
- **THEN** all unlocked resources are locked
- **AND** unlock states are cleared
- **AND** all lock timers are cancelled

#### Scenario: Verify token validity on application resume
- **WHEN** the application resumes from background
- **THEN** all stored unlock states are checked
- **AND** resources with invalid or expired tokens are locked
- **AND** resources with valid tokens remain unlocked

### Requirement: PIN Service Configuration

The system SHALL support configurable PIN service instances with different storage prefixes and resource type names.

#### Scenario: Create PIN service with custom configuration
- **WHEN** a PIN service is created with a configuration
- **AND** the configuration specifies a storage key prefix
- **THEN** all storage operations use the specified prefix
- **AND** the resource type name is used in logs and error messages
- **AND** the default session timeout is applied

#### Scenario: Multiple PIN service instances
- **WHEN** multiple PIN service instances are created with different configurations
- **THEN** each instance uses its own storage namespace
- **AND** sessions from different instances do not interfere with each other
- **AND** resources from different namespaces are managed independently


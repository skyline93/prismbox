## REMOVED Requirements

### Requirement: Encrypted Space Album
The system SHALL provide an encrypted space feature that allows users to create a private album protected by a PIN code, with session-based access control and secure asset management.

**Reason**: The encrypted space feature is being completely removed to simplify the system architecture and reduce maintenance complexity.

**Migration**: Users with existing encrypted space albums will lose access to those albums. No data migration or export functionality is provided.

#### Scenario: Encrypted space album creation
- **WHEN** a user requests to create an encrypted space album
- **THEN** the system creates a special album with encryption enabled
- **AND** the album type is set to "encrypted_space"

#### Scenario: PIN-based access control
- **WHEN** a user attempts to access an encrypted space album
- **AND** a PIN has been set for the album
- **THEN** the user must provide the correct PIN to unlock the album
- **AND** upon successful verification, a session token is issued
- **AND** the session token is required for all subsequent operations on the album

#### Scenario: Session token management
- **WHEN** a user unlocks an encrypted space album
- **THEN** a session token is generated and stored
- **AND** the token has an expiration time (default 1 hour)
- **AND** the token must be included in all API requests for album operations
- **AND** when the token expires, the user must re-verify the PIN

#### Scenario: Asset management in encrypted space
- **WHEN** a user adds assets to an encrypted space album
- **AND** a valid session token is provided
- **THEN** the assets are associated with the encrypted album
- **AND** for local-only assets, files are migrated to private storage
- **AND** for remote assets, the association is stored in the database

#### Scenario: Password management
- **WHEN** a user sets a PIN for an encrypted space album
- **THEN** the PIN is hashed and stored securely
- **AND** all existing session tokens are invalidated
- **WHEN** a user changes the PIN
- **AND** the old PIN is verified
- **THEN** the new PIN is hashed and stored
- **AND** all existing session tokens are invalidated

### Requirement: Encrypted Space API Endpoints
The system SHALL provide API endpoints for managing encrypted space albums, including creation, password management, session management, and asset operations.

**Reason**: All encrypted space API endpoints are being removed as part of the feature removal.

**Migration**: Clients using these endpoints will need to be updated to remove all encrypted space functionality.

#### Scenario: Get or create encrypted space album
- **WHEN** a user requests to get or create an encrypted space album
- **THEN** the system returns the existing encrypted space album or creates a new one
- **AND** the album has type "encrypted_space" and encryption enabled

#### Scenario: Set album password
- **WHEN** a user sets a password for an encrypted space album
- **AND** the password is 6 digits
- **THEN** the password is hashed and stored
- **AND** all existing sessions are revoked

#### Scenario: Verify password and get session token
- **WHEN** a user verifies the password for an encrypted space album
- **AND** the password is correct
- **THEN** a session token is generated and returned
- **AND** the token expiration time is included in the response

#### Scenario: Access encrypted space assets
- **WHEN** a user requests assets from an encrypted space album
- **AND** a valid session token is provided
- **THEN** the system returns the list of asset IDs in the album
- **WHEN** a user adds assets to an encrypted space album
- **AND** a valid session token is provided
- **THEN** the assets are added to the album
- **WHEN** a user removes assets from an encrypted space album
- **AND** a valid session token is provided
- **THEN** the assets are removed from the album

### Requirement: Encrypted Space UI Components
The system SHALL provide user interface components for managing encrypted space, including the encrypted space page, password setup dialog, password verification dialog, and integration with the albums and photos pages.

**Reason**: All encrypted space UI components are being removed as part of the feature removal.

**Migration**: Users will no longer see encrypted space options in the UI. Any existing encrypted space albums will be inaccessible.

#### Scenario: Encrypted space page
- **WHEN** a user navigates to the encrypted space page
- **THEN** the page displays all assets in the encrypted space album
- **AND** the user must unlock the album with a PIN if not already unlocked
- **AND** the page supports standard album operations (view, delete, etc.)

#### Scenario: Password setup dialog
- **WHEN** a user attempts to access an encrypted space album without a PIN
- **THEN** a password setup dialog is shown
- **AND** the user can set a 6-digit PIN
- **AND** biometric authentication can be enabled for future unlocks

#### Scenario: Password verification dialog
- **WHEN** a user attempts to access an encrypted space album with a PIN set
- **THEN** a password verification dialog is shown
- **AND** the user can enter the PIN or use biometric authentication
- **AND** upon successful verification, the album is unlocked

#### Scenario: Add to encrypted space from photos page
- **WHEN** a user selects photos on the timeline page
- **AND** the user chooses "Add to Encrypted Space"
- **THEN** the system verifies the user has access to encrypted space
- **AND** if unlocked, the photos are added to the encrypted space album
- **AND** if locked, the password verification dialog is shown

#### Scenario: Encrypted space settings
- **WHEN** a user navigates to settings
- **THEN** an encrypted space settings section is available
- **AND** the user can enable/disable biometric authentication
- **AND** the user can configure the auto-lock timeout

### Requirement: Encrypted Space Database Schema
The system SHALL store encrypted space data in the database, including encrypted album records, session tokens, and password hashes.

**Reason**: The database schema for encrypted space is being removed as part of the feature removal.

**Migration**: The `album_sessions` table will be dropped, and encrypted-related fields will be removed from the `albums` table. All data in these structures will be permanently deleted.

#### Scenario: Encrypted album storage
- **WHEN** an encrypted space album is created
- **THEN** the album record is stored with `is_encrypted=true` and `album_type='encrypted_space'`
- **AND** the password hash is stored in the `password_hash` field

#### Scenario: Session token storage
- **WHEN** a user unlocks an encrypted space album
- **THEN** a session token record is created in the `album_sessions` table
- **AND** the token hash, expiration time, and album association are stored
- **AND** the token can be validated for subsequent requests


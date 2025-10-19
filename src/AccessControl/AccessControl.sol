// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

contract ERC165Facet {

    /// @notice Emitted when the admin role for a role is changed.
    /// @param role The role that was changed.
    /// @param previousAdminRole The previous admin role.
    /// @param newAdminRole The new admin role.
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /// @notice Emitted when a role is granted to an account.
    /// @param role The role that was granted.
    /// @param account The account that was granted the role.
    /// @param sender The sender that granted the role.
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /// @notice Emitted when a role is revoked from an account.
    /// @param role The role that was revoked.
    /// @param account The account from which the role was revoked.
    /// @param sender The account that revoked the role.
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /// @notice Thrown when the account does not have a specific role.
    /// @param role The role that the account does not have.
    /// @param account The account that does not have the role.
    error AccessControlUnauthorizedAccount(address account, bytes32 role);

    /// @notice Storage slot identifier.
    bytes32 constant STORAGE_POSITION = keccak256("compose.erc165");

    /// @notice Default admin role.
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @notice Role data.
    struct RoleData {
        mapping(address account => bool) hasRole; // Mapping of accounts to roles.
        bytes32 adminRole; // Admin role for the role.
    }

    struct LibERC165Storage {
        mapping(bytes32 role => RoleData) _roles; // Mapping of roles to role data.
    }

        
    /// @notice Returns the storage for the AccessControl.
    /// @return s The storage for the AccessControl.
    function getStorage() internal pure returns (LibERC165Storage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position // Store the position in the storage slot.
        }
    }
    /// @notice Returns if an account has a role.
    /// @param role The role to check.
    /// @param account The account to check the role for.
    /// @return True if the account has the role, false otherwise.
    function hasRole(bytes32 role, address account) external view returns(bool){
        return getStorage()._roles[role].hasRole[account];
    }


    /// @notice Asserts that an account has a role.
    /// @param role The role to assert.
    /// @param account The account to assert the role for.
    /// @dev Emits a {AccessControlUnauthorizedAccount} error if the account does not have the role.
    function assertOnlyRole(bytes32 role, address account) external view {
        bool hasRole = getStorage()._roles[role].hasRole[account];
        if (!hasRole) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /// @notice Returns the admin role for a role.
    /// @param role The role to get the admin for.
    /// @return The admin role for the role.
    function getRoleAdmin(bytes32 role) external view returns(bytes32){
        return getStorage()._roles[role].adminRole;
    }


    /// @notice Grants a role to an account.
    /// @param role The role to grant.
    /// @param account The account to grant the role to.
    /// @dev Emits a {RoleGranted} event.
    /// @custom:error AccessControlUnauthorizedAccount If the caller is not the admin of the role.
    function grantRole(bytes32 role, address account) external {
        bytes32 adminRole = getStorage()._roles[role].adminRole;
        _assertOnlyRole(adminRole, msg.sender); // Check if the caller is the admin of the role.

        bool hasRole = getStorage()._roles[role].hasRole[account];
        if (!hasRole) {
            getStorage()._roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /// @notice Sets the admin role for a role.
    /// @param role The role to set the admin for.
    /// @param adminRole The admin role to set.
    /// @dev Emits a {RoleAdminChanged} event.
    /// @custom:error AccessControlUnauthorizedAccount If the caller is not the admin of the role.
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external {
        bytes32 preAdminRole = getStorage()._roles[role].adminRole;
        _assertOnlyRole(preAdminRole, msg.sender); // Check if the caller is the admin of the role.

        getStorage()._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, preAdminRole, adminRole);
    }

    /// @notice Revokes a role from an account.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    /// @dev Emits a {RoleRevoked} event.
    /// @custom:error AccessControlUnauthorizedAccount If the caller is not the admin of the role.
    function revokeRole(bytes32 role, address account) external {
        bytes32 preAdminRole = getStorage()._roles[role].adminRole;
        _assertOnlyRole(preAdminRole, msg.sender); // Check if the caller is the admin of the role.

        bool hasRole = getStorage()._roles[role].hasRole[account];
        if (hasRole) {
            getStorage()._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }


    /// @notice Renounces a role from the caller.
    /// @param role The role to renounce.
    /// @param account The account to renounce the role from.
    /// @dev Emits a {RoleRevoked} event.
    /// @custom:error AccessControlUnauthorizedAccount If the caller is not the account to renounce the role from.
    function renounceRole(bytes32 role, address account) external {
        if(msg.sender != account){
            revert AccessControlUnauthorizedAccount(account, role);
        }

        bool hasRole = getStorage()._roles[role].hasRole[account];
        if (hasRole) {
            getStorage()._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }


    /// @notice internal assertOnlyRole function to avoid repeating it in the external functions.
    /// @param role The role to assert.
    /// @dev Emits a {RoleGranted} event.
    /// @custom:error AccessControlUnauthorizedAccount If the caller does not have the role.
    function _assertOnlyRole(bytes32 role, address account) internal view {
        bool hasRole = getStorage()._roles[role].hasRole[account];
        if (!hasRole) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

}
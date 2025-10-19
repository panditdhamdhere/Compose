// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

library LibAccessControl {

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

    /// @notice role data.
    struct RoleData {
        mapping(address account => bool) hasRole; // Mapping of accounts to roles.
        bytes32 adminRole; // Admin role for the role.
    }

    /// @notice storage struct for the LibERC165.
    struct LibERC165Storage {
        mapping(bytes32 role => RoleData) _roles; // Mapping of roles to role data.
    }

    /// @notice Returns the storage for the AccessControl.
    /// @return s The storage for the AccessControl.
    function getStorage() internal pure returns (LibERC165Storage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
    
    /// @notice function to assert that an account has a role.
    /// @param role The role to assert.
    /// @param account The account to assert the role for.
    /// @custom:error AccessControlUnauthorizedAccount If the account does not have the role.
    function assertOnlyRole(bytes32 role, address account) internal view {
        bool hasRole = getStorage()._roles[role].hasRole[account];
        if (!hasRole) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }   

    /// @notice function to check if an account has a role.
    /// @param role The role to check.
    /// @param account The account to check the role for.
    /// @return True if the account has the role, false otherwise.
    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return getStorage()._roles[role].hasRole[account];
    }

    /// @notice function to set the admin role for a role.
    /// @param role The role to set the admin for.
    /// @param adminRole The admin role to set.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getStorage()._roles[role].adminRole;
        getStorage()._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
 
    /// @notice function to grant a role to an account.
    /// @param role The role to grant.
    /// @param account The account to grant the role to.
    /// @return True if the role was granted, false otherwise.
    function _grantRole(bytes32 role, address account) internal returns (bool) {
        bool hasRole = getStorage()._roles[role].hasRole[account];
        if (!hasRole) {
            getStorage()._roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, msg.sender);
            return true;
        } else {
            return false;
        }
    }

    /// @notice function to revoke a role from an account.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    /// @return True if the role was revoked, false otherwise.
    function _revokeRole(bytes32 role, address account) internal returns (bool) {
        bool hasRole = getStorage()._roles[role].hasRole[account];
        if (hasRole) {
            getStorage()._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, msg.sender);
            return true;
        } else {
            return false;
        }
    }


}
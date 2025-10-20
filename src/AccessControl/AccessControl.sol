// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

contract AccessControlFacet {

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

    /// @notice Thrown when the sender is not the account to renounce the role from.
    /// @param sender The sender that is not the account to renounce the role from.
    /// @param account The account to renounce the role from.
    error AccessControlUnauthorizedSender(address sender, address account);

    /// @notice Storage slot identifier.
    bytes32 constant STORAGE_POSITION = keccak256("compose.accesscontrol");

    /// @notice Default admin role.
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @notice storage struct for the AccessControl.
    struct AccessControlStorage {
        mapping(address account => mapping(bytes32 role => bool hasRole)) _hasRole; 
        mapping(bytes32 role => bytes32 adminRole) _adminRole; 
    }

    /// @notice Returns the storage for the AccessControl.
    /// @return s The storage for the AccessControl.
    function getStorage() internal pure returns (AccessControlStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /// @notice Returns if an account has a role.
    /// @param role The role to check.
    /// @param account The account to check the role for.
    /// @return True if the account has the role, false otherwise.
    function hasRole(bytes32 role, address account) external view returns(bool){
        AccessControlStorage storage s = getStorage();
        return s._hasRole[account][role];
    }


    /// @notice Checks if an account has a required role.
    /// @param role The role to check.
    /// @param account The account to check the role for.
    /// @custom:error AccessControlUnauthorizedAccount If the account does not have the role.
    function requireRole(bytes32 role, address account) external view {
        AccessControlStorage storage s = getStorage();
        if (!s._hasRole[account][role]) revert AccessControlUnauthorizedAccount(account, role);
    }

    /// @notice Returns the admin role for a role.
    /// @param role The role to get the admin for.
    /// @return The admin role for the role.
    function getRoleAdmin(bytes32 role) external view returns(bytes32){
        AccessControlStorage storage s = getStorage();
        return s._adminRole[role];
    }


    /// @notice Grants a role to an account.
    /// @param role The role to grant.
    /// @param account The account to grant the role to.
    /// @dev Emits a {RoleGranted} event.
    /// @custom:error AccessControlUnauthorizedAccount If the caller is not the admin of the role.
    function grantRole(bytes32 role, address account) external {
        AccessControlStorage storage s = getStorage();
        bytes32 adminRole = s._adminRole[role];

        // Check if the caller is the admin of the role.
        if (!s._hasRole[msg.sender][adminRole]) revert AccessControlUnauthorizedAccount(msg.sender, adminRole);

        bool hasRole = s._hasRole[account][role];
        if (!hasRole) {
            s._hasRole[account][role] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /// @notice Revokes a role from an account.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    /// @dev Emits a {RoleRevoked} event.
    /// @custom:error AccessControlUnauthorizedAccount If the caller is not the admin of the role.
    function revokeRole(bytes32 role, address account) external {
        AccessControlStorage storage s = getStorage();
        bytes32 adminRole = s._adminRole[role];

        // Check if the caller is the admin of the role.
        if (!s._hasRole[msg.sender][adminRole]) revert AccessControlUnauthorizedAccount(msg.sender, adminRole);

        bool hasRole = s._hasRole[account][role];
        if (hasRole) {
            s._hasRole[account][role] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }


    /// @notice Renounces a role from the caller.
    /// @param role The role to renounce.
    /// @param account The account to renounce the role from.
    /// @dev Emits a {RoleRevoked} event.
    /// @custom:error AccessControlUnauthorizedSender If the caller is not the account to renounce the role from.
    function renounceRole(bytes32 role, address account) external {
        AccessControlStorage storage s = getStorage();

        // Check If the caller is not the account to renounce the role from.
        if(msg.sender != account) revert AccessControlUnauthorizedSender(msg.sender, account);
    
        bool hasRole = s._hasRole[account][role];
        if (hasRole) {
            s._hasRole[account][role] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

}
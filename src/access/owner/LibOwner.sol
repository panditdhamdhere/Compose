// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/// @title ERC-173 Contract Ownership
/// @notice Provides internal functions and storage layout for owner management.
library LibOwner {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Thrown when attempting to transfer ownership of a renounced contract.
    error OwnerAlreadyRenounced();

    bytes32 constant STORAGE_POSITION = keccak256("compose.owner");

    /// @custom:storage-location erc8042:compose.erc173
    struct OwnerStorage {
        address owner;
    }

    /// @notice Returns a pointer to the ERC-173 storage struct.
    /// @dev Uses inline assembly to access the storage slot defined by STORAGE_POSITION.
    /// @return s The ERC173Storage struct in storage.
    function getStorage() internal pure returns (OwnerStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() internal view returns (address) {
        return getStorage().owner;
    }

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) internal {
        OwnerStorage storage s = getStorage();
        if (s.owner == address(0)) {
            revert OwnerAlreadyRenounced();
        }
        address previousOwner = s.owner;
        s.owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}

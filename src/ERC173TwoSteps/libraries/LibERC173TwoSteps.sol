// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/// @title ERC-173 Two-Step Contract Ownership Library
/// @notice Provides two-step ownership transfer logic for facets or modular contracts.
library LibERC173TwoSteps {
    /// @dev Emitted when ownership transfer is initiated (pending owner set).
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    /// @dev Emitted when ownership transfer is finalized.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Thrown when a non-owner or non-pending owner tries to act.
    error OwnableUnauthorizedAccount();
    /// @notice Thrown when attempting to transfer ownership of a renounced contract.
    error OwnableAlreadyRenounced();
    /// @notice Thrown when attempting to initialize the contract more than once.
    error OwnableAlreadyInitialized();

    bytes32 constant STORAGE_POSITION = keccak256("compose.erc173twosteps");

    /// @custom:storage-location erc8042:compose.erc173
    struct ERC173TwoStepsStorage {
        bool initialized;
        address owner;
        address pendingOwner;
    }

    /// @notice Initializes the contract.
    /// @dev Initializes the contract and sets the owner to the caller.
    function initialize() external {
        ERC173TwoStepsStorage storage s = getStorage();
        if (s.initialized) {
            revert OwnableAlreadyInitialized();
        }
        s.initialized = true;
        s.owner = msg.sender;
    }

    /// @notice Returns a pointer to the ERC-173 storage struct.
    /// @dev Uses inline assembly to access the storage slot defined by STORAGE_POSITION.
    /// @return s The ERC173Storage struct in storage.
    function getStorage() internal pure returns (ERC173TwoStepsStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /// @notice Returns the current owner.
    function owner() internal view returns (address) {
        return getStorage().owner;
    }

    /// @notice Returns the pending owner (if any).
    function pendingOwner() internal view returns (address) {
        return getStorage().pendingOwner;
    }

    /// @notice Initiates a two-step ownership transfer.
    /// @param _newOwner The address of the new owner (set to `address(0)` to renounce).
    function transferOwnership(address _newOwner) internal {
        ERC173TwoStepsStorage storage s = getStorage();
        if (s.owner == address(0)) revert OwnableAlreadyRenounced();
        if (msg.sender != s.owner) revert OwnableUnauthorizedAccount();

        s.pendingOwner = _newOwner;
        emit OwnershipTransferStarted(s.owner, _newOwner);
    }

    /// @notice Finalizes ownership transfer; must be called by the pending owner.
    function acceptOwnership() internal {
        ERC173TwoStepsStorage storage s = getStorage();
        if (msg.sender != s.pendingOwner) revert OwnableUnauthorizedAccount();

        address oldOwner = s.owner;
        s.owner = s.pendingOwner;
        s.pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, s.owner);
    }
}

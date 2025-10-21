// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import {LibERC1155} from "./libraries/LibERC1155.sol";

/// @title ERC-1155 Multi-Token Standard (Zero-Dependency Implementation)
/// @notice A complete, dependency-free ERC-1155 implementation using the diamond storage pattern.
/// @dev This facet provides multi-token functionality, batch operations, safe transfers, minting, burning, and approvals.
contract ERC1155Facet {

    /// @notice Error indicating the queried owner address is invalid (zero address).
    error ERC1155InvalidOwner(address _owner);

    /// @notice Error indicating that the queried token does not exist.
    error ERC1155NonexistentToken(uint256 _tokenId);

    /// @notice Error indicating the sender does not match the token owner.
    error ERC1155IncorrectOwner(address _sender, uint256 _tokenId, address _owner);

    /// @notice Error indicating the sender address is invalid.
    error ERC1155InvalidSender(address _sender);

    /// @notice Error indicating the receiver address is invalid.
    error ERC1155InvalidReceiver(address _receiver);

    /// @notice Error indicating the operator lacks approval to transfer the given token.
    error ERC1155InsufficientApproval(address _operator, uint256 _tokenId);

    /// @notice Error indicating the approver address is invalid.
    error ERC1155InvalidApprover(address _approver);

    /// @notice Error indicating the operator address is invalid.
    error ERC1155InvalidOperator(address _operator);

    /// @notice Error indicating arrays have different lengths in batch operations.
    error ERC1155InvalidArrayLength(uint256 _idsLength, uint256 _valuesLength);

    /// @notice Emitted when a single token type is transferred.
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /// @notice Emitted when multiple token types are transferred.
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /// @notice Emitted when an operator is enabled or disabled for an owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Emitted when the URI for a token type is updated.
    event URI(string _value, uint256 indexed _id);

    /// @notice Returns the amount of tokens of token type `_id` owned by `_account`.
    /// @param _account The address to query the balance of.
    /// @param _id The token ID to query.
    /// @return The balance of the token type for the account.
    function balanceOf(address _account, uint256 _id) external view returns (uint256) {
        if (_account == address(0)) {
            revert ERC1155InvalidOwner(address(0));
        }
        LibERC1155.ERC1155Storage storage s = LibERC1155.getStorage();
        return s.balanceOf[_id][_account];
    }

    /// @notice Returns the amounts of tokens of token types `_ids` owned by `_accounts`.
    /// @param _accounts The addresses to query the balances of.
    /// @param _ids The token IDs to query.
    /// @return The balances of the token types for the accounts.
    function balanceOfBatch(address[] calldata _accounts, uint256[] calldata _ids) external view returns (uint256[] memory) {
        if (_accounts.length != _ids.length) {
            revert ERC1155InvalidArrayLength(_accounts.length, _ids.length);
        }

        uint256[] memory batchBalances = new uint256[](_accounts.length);
        LibERC1155.ERC1155Storage storage s = LibERC1155.getStorage();

        for (uint256 i = 0; i < _accounts.length; ++i) {
            if (_accounts[i] == address(0)) {
                revert ERC1155InvalidOwner(address(0));
            }
            batchBalances[i] = s.balanceOf[_ids[i]][_accounts[i]];
        }

        return batchBalances;
    }

    /// @notice Enables or disables approval for a third party ("operator") to manage all of the caller's tokens.
    /// @param _operator The address to add to the set of authorized operators.
    /// @param _approved True if the operator is approved, false to revoke approval.
    function setApprovalForAll(address _operator, bool _approved) external {
        if (_operator == address(0)) {
            revert ERC1155InvalidOperator(address(0));
        }
        LibERC1155.setApprovalForAll(_operator, _approved);
    }

    /// @notice Returns true if `_operator` is approved to transfer `_account`'s tokens.
    /// @param _account The address to query the approval of.
    /// @param _operator The address to query the approval for.
    /// @return True if the operator is approved, false otherwise.
    function isApprovedForAll(address _account, address _operator) external view returns (bool) {
        LibERC1155.ERC1155Storage storage s = LibERC1155.getStorage();
        return s.isApprovedForAll[_account][_operator];
    }

    /// @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address.
    /// @param _from The address to transfer from.
    /// @param _to The address to transfer to.
    /// @param _id The token ID to transfer.
    /// @param _value The amount to transfer.
    /// @param _data Additional data with no specified format.
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external {
        LibERC1155.transferFrom(_from, _to, _id, _value, _data);
    }

    /// @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address.
    /// @param _from The address to transfer from.
    /// @param _to The address to transfer to.
    /// @param _ids The token IDs to transfer.
    /// @param _values The amounts to transfer.
    /// @param _data Additional data with no specified format.
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external {
        LibERC1155.transferFromBatch(_from, _to, _ids, _values, _data);
    }

    /// @notice Mints `_value` amount of tokens of token type `_id` to `_to`.
    /// @param _to The address to mint tokens to.
    /// @param _id The token ID to mint.
    /// @param _value The amount to mint.
    /// @param _data Additional data with no specified format.
    function mint(address _to, uint256 _id, uint256 _value, bytes memory _data) external {
        LibERC1155.mint(_to, _id, _value, _data);
    }

    /// @notice Mints `_values` amount(s) of tokens of token types `_ids` to `_to`.
    /// @param _to The address to mint tokens to.
    /// @param _ids The token IDs to mint.
    /// @param _values The amounts to mint.
    /// @param _data Additional data with no specified format.
    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) external {
        LibERC1155.mintBatch(_to, _ids, _values, _data);
    }

    /// @notice Burns `_value` amount of tokens of token type `_id` from `_from`.
    /// @param _from The address to burn tokens from.
    /// @param _id The token ID to burn.
    /// @param _value The amount to burn.
    function burn(address _from, uint256 _id, uint256 _value) external {
        LibERC1155.burn(_from, _id, _value);
    }

    /// @notice Burns `_values` amount(s) of tokens of token types `_ids` from `_from`.
    /// @param _from The address to burn tokens from.
    /// @param _ids The token IDs to burn.
    /// @param _values The amounts to burn.
    function burnBatch(address _from, uint256[] memory _ids, uint256[] memory _values) external {
        LibERC1155.burnBatch(_from, _ids, _values);
    }

    /// @notice Returns the URI for token type `_id`.
    /// @param _id The token ID to query.
    /// @return The URI for the token type.
    function uri(uint256 _id) external view returns (string memory) {
        LibERC1155.ERC1155Storage storage s = LibERC1155.getStorage();
        string memory baseURI = s.uri;
        if (bytes(baseURI).length == 0) {
            return "";
        }
        
        // Replace {id} with the actual token ID
        bytes memory baseBytes = bytes(baseURI);
        bytes memory idBytes = bytes(_toString(_id));
        
        // Calculate the result length
        uint256 resultLength = 0;
        bool foundId = false;
        for (uint256 i = 0; i < baseBytes.length; i++) {
            if (i < baseBytes.length - 3 && 
                baseBytes[i] == '{' && 
                baseBytes[i + 1] == 'i' && 
                baseBytes[i + 2] == 'd' && 
                baseBytes[i + 3] == '}') {
                resultLength += idBytes.length;
                foundId = true;
                i += 3; // Skip the remaining characters of {id}
            } else {
                resultLength++;
            }
        }
        
        if (!foundId) {
            return baseURI; // No {id} placeholder found
        }
        
        bytes memory result = new bytes(resultLength);
        uint256 resultIndex = 0;
        
        for (uint256 i = 0; i < baseBytes.length; i++) {
            if (i < baseBytes.length - 3 && 
                baseBytes[i] == '{' && 
                baseBytes[i + 1] == 'i' && 
                baseBytes[i + 2] == 'd' && 
                baseBytes[i + 3] == '}') {
                // Replace {id} with the token ID
                for (uint256 j = 0; j < idBytes.length; j++) {
                    result[resultIndex] = idBytes[j];
                    resultIndex++;
                }
                i += 3; // Skip the remaining characters of {id}
            } else {
                result[resultIndex] = baseBytes[i];
                resultIndex++;
            }
        }
        
        return string(result);
    }

    /// @notice Sets the URI for all token types.
    /// @param _newuri The new URI value.
    function setURI(string memory _newuri) external {
        LibERC1155.setURI(_newuri);
    }

    /// @notice Converts a uint256 to its ASCII string decimal representation.
    /// @param _value The value to convert.
    /// @return The string representation of the value.
    function _toString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }
}

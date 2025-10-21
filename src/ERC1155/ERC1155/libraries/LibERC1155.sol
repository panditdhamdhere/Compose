// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/// @title LibERC1155 — ERC-1155 Library
/// @notice Provides internal functions and storage layout for ERC-1155 multi-token logic.
/// @dev Uses ERC-8042 for storage location standardization and ERC-6093 for error conventions.
library LibERC1155 {

    /// @notice Thrown when a sender attempts to transfer or burn more tokens than their balance.
    /// @param _sender The address attempting the transfer or burn.
    /// @param _balance The sender's current balance.
    /// @param _needed The amount required to complete the operation.
    error ERC1155InsufficientBalance(address _sender, uint256 _balance, uint256 _needed);

    /// @notice Thrown when the sender address is invalid (e.g., zero address).
    /// @param _sender The invalid sender address.
    error ERC1155InvalidSender(address _sender);

    /// @notice Thrown when the receiver address is invalid (e.g., zero address).
    /// @param _receiver The invalid receiver address.
    error ERC1155InvalidReceiver(address _receiver);

    /// @notice Thrown when a spender tries to spend more than their allowance.
    /// @param _spender The address attempting to spend.
    /// @param _allowance The current allowance.
    /// @param _needed The required amount to complete the transfer.
    error ERC1155InsufficientAllowance(address _spender, uint256 _allowance, uint256 _needed);

    /// @notice Thrown when arrays have different lengths in batch operations.
    /// @param _idsLength The length of the IDs array.
    /// @param _valuesLength The length of the values array.
    error ERC1155InvalidArrayLength(uint256 _idsLength, uint256 _valuesLength);

    /// @notice Thrown when attempting to transfer to a non-receiver contract.
    /// @param _receiver The address that should implement IERC1155Receiver.
    error ERC1155InvalidReceiverContract(address _receiver);

    /// @notice Emitted when tokens are transferred between addresses.
    /// @param _operator The address which initiated the transfer.
    /// @param _from The address tokens are transferred from.
    /// @param _to The address tokens are transferred to.
    /// @param _id The token ID being transferred.
    /// @param _value The amount of tokens transferred.
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /// @notice Emitted when multiple tokens are transferred between addresses.
    /// @param _operator The address which initiated the transfer.
    /// @param _from The address tokens are transferred from.
    /// @param _to The address tokens are transferred to.
    /// @param _ids The token IDs being transferred.
    /// @param _values The amounts of tokens transferred.
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /// @notice Emitted when an approval is made for an operator by an owner.
    /// @param _owner The address granting the approval.
    /// @param _operator The address receiving the approval.
    /// @param _approved Whether the operator is approved.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Emitted when the URI for a token type is updated.
    /// @param _value The new URI value.
    /// @param _id The token ID for which the URI was updated.
    event URI(string _value, uint256 indexed _id);

    /// @notice Storage slot identifier, defined using keccak256 hash of the library diamond storage identifier.
    bytes32 constant STORAGE_POSITION = keccak256("compose.erc1155");

    /// @notice ERC-1155 storage layout using the ERC-8042 standard.
    /// @custom:storage-location erc8042:compose.erc1155
    struct ERC1155Storage {
        string uri;
        mapping(uint256 id => mapping(address account => uint256)) balanceOf;
        mapping(address account => mapping(address operator => bool)) isApprovedForAll;
    }

    /// @notice Returns a pointer to the ERC-1155 storage struct.
    /// @dev Uses inline assembly to bind the storage struct to the fixed storage position.
    /// @return s The ERC-1155 storage struct.
    function getStorage() internal pure returns (ERC1155Storage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /// @notice Mints new tokens to a specified address.
    /// @dev Increases the recipient's balance for the given token ID.
    /// @param _to The address receiving the newly minted tokens.
    /// @param _id The token ID to mint.
    /// @param _value The number of tokens to mint.
    /// @param _data Additional data with no specified format.
    function mint(address _to, uint256 _id, uint256 _value, bytes memory _data) internal {
        ERC1155Storage storage s = getStorage();
        if (_to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        unchecked {
            s.balanceOf[_id][_to] += _value;
        }
        emit TransferSingle(msg.sender, address(0), _to, _id, _value);
        
        if (_to.code.length > 0) {
            _doSafeTransferAcceptanceCheck(msg.sender, address(0), _to, _id, _value, _data);
        }
    }

    /// @notice Mints multiple token types to a specified address.
    /// @dev Increases the recipient's balance for the given token IDs.
    /// @param _to The address receiving the newly minted tokens.
    /// @param _ids The token IDs to mint.
    /// @param _values The numbers of tokens to mint for each ID.
    /// @param _data Additional data with no specified format.
    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {
        ERC1155Storage storage s = getStorage();
        if (_to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (_ids.length != _values.length) {
            revert ERC1155InvalidArrayLength(_ids.length, _values.length);
        }
        
        for (uint256 i = 0; i < _ids.length; i++) {
            unchecked {
                s.balanceOf[_ids[i]][_to] += _values[i];
            }
        }
        
        emit TransferBatch(msg.sender, address(0), _to, _ids, _values);
        
        if (_to.code.length > 0) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), _to, _ids, _values, _data);
        }
    }

    /// @notice Burns tokens from a specified address.
    /// @dev Decreases the sender's balance for the given token ID.
    /// @param _from The address whose tokens will be burned.
    /// @param _id The token ID to burn.
    /// @param _value The number of tokens to burn.
    function burn(address _from, uint256 _id, uint256 _value) internal {
        ERC1155Storage storage s = getStorage();
        if (_from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        uint256 fromBalance = s.balanceOf[_id][_from];
        if (fromBalance < _value) {
            revert ERC1155InsufficientBalance(_from, fromBalance, _value);
        }
        unchecked {
            s.balanceOf[_id][_from] = fromBalance - _value;
        }
        emit TransferSingle(msg.sender, _from, address(0), _id, _value);
    }

    /// @notice Burns multiple token types from a specified address.
    /// @dev Decreases the sender's balance for the given token IDs.
    /// @param _from The address whose tokens will be burned.
    /// @param _ids The token IDs to burn.
    /// @param _values The numbers of tokens to burn for each ID.
    function burnBatch(address _from, uint256[] memory _ids, uint256[] memory _values) internal {
        ERC1155Storage storage s = getStorage();
        if (_from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        if (_ids.length != _values.length) {
            revert ERC1155InvalidArrayLength(_ids.length, _values.length);
        }
        
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 fromBalance = s.balanceOf[_ids[i]][_from];
            if (fromBalance < _values[i]) {
                revert ERC1155InsufficientBalance(_from, fromBalance, _values[i]);
            }
            unchecked {
                s.balanceOf[_ids[i]][_from] = fromBalance - _values[i];
            }
        }
        
        emit TransferBatch(msg.sender, _from, address(0), _ids, _values);
    }

    /// @notice Transfers tokens from one address to another.
    /// @dev Updates balances directly without allowance mechanism.
    /// @param _from The address to send tokens from.
    /// @param _to The address to send tokens to.
    /// @param _id The token ID to transfer.
    /// @param _value The number of tokens to transfer.
    /// @param _data Additional data with no specified format.
    function transferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {
        ERC1155Storage storage s = getStorage();
        if (_from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        if (_to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        
        uint256 fromBalance = s.balanceOf[_id][_from];
        if (fromBalance < _value) {
            revert ERC1155InsufficientBalance(_from, fromBalance, _value);
        }
        
        if (msg.sender != _from && !s.isApprovedForAll[_from][msg.sender]) {
            revert ERC1155InsufficientAllowance(msg.sender, 0, _value);
        }
        
        unchecked {
            s.balanceOf[_id][_from] = fromBalance - _value;
            s.balanceOf[_id][_to] += _value;
        }
        
        emit TransferSingle(msg.sender, _from, _to, _id, _value);
        
        if (_to.code.length > 0) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }

    /// @notice Transfers multiple token types from one address to another.
    /// @dev Updates balances directly without allowance mechanism.
    /// @param _from The address to send tokens from.
    /// @param _to The address to send tokens to.
    /// @param _ids The token IDs to transfer.
    /// @param _values The numbers of tokens to transfer for each ID.
    /// @param _data Additional data with no specified format.
    function transferFromBatch(address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {
        ERC1155Storage storage s = getStorage();
        if (_from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        if (_to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (_ids.length != _values.length) {
            revert ERC1155InvalidArrayLength(_ids.length, _values.length);
        }
        
        if (msg.sender != _from && !s.isApprovedForAll[_from][msg.sender]) {
            revert ERC1155InsufficientAllowance(msg.sender, 0, 0);
        }
        
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 fromBalance = s.balanceOf[_ids[i]][_from];
            if (fromBalance < _values[i]) {
                revert ERC1155InsufficientBalance(_from, fromBalance, _values[i]);
            }
            unchecked {
                s.balanceOf[_ids[i]][_from] = fromBalance - _values[i];
                s.balanceOf[_ids[i]][_to] += _values[i];
            }
        }
        
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
        
        if (_to.code.length > 0) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        }
    }

    /// @notice Approves an operator to transfer tokens on behalf of the caller.
    /// @dev Sets the approval for the operator.
    /// @param _operator The address to approve for transfers.
    /// @param _approved Whether the operator is approved.
    function setApprovalForAll(address _operator, bool _approved) internal {
        ERC1155Storage storage s = getStorage();
        s.isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Sets the URI for a token type.
    /// @dev Emits a URI event for the token ID.
    /// @param _newuri The new URI value.
    function setURI(string memory _newuri) internal {
        ERC1155Storage storage s = getStorage();
        s.uri = _newuri;
        emit URI(_newuri, 0);
    }

    /// @notice Performs a safe transfer acceptance check for a single token.
    /// @dev Calls onERC1155Received on the recipient if it's a contract.
    /// @param _operator The address which initiated the transfer.
    /// @param _from The address tokens are transferred from.
    /// @param _to The address tokens are transferred to.
    /// @param _id The token ID being transferred.
    /// @param _value The amount of tokens transferred.
    /// @param _data Additional data with no specified format.
    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) private {
        try IERC1155Receiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) returns (bytes4 response) {
            if (response != IERC1155Receiver.onERC1155Received.selector) {
                revert ERC1155InvalidReceiverContract(_to);
            }
        } catch {
            revert ERC1155InvalidReceiverContract(_to);
        }
    }

    /// @notice Performs a safe transfer acceptance check for multiple tokens.
    /// @dev Calls onERC1155BatchReceived on the recipient if it's a contract.
    /// @param _operator The address which initiated the transfer.
    /// @param _from The address tokens are transferred from.
    /// @param _to The address tokens are transferred to.
    /// @param _ids The token IDs being transferred.
    /// @param _values The amounts of tokens transferred.
    /// @param _data Additional data with no specified format.
    function _doSafeBatchTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) private {
        try IERC1155Receiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) returns (bytes4 response) {
            if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                revert ERC1155InvalidReceiverContract(_to);
            }
        } catch {
            revert ERC1155InvalidReceiverContract(_to);
        }
    }
}

/// @title ERC-1155 Token Receiver Interface
/// @notice Interface for contracts that want to handle safe transfers of ERC-1155 tokens.
/// @dev Contracts implementing this must return the selector to confirm token receipt.
interface IERC1155Receiver {
    /// @notice Handles the receipt of a single ERC-1155 token type.
    /// @param _operator The address which initiated the transfer.
    /// @param _from The previous owner of the token.
    /// @param _id The token ID being transferred.
    /// @param _value The amount of tokens transferred.
    /// @param _data Additional data with no specified format.
    /// @return The selector to confirm the token transfer.
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /// @notice Handles the receipt of multiple ERC-1155 token types.
    /// @param _operator The address which initiated the transfer.
    /// @param _from The previous owner of the tokens.
    /// @param _ids The token IDs being transferred.
    /// @param _values The amounts of tokens transferred.
    /// @param _data Additional data with no specified format.
    /// @return The selector to confirm the token transfer.
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;


/// @notice Interface for contracts that want to support safeTransfers.
interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}


/// @title ERC-721 token (zero-dependency implementation)
/// @notice A complete, dependency-free ERC-721 implementation using the project's storage pattern.
/// @dev This contract provides metadata, ownership, approvals, safe transfers (with local IERC721Receiver check),
/// minting, burning, and helpers. It intentionally avoids external imports.
contract ERC721 {

    // ERC-6093: Custom errors for ERC-721
    error ERC721InvalidOwner(address _owner);
    error ERC721NonexistentToken(uint256 _tokenId);
    error ERC721IncorrectOwner(address _sender, uint256 _tokenId, address _owner);
    error ERC721InvalidSender(address _sender);
    error ERC721InvalidReceiver(address _receiver);
    error ERC721InsufficientApproval(address _operator, uint256 _tokenId);
    error ERC721InvalidApprover(address _approver);
    error ERC721InvalidOperator(address _operator);

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // Struct storage position defined by keccak256 hash 
    // of diamond storage identifier
    bytes32 constant STORAGE_POSITION = keccak256("compose.erc721");

    // Storage defined using the ERC-8042 standard
    // @custom:storage-location erc8042:compose.erc721
    struct ERC721Storage {
        string name;
        string symbol;        
        mapping(uint256 tokenId => address owner) ownerOf;
        mapping(address owner => uint256 balance) balanceOf;
        mapping(uint256 tokenId => address approved) approved;
        mapping(address owner => mapping(address operator => bool approved)) isApprovedForAll;   
    }

    function getStorage() internal pure returns (ERC721Storage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
        
    function name() external view returns (string memory) {
        return getStorage().name;
    }

    function symbol() external view returns (string memory) {
        return getStorage().symbol;
    }    

    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == address(0)) {
            revert ERC721InvalidOwner(_owner);
        }
        return getStorage().balanceOf[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = getStorage().ownerOf[_tokenId];
        if (owner == address(0)) {
            revert ERC721NonexistentToken(_tokenId);
        } 
        return owner;
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        address owner = getStorage().ownerOf[_tokenId];
        if (owner == address(0)) {
            revert ERC721NonexistentToken(_tokenId);
        }
        return getStorage().approved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return getStorage().isApprovedForAll[_owner][_operator];
    }

    function approve(address _approved, uint256 _tokenId) external {
        ERC721Storage storage s = getStorage();
        address owner = s.ownerOf[_tokenId];
        if (owner == address(0)) {
            revert ERC721NonexistentToken(_tokenId);
        }
        if (msg.sender != owner && !s.isApprovedForAll[owner][msg.sender]) {
            revert ERC721InvalidApprover(_approved);
        }        
        s.approved[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);        
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        if (_operator == address(0)) {
            revert ERC721InvalidOperator(_operator);
        }
        getStorage().isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }  
 
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        ERC721Storage storage s = getStorage();
         if (_to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address owner = s.ownerOf[_tokenId];
        if (owner == address(0)) {
            revert ERC721NonexistentToken(_tokenId);
        }
        if (owner != _from) {
            revert ERC721IncorrectOwner(_from, _tokenId, owner);
        }        
        if (msg.sender != _from) {
            if(!s.isApprovedForAll[_from][msg.sender] && msg.sender != s.approved[_tokenId]) {
                revert ERC721InsufficientApproval(msg.sender, _tokenId);
            }
        }
        delete s.approved[_tokenId];
        unchecked {
            s.balanceOf[_from]--;
            s.balanceOf[_to]++;
        }
        s.ownerOf[_tokenId] = _to;        
        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        ERC721Storage storage s = getStorage();
         if (_to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address owner = s.ownerOf[_tokenId];
        if (owner == address(0)) {
            revert ERC721NonexistentToken(_tokenId);
        }
        if (owner != _from) {
            revert ERC721IncorrectOwner(_from, _tokenId, owner);
        }        
        if (msg.sender != _from) {
            if(!s.isApprovedForAll[_from][msg.sender] && msg.sender != s.approved[_tokenId]) {
                revert ERC721InsufficientApproval(msg.sender, _tokenId);
            }
        }
        delete s.approved[_tokenId];
        unchecked {
            s.balanceOf[_from]--;
            s.balanceOf[_to]++;
        }
        s.ownerOf[_tokenId] = _to;        
        emit Transfer(_from, _to, _tokenId);

        // If _to is a contract, check for IERC721Receiver implementation
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(_to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-IERC721Receiver implementer
                    revert ERC721InvalidReceiver(_to);
                } else {
                    assembly ("memory-safe") {
                        revert(add(reason, 0x20), mload(reason))
                    }
                }
            }
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external {
        ERC721Storage storage s = getStorage();
         if (_to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address owner = s.ownerOf[_tokenId];
        if (owner == address(0)) {
            revert ERC721NonexistentToken(_tokenId);
        }
        if (owner != _from) {
            revert ERC721IncorrectOwner(_from, _tokenId, owner);
        }        
        if (msg.sender != _from) {
            if(!s.isApprovedForAll[_from][msg.sender] && msg.sender != s.approved[_tokenId]) {
                revert ERC721InsufficientApproval(msg.sender, _tokenId);
            }
        }
        delete s.approved[_tokenId];
        unchecked {
            s.balanceOf[_from]--;
            s.balanceOf[_to]++;
        }
        s.ownerOf[_tokenId] = _to;        
        emit Transfer(_from, _to, _tokenId);

        // If _to is a contract, check for IERC721Receiver implementation
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(_to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-IERC721Receiver implementer
                    revert ERC721InvalidReceiver(_to);
                } else {
                    assembly ("memory-safe") {
                        revert(add(reason, 0x20), mload(reason))
                    }
                }
            }
        }
    }

    function _mint(address _to, uint256 _tokenId) internal {
        ERC721Storage storage s = getStorage();
        if (_to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        if (s.ownerOf[_tokenId] != address(0)) {
            revert ERC721NonexistentToken(_tokenId);
        }
        s.ownerOf[_tokenId] = _to;
        unchecked {
            s.balanceOf[_to]++;
        }
        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal {
        ERC721Storage storage s = getStorage();
        address owner = s.ownerOf[_tokenId];
        if (owner == address(0)) {
            revert ERC721NonexistentToken(_tokenId);
        }
        delete s.ownerOf[_tokenId];
        delete s.approved[_tokenId];
        unchecked {
            s.balanceOf[owner]--;
        }
        emit Transfer(owner, address(0), _tokenId);
    }
    
}
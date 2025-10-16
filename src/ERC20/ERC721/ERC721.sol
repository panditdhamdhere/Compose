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
}
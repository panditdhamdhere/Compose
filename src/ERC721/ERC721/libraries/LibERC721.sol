// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

library LibERC721 {

    // ERC-6093: Custom errors for ERC-721    
    error ERC721NonexistentToken(uint256 _tokenId);    
    error ERC721IncorrectOwner(address _sender, uint256 _tokenId, address _owner);
    error ERC721InvalidSender(address _sender);
    error ERC721InvalidReceiver(address _receiver);
    error ERC721InsufficientApproval(address _operator, uint256 _tokenId);

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
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

    function transferFrom(address _from, address _to, uint256 _tokenId) internal {
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

    function mint(address _to, uint256 _tokenId) internal {
        ERC721Storage storage s = getStorage();
        if (_to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        if (s.ownerOf[_tokenId] != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
        s.ownerOf[_tokenId] = _to;
        unchecked {
            s.balanceOf[_to]++;
        }
        emit Transfer(address(0), _to, _tokenId);
    }

    function burn(uint256 _tokenId) internal {
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
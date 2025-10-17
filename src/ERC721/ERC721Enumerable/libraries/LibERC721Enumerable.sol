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
    bytes32 constant STORAGE_POSITION = keccak256("compose.erc721.enumerable");

    // Storage defined using the ERC-8042 standard
    // @custom:storage-location erc8042:compose.erc721.enumerable
    struct ERC721EnumerableStorage {
        string name;
        string symbol;        
        
        mapping(uint256 tokenId => address owner) ownerOf;
        mapping(address owner => uint256[] ownedTokens) ownedTokensOf;
        mapping(uint256 tokenId => uint256 ownedTokensIndex) ownedTokensIndexOf;
        uint256[] allTokens;
        mapping(uint256 tokenId => uint256 allTokensIndex) allTokensIndexOf;

        mapping(uint256 tokenId => address approved) approved;
        mapping(address owner => mapping(address operator => bool approved)) isApprovedForAll;   
    }

    function getStorage() internal pure returns (ERC721EnumerableStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function transferFrom(address _from, address _to, uint256 _tokenId, address _sender) internal {
        ERC721EnumerableStorage storage s = getStorage();
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
        if (_sender != _from) {
            if(!s.isApprovedForAll[_from][_sender] && _sender != s.approved[_tokenId]) {
                revert ERC721InsufficientApproval(_sender, _tokenId);
            }
        }
        delete s.approved[_tokenId];
        // removing token from _from's ownedTokens
        uint256 tokenIndex = s.ownedTokensIndexOf[_tokenId];
        uint256 lastTokenIndex = s.ownedTokensOf[_from].length - 1;
        if(tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = s.ownedTokensOf[_from][lastTokenIndex];
            s.ownedTokensOf[_from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            s.ownedTokensIndexOf[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        s.ownedTokensOf[_from].pop(); 
        // adding token to _to's ownedTokens
        s.ownedTokensIndexOf[_tokenId] = s.ownedTokensOf[_to].length;
        s.ownedTokensOf[_to].push(_tokenId);
        s.ownerOf[_tokenId] = _to;        
        emit Transfer(_from, _to, _tokenId);
    }

    function mint(address _to, uint256 _tokenId) internal {
        ERC721EnumerableStorage storage s = getStorage();
        if (_to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        if (s.ownerOf[_tokenId] != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
        s.ownedTokensIndexOf[_tokenId] = s.ownedTokensOf[_to].length;
        s.ownedTokensOf[_to].push(_tokenId);
        
        s.allTokensIndexOf[_tokenId] = s.allTokens.length;
        s.allTokens.push(_tokenId);       

        emit Transfer(address(0), _to, _tokenId);
    }

    function burn(uint256 _tokenId, address _sender) internal {
        ERC721EnumerableStorage storage s = getStorage();
        address owner = s.ownerOf[_tokenId];
        if (owner == address(0)) {
            revert ERC721NonexistentToken(_tokenId);
        }
        if (_sender != owner) {
            if(!s.isApprovedForAll[owner][_sender] && _sender != s.approved[_tokenId]) {
                revert ERC721InsufficientApproval(_sender, _tokenId);
            }
        }
        delete s.ownerOf[_tokenId];
        delete s.approved[_tokenId];

        // removing token from _from's ownedTokens
        uint256 tokenIndex = s.ownedTokensIndexOf[_tokenId];
        uint256 lastTokenIndex = s.ownedTokensOf[owner].length - 1;
        if(tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = s.ownedTokensOf[owner][lastTokenIndex];
            s.ownedTokensOf[owner][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            s.ownedTokensIndexOf[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        s.ownedTokensOf[owner].pop(); 

        // removing token from allTokens
        tokenIndex = s.allTokensIndexOf[_tokenId];
        lastTokenIndex = s.allTokens.length - 1;
        if(tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = s.allTokens[lastTokenIndex];
            s.allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            s.allTokensIndexOf[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        s.allTokens.pop();        

        emit Transfer(owner, address(0), _tokenId);
    }



}
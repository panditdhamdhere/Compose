// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

library LibERC20 {    
            
    // Struct storage position defined by keccak256 hash 
    // of diamond storage identifier
    bytes32 constant STORAGE_POSITION = keccak256("compose.erc20");

    // Storage defined using the ERC-8042 standard
    // @custom:storage-location erc8042:compose.erc20
    struct ERC20Storage {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balanceOf;
        mapping(address => mapping(address => uint256)) allowances;   
    }

    function getStorage() internal pure returns (ERC20Storage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
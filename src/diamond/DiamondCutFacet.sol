// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

// import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
// import { LibDiamond } from "../libraries/LibDiamond.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard
// contract DiamondCutFacet {

//     bytes32 constant ERC173_STORAGE_POSITION = keccak256("compose.erc173");
    
//     /// @custom:storage-location erc8042:compose.erc173
//     struct ERC173Storage {
//         address owner;
//     }    

//     /// @notice Returns a pointer to the ERC-173 storage struct.
//     /// @dev Uses inline assembly to access the storage slot defined by STORAGE_POSITION.
//     /// @return s The ERC173Storage struct in storage.
//     function getOwnerStorage() internal pure returns (ERC173Storage storage s) {
//         bytes32 position = STORAGE_POSITION;
//         assembly {
//             s.slot := position
//         }
//     }




//     /// @notice Add/replace/remove any number of functions and optionally execute
//     ///         a function with delegatecall
//     /// @param _diamondCut Contains the facet addresses and function selectors
//     /// @param _init The address of the contract or facet to execute _calldata
//     /// @param _calldata A function call, including function selector and arguments
//     ///                  _calldata is executed with delegatecall on _init
//     function diamondCut(
//         FacetCut[] calldata _diamondCut,
//         address _init,
//         bytes calldata _calldata
//     ) external override {
//         LibDiamond.enforceIsContractOwner();
//         LibDiamond.diamondCut(_diamondCut, _init, _calldata);
//     }
// }
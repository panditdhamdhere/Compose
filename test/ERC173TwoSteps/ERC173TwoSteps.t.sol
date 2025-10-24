// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.30;

// import {Test, console2} from "forge-std/Test.sol";
// import {ERC173TwoStepsFacet} from "../../src/ERC173TwoSteps/ERC173TwoSteps.sol";

// contract ERC173TwoStepsTest is Test {
//     ERC173TwoStepsFacet public erc173TwoSteps;
//     address owner = makeAddr("owner");
//     address newOwner = makeAddr("newOwner");

//     function setUp() public {
//         erc173TwoSteps = new ERC173TwoStepsFacet();
//         vm.prank(owner);
//         erc173TwoSteps.initialize();
//     }

//     function test_changeOwnership() public {
//         vm.prank(owner);
//         erc173TwoSteps.transferOwnership(newOwner);
//         assertEq(erc173TwoSteps.owner(), owner);
//         assertEq(erc173TwoSteps.pendingOwner(), newOwner);
//     }

//     function test_canNotInitializeMoreThanOne() public {
//         vm.expectRevert(ERC173TwoStepsFacet.OwnableAlreadyInitialized.selector);
//         erc173TwoSteps.initialize();
//     }

//     function test_transferOwnership() public {
//         vm.prank(owner);
//         erc173TwoSteps.transferOwnership(newOwner);
//         assertEq(erc173TwoSteps.owner(), owner);
//         assertEq(erc173TwoSteps.pendingOwner(), newOwner);

//         vm.prank(newOwner);
//         erc173TwoSteps.acceptOwnership();
//         assertEq(erc173TwoSteps.owner(), newOwner);
//         assertEq(erc173TwoSteps.pendingOwner(), address(0));
//     }

//     function test_onlyOwnerCanInitiateTransferOwnership() public {
//         address hacker = makeAddr("hacker");
//         vm.prank(hacker);
//         vm.expectRevert(ERC173TwoStepsFacet.OwnableUnauthorizedAccount.selector);
//         erc173TwoSteps.transferOwnership(hacker);
//     }

//     function test_transferOwnershipFailed() public {
//         vm.prank(owner);
//         erc173TwoSteps.transferOwnership(newOwner);
//         assertEq(erc173TwoSteps.owner(), owner);
//         assertEq(erc173TwoSteps.pendingOwner(), newOwner);

//         address hacker = makeAddr("hacker");
//         vm.prank(hacker);
//         vm.expectRevert(ERC173TwoStepsFacet.OwnableUnauthorizedAccount.selector);
//         erc173TwoSteps.acceptOwnership();
//     }
// }

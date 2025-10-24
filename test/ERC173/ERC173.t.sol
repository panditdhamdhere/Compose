// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {ERC173Facet} from "../../src/ERC173/ERC173.sol";

contract ERC173Test is Test {
    ERC173Facet public erc173;
    address owner = makeAddr("owner");
    address newOwner = makeAddr("newOwner");

    function setUp() public {
        erc173 = new ERC173Facet();
        vm.prank(owner);
        erc173.initialize();
    }

    function test_changeOwnership() public {
        vm.prank(owner);
        erc173.transferOwnership(newOwner);
        assertEq(erc173.owner(), owner);
        assertEq(erc173.pendingOwner(), newOwner);
    }

    function test_canNotInitializeMoreThanOne() public {
        vm.expectRevert(ERC173Facet.OwnableAlreadyInitialized.selector);
        erc173.initialize();
    }

    function test_transferOwnership() public {
        vm.prank(owner);
        erc173.transferOwnership(newOwner);
        assertEq(erc173.owner(), owner);
        assertEq(erc173.pendingOwner(), newOwner);

        vm.prank(newOwner);
        erc173.acceptOwnership();
        assertEq(erc173.owner(), newOwner);
        assertEq(erc173.pendingOwner(), address(0));
    }

    function test_onlyOwnerCanInitiateTransferOwnership() public {
        address hacker = makeAddr("hacker");
        vm.prank(hacker);
        vm.expectRevert(ERC173Facet.OwnableUnauthorizedAccount.selector);
        erc173.transferOwnership(hacker);
    }

    function test_transferOwnershipFailed() public {
        vm.prank(owner);
        erc173.transferOwnership(newOwner);
        assertEq(erc173.owner(), owner);
        assertEq(erc173.pendingOwner(), newOwner);

        address hacker = makeAddr("hacker");
        vm.prank(hacker);
        vm.expectRevert(ERC173Facet.OwnableUnauthorizedAccount.selector);
        erc173.acceptOwnership();
    }
}

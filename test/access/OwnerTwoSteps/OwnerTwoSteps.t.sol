// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {OwnerTwoStepsFacet} from "../../../src/access/OwnerTwoSteps/OwnerTwoSteps.sol";
import {OwnerTwoStepsFacetHarness} from "./harnesses/OwnerTwoStepsFacetHarness.sol";

contract OwnerTwoStepsFacetTest is Test {
    OwnerTwoStepsFacetHarness public ownerTwoSteps;

    address INITIAL_OWNER = makeAddr("owner");
    address NEW_OWNER = makeAddr("newOwner");
    address ALICE = makeAddr("alice");
    address BOB = makeAddr("bob");
    address ZERO_ADDRESS = address(0);

    // Events
    event OwnershipTransferStarted(address indexed _previousOwner, address indexed _newOwner);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    function setUp() public {
        ownerTwoSteps = new OwnerTwoStepsFacetHarness();
        ownerTwoSteps.initialize(INITIAL_OWNER);
    }

    // ============================================
    // Ownership Getter Tests
    // ============================================

    function test_Owner_ReturnsCorrectInitialOwner() public view {
        assertEq(ownerTwoSteps.owner(), INITIAL_OWNER);
    }

    function test_PendingOwner_InitiallyZero() public view {
        assertEq(ownerTwoSteps.pendingOwner(), ZERO_ADDRESS);
    }

    // ============================================
    // Transfer Ownership Initiation Tests
    // ============================================

    function test_TransferOwnership_OnlyOwnerCanInitiate() public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(NEW_OWNER);

        assertEq(ownerTwoSteps.owner(), INITIAL_OWNER);
        assertEq(ownerTwoSteps.pendingOwner(), NEW_OWNER);
    }

    function test_TransferOwnership_EmitsOwnershipTransferStartedEvent() public {
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferStarted(INITIAL_OWNER, NEW_OWNER);

        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(NEW_OWNER);
    }

    function test_TransferOwnership_CanTransferToZeroAddress() public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(ZERO_ADDRESS);

        assertEq(ownerTwoSteps.pendingOwner(), ZERO_ADDRESS);
    }

    function test_TransferOwnership_CanUpdatePendingOwner() public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(ALICE);
        assertEq(ownerTwoSteps.pendingOwner(), ALICE);

        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(BOB);
        assertEq(ownerTwoSteps.pendingOwner(), BOB);
    }

    function test_TransferOwnership_CanCancelBySettingToZero() public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(NEW_OWNER);
        assertEq(ownerTwoSteps.pendingOwner(), NEW_OWNER);

        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(ZERO_ADDRESS);
        assertEq(ownerTwoSteps.pendingOwner(), ZERO_ADDRESS);
    }

    function test_RevertWhen_TransferOwnership_CalledByNonOwner() public {
        vm.expectRevert(OwnerTwoStepsFacet.OwnerUnauthorizedAccount.selector);
        vm.prank(ALICE);
        ownerTwoSteps.transferOwnership(ALICE);
    }

    function test_RevertWhen_TransferOwnership_CalledByPendingOwner() public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(NEW_OWNER);

        vm.expectRevert(OwnerTwoStepsFacet.OwnerUnauthorizedAccount.selector);
        vm.prank(NEW_OWNER);
        ownerTwoSteps.transferOwnership(ALICE);
    }

    // ============================================
    // Accept Ownership Tests
    // ============================================

    function test_AcceptOwnership_CompletesTransfer() public {
        // Initiate transfer
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(NEW_OWNER);

        // Accept ownership
        vm.prank(NEW_OWNER);
        ownerTwoSteps.acceptOwnership();

        // Verify ownership transferred
        assertEq(ownerTwoSteps.owner(), NEW_OWNER);
        assertEq(ownerTwoSteps.pendingOwner(), ZERO_ADDRESS);
    }

    function test_AcceptOwnership_EmitsOwnershipTransferredEvent() public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(NEW_OWNER);

        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(INITIAL_OWNER, NEW_OWNER);

        vm.prank(NEW_OWNER);
        ownerTwoSteps.acceptOwnership();
    }

    function test_AcceptOwnership_ClearsPendingOwner() public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(NEW_OWNER);

        vm.prank(NEW_OWNER);
        ownerTwoSteps.acceptOwnership();

        assertEq(ownerTwoSteps.pendingOwner(), ZERO_ADDRESS);
    }

    function test_RevertWhen_AcceptOwnership_CalledByNonPendingOwner() public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(NEW_OWNER);

        vm.expectRevert(OwnerTwoStepsFacet.OwnerUnauthorizedAccount.selector);
        vm.prank(ALICE);
        ownerTwoSteps.acceptOwnership();
    }

    function test_RevertWhen_AcceptOwnership_CalledByCurrentOwner() public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(NEW_OWNER);

        vm.expectRevert(OwnerTwoStepsFacet.OwnerUnauthorizedAccount.selector);
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.acceptOwnership();
    }

    function test_RevertWhen_AcceptOwnership_NoPendingOwner() public {
        vm.expectRevert(OwnerTwoStepsFacet.OwnerUnauthorizedAccount.selector);
        vm.prank(ALICE);
        ownerTwoSteps.acceptOwnership();
    }

    // ============================================
    // Renounce Ownership Tests (via Zero Address)
    // ============================================

    function test_RenounceOwnership_TwoStep() public {
        // Initiate renouncement
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(ZERO_ADDRESS);

        // Owner should still be the same
        assertEq(ownerTwoSteps.owner(), INITIAL_OWNER);
        assertEq(ownerTwoSteps.pendingOwner(), ZERO_ADDRESS);

        // Note: Zero address cannot accept ownership (no private key)
        // This effectively cancels the renouncement unless there's another mechanism
    }

    // ============================================
    // Sequential Transfer Tests
    // ============================================

    function test_SequentialTransfers() public {
        // First transfer
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(ALICE);

        vm.prank(ALICE);
        ownerTwoSteps.acceptOwnership();
        assertEq(ownerTwoSteps.owner(), ALICE);

        // Second transfer
        vm.prank(ALICE);
        ownerTwoSteps.transferOwnership(BOB);

        vm.prank(BOB);
        ownerTwoSteps.acceptOwnership();
        assertEq(ownerTwoSteps.owner(), BOB);

        // Third transfer back to initial
        vm.prank(BOB);
        ownerTwoSteps.transferOwnership(INITIAL_OWNER);

        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.acceptOwnership();
        assertEq(ownerTwoSteps.owner(), INITIAL_OWNER);
    }

    function test_TransferToSelf() public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(INITIAL_OWNER);
        assertEq(ownerTwoSteps.pendingOwner(), INITIAL_OWNER);

        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.acceptOwnership();
        assertEq(ownerTwoSteps.owner(), INITIAL_OWNER);
    }

    // ============================================
    // Edge Cases
    // ============================================

    function test_MultiplePendingChanges_OnlyLastOneMatters() public {
        vm.startPrank(INITIAL_OWNER);

        ownerTwoSteps.transferOwnership(ALICE);
        assertEq(ownerTwoSteps.pendingOwner(), ALICE);

        ownerTwoSteps.transferOwnership(BOB);
        assertEq(ownerTwoSteps.pendingOwner(), BOB);

        ownerTwoSteps.transferOwnership(NEW_OWNER);
        assertEq(ownerTwoSteps.pendingOwner(), NEW_OWNER);

        vm.stopPrank();

        // Alice and Bob cannot accept
        vm.prank(ALICE);
        vm.expectRevert(OwnerTwoStepsFacet.OwnerUnauthorizedAccount.selector);
        ownerTwoSteps.acceptOwnership();

        vm.prank(BOB);
        vm.expectRevert(OwnerTwoStepsFacet.OwnerUnauthorizedAccount.selector);
        ownerTwoSteps.acceptOwnership();

        // Only NEW_OWNER can accept
        vm.prank(NEW_OWNER);
        ownerTwoSteps.acceptOwnership();
        assertEq(ownerTwoSteps.owner(), NEW_OWNER);
    }

    // ============================================
    // Fuzz Tests
    // ============================================

    function test_Fuzz_TransferOwnership(address newOwner) public {
        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(newOwner);

        assertEq(ownerTwoSteps.owner(), INITIAL_OWNER);
        assertEq(ownerTwoSteps.pendingOwner(), newOwner);
    }

    function test_Fuzz_AcceptOwnership(address newOwner) public {
        vm.assume(newOwner != address(0)); // Zero address can't execute transactions

        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(newOwner);

        vm.prank(newOwner);
        ownerTwoSteps.acceptOwnership();

        assertEq(ownerTwoSteps.owner(), newOwner);
        assertEq(ownerTwoSteps.pendingOwner(), ZERO_ADDRESS);
    }

    function test_Fuzz_RevertWhen_UnauthorizedTransfer(address caller, address target) public {
        vm.assume(caller != INITIAL_OWNER);

        vm.prank(caller);
        vm.expectRevert(OwnerTwoStepsFacet.OwnerUnauthorizedAccount.selector);
        ownerTwoSteps.transferOwnership(target);
    }

    function test_Fuzz_RevertWhen_UnauthorizedAccept(address caller) public {
        vm.assume(caller != NEW_OWNER);

        vm.prank(INITIAL_OWNER);
        ownerTwoSteps.transferOwnership(NEW_OWNER);

        vm.prank(caller);
        vm.expectRevert(OwnerTwoStepsFacet.OwnerUnauthorizedAccount.selector);
        ownerTwoSteps.acceptOwnership();
    }
}

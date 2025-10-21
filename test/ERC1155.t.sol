// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC1155Facet} from "../src/ERC1155/ERC1155/ERC1155Facet.sol";
import {LibERC1155} from "../src/ERC1155/ERC1155/libraries/LibERC1155.sol";

/// @title MockERC1155Facet
/// @notice Mock contract that properly initializes ERC1155 storage for testing
contract MockERC1155Facet is ERC1155Facet {
    constructor() {
        // Initialize storage directly
        LibERC1155.ERC1155Storage storage s = LibERC1155.getStorage();
        s.uri = "https://api.example.com/metadata/{id}.json";
    }
}

/// @title MockERC1155Receiver
/// @notice Mock contract that implements IERC1155Receiver for testing safe transfers
contract MockERC1155Receiver {
    bytes4 public constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 public constant ERC1155_BATCH_RECEIVED = 0xbc197c81;
    
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155_RECEIVED;
    }
    
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155_BATCH_RECEIVED;
    }
}

/// @title ERC1155Test
/// @notice Comprehensive tests for ERC-1155 Multi-Token Standard
contract ERC1155Test is Test {
    MockERC1155Facet public erc1155;
    MockERC1155Receiver public receiver;
    
    // Test accounts
    address public owner;
    address public spender;
    address public other;
    
    // Test token IDs and amounts
    uint256 public constant TOKEN_ID_1 = 1;
    uint256 public constant TOKEN_ID_2 = 2;
    uint256 public constant TOKEN_ID_3 = 3;
    uint256 public constant AMOUNT_100 = 100;
    uint256 public constant AMOUNT_50 = 50;
    uint256 public constant AMOUNT_25 = 25;
    
    function setUp() public {
        // Create test accounts
        owner = makeAddr("owner");
        spender = makeAddr("spender");
        other = makeAddr("other");
        
        // Deploy contracts
        erc1155 = new MockERC1155Facet();
        receiver = new MockERC1155Receiver();
        
        // Mint initial tokens to owner
        erc1155.mint(owner, TOKEN_ID_1, AMOUNT_100, "");
        erc1155.mint(owner, TOKEN_ID_2, AMOUNT_50, "");
        erc1155.mint(owner, TOKEN_ID_3, AMOUNT_25, "");
    }
    
    // ============ View Function Tests ============
    
    function test_BalanceOf_SingleToken() public {
        vm.prank(owner);
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_1), AMOUNT_100);
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_2), AMOUNT_50);
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_3), AMOUNT_25);
    }
    
    function test_BalanceOf_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(ERC1155Facet.ERC1155InvalidOwner.selector, address(0)));
        erc1155.balanceOf(address(0), TOKEN_ID_1);
    }
    
    function test_BalanceOfBatch_MultipleTokens() public {
        address[] memory accounts = new address[](2);
        accounts[0] = owner;
        accounts[1] = spender;
        
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory balances = erc1155.balanceOfBatch(accounts, ids);
        assertEq(balances[0], AMOUNT_100);
        assertEq(balances[1], 0); // spender has no tokens
    }
    
    function test_BalanceOfBatch_InvalidArrayLength() public {
        address[] memory accounts = new address[](2);
        accounts[0] = owner;
        accounts[1] = spender;
        
        uint256[] memory ids = new uint256[](3);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        ids[2] = TOKEN_ID_3;
        
        vm.expectRevert(abi.encodeWithSelector(ERC1155Facet.ERC1155InvalidArrayLength.selector, 2, 3));
        erc1155.balanceOfBatch(accounts, ids);
    }
    
    function test_IsApprovedForAll_DefaultState() public {
        assertFalse(erc1155.isApprovedForAll(owner, spender));
    }
    
    function test_URI_ReturnsCorrectFormat() public {
        string memory tokenURI = erc1155.uri(TOKEN_ID_1);
        assertEq(tokenURI, "https://api.example.com/metadata/1.json");
    }
    
    // ============ Approval Tests ============
    
    function test_SetApprovalForAll_ApprovesOperator() public {
        vm.prank(owner);
        erc1155.setApprovalForAll(spender, true);
        
        assertTrue(erc1155.isApprovedForAll(owner, spender));
    }
    
    function test_SetApprovalForAll_RevokesApproval() public {
        vm.startPrank(owner);
        erc1155.setApprovalForAll(spender, true);
        assertTrue(erc1155.isApprovedForAll(owner, spender));
        
        erc1155.setApprovalForAll(spender, false);
        assertFalse(erc1155.isApprovedForAll(owner, spender));
        vm.stopPrank();
    }
    
    function test_SetApprovalForAll_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(ERC1155Facet.ERC1155InvalidOperator.selector, address(0)));
        erc1155.setApprovalForAll(address(0), true);
    }
    
    // ============ Transfer Tests ============
    
    function test_SafeTransferFrom_OwnerToOther() public {
        vm.prank(owner);
        erc1155.safeTransferFrom(owner, other, TOKEN_ID_1, AMOUNT_50, "");
        
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_1), AMOUNT_50);
        assertEq(erc1155.balanceOf(other, TOKEN_ID_1), AMOUNT_50);
    }
    
    function test_SafeTransferFrom_ApprovedOperator() public {
        vm.startPrank(owner);
        erc1155.setApprovalForAll(spender, true);
        vm.stopPrank();
        
        vm.prank(spender);
        erc1155.safeTransferFrom(owner, other, TOKEN_ID_1, AMOUNT_50, "");
        
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_1), AMOUNT_50);
        assertEq(erc1155.balanceOf(other, TOKEN_ID_1), AMOUNT_50);
    }
    
    function test_SafeTransferFrom_InsufficientBalance() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(LibERC1155.ERC1155InsufficientBalance.selector, owner, AMOUNT_100, AMOUNT_100 + 1));
        erc1155.safeTransferFrom(owner, other, TOKEN_ID_1, AMOUNT_100 + 1, "");
    }
    
    function test_SafeTransferFrom_UnauthorizedOperator() public {
        vm.prank(spender);
        vm.expectRevert(abi.encodeWithSelector(LibERC1155.ERC1155InsufficientAllowance.selector, spender, 0, AMOUNT_50));
        erc1155.safeTransferFrom(owner, other, TOKEN_ID_1, AMOUNT_50, "");
    }
    
    function test_SafeTransferFrom_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(LibERC1155.ERC1155InvalidReceiver.selector, address(0)));
        erc1155.safeTransferFrom(owner, address(0), TOKEN_ID_1, AMOUNT_50, "");
    }
    
    function test_SafeTransferFrom_ToContract() public {
        vm.prank(owner);
        erc1155.safeTransferFrom(owner, address(receiver), TOKEN_ID_1, AMOUNT_50, "");
        
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_1), AMOUNT_50);
        assertEq(erc1155.balanceOf(address(receiver), TOKEN_ID_1), AMOUNT_50);
    }
    
    // ============ Batch Transfer Tests ============
    
    function test_SafeBatchTransferFrom_MultipleTokens() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = AMOUNT_50;
        amounts[1] = AMOUNT_25;
        
        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, other, ids, amounts, "");
        
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_1), AMOUNT_50);
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_2), AMOUNT_25);
        assertEq(erc1155.balanceOf(other, TOKEN_ID_1), AMOUNT_50);
        assertEq(erc1155.balanceOf(other, TOKEN_ID_2), AMOUNT_25);
    }
    
    function test_SafeBatchTransferFrom_InvalidArrayLength() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = AMOUNT_50;
        amounts[1] = AMOUNT_25;
        amounts[2] = AMOUNT_25;
        
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(LibERC1155.ERC1155InvalidArrayLength.selector, 2, 3));
        erc1155.safeBatchTransferFrom(owner, other, ids, amounts, "");
    }
    
    function test_SafeBatchTransferFrom_ToContract() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = AMOUNT_50;
        amounts[1] = AMOUNT_25;
        
        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, address(receiver), ids, amounts, "");
        
        assertEq(erc1155.balanceOf(address(receiver), TOKEN_ID_1), AMOUNT_50);
        assertEq(erc1155.balanceOf(address(receiver), TOKEN_ID_2), AMOUNT_25);
    }
    
    // ============ Mint Tests ============
    
    function test_Mint_SingleToken() public {
        erc1155.mint(other, TOKEN_ID_1, AMOUNT_50, "");
        
        assertEq(erc1155.balanceOf(other, TOKEN_ID_1), AMOUNT_50);
    }
    
    function test_Mint_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(LibERC1155.ERC1155InvalidReceiver.selector, address(0)));
        erc1155.mint(address(0), TOKEN_ID_1, AMOUNT_50, "");
    }
    
    function test_MintBatch_MultipleTokens() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = AMOUNT_50;
        amounts[1] = AMOUNT_25;
        
        erc1155.mintBatch(other, ids, amounts, "");
        
        assertEq(erc1155.balanceOf(other, TOKEN_ID_1), AMOUNT_50);
        assertEq(erc1155.balanceOf(other, TOKEN_ID_2), AMOUNT_25);
    }
    
    function test_MintBatch_InvalidArrayLength() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = AMOUNT_50;
        amounts[1] = AMOUNT_25;
        amounts[2] = AMOUNT_25;
        
        vm.expectRevert(abi.encodeWithSelector(LibERC1155.ERC1155InvalidArrayLength.selector, 2, 3));
        erc1155.mintBatch(other, ids, amounts, "");
    }
    
    // ============ Burn Tests ============
    
    function test_Burn_SingleToken() public {
        erc1155.burn(owner, TOKEN_ID_1, AMOUNT_50);
        
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_1), AMOUNT_50);
    }
    
    function test_Burn_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(LibERC1155.ERC1155InvalidSender.selector, address(0)));
        erc1155.burn(address(0), TOKEN_ID_1, AMOUNT_50);
    }
    
    function test_Burn_InsufficientBalance() public {
        vm.expectRevert(abi.encodeWithSelector(LibERC1155.ERC1155InsufficientBalance.selector, owner, AMOUNT_100, AMOUNT_100 + 1));
        erc1155.burn(owner, TOKEN_ID_1, AMOUNT_100 + 1);
    }
    
    function test_BurnBatch_MultipleTokens() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = AMOUNT_50;
        amounts[1] = AMOUNT_25;
        
        erc1155.burnBatch(owner, ids, amounts);
        
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_1), AMOUNT_50);
        assertEq(erc1155.balanceOf(owner, TOKEN_ID_2), AMOUNT_25);
    }
    
    function test_BurnBatch_InvalidArrayLength() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = AMOUNT_50;
        amounts[1] = AMOUNT_25;
        amounts[2] = AMOUNT_25;
        
        vm.expectRevert(abi.encodeWithSelector(LibERC1155.ERC1155InvalidArrayLength.selector, 2, 3));
        erc1155.burnBatch(owner, ids, amounts);
    }
    
    // ============ URI Tests ============
    
    function test_SetURI_UpdatesURI() public {
        string memory newURI = "https://newapi.example.com/metadata/{id}.json";
        erc1155.setURI(newURI);
        
        string memory tokenURI = erc1155.uri(TOKEN_ID_1);
        assertEq(tokenURI, "https://newapi.example.com/metadata/1.json");
    }
    
    // ============ Event Tests ============
    
    function test_TransferSingle_EmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit LibERC1155.TransferSingle(owner, owner, other, TOKEN_ID_1, AMOUNT_50);
        
        vm.prank(owner);
        erc1155.safeTransferFrom(owner, other, TOKEN_ID_1, AMOUNT_50, "");
    }
    
    function test_TransferBatch_EmitsEvent() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = AMOUNT_50;
        amounts[1] = AMOUNT_25;
        
        vm.expectEmit(true, true, true, true);
        emit LibERC1155.TransferBatch(owner, owner, other, ids, amounts);
        
        vm.prank(owner);
        erc1155.safeBatchTransferFrom(owner, other, ids, amounts, "");
    }
    
    function test_ApprovalForAll_EmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit LibERC1155.ApprovalForAll(owner, spender, true);
        
        vm.prank(owner);
        erc1155.setApprovalForAll(spender, true);
    }
    
    function test_URI_EmitsEvent() public {
        string memory newURI = "https://newapi.example.com/metadata/{id}.json";
        
        vm.expectEmit(false, true, false, true);
        emit LibERC1155.URI(newURI, 0);
        
        erc1155.setURI(newURI);
    }
}

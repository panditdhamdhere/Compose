// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC20Facet} from "../src/ERC20/ERC20/ERC20Facet.sol";

contract CounterTest is Test {
    ERC20Facet public erc20;

    function setUp() public {
        erc20 = new ERC20Facet();
        //erc20.setNumber(0);
    }

    function test_Increment() public {
        //counter.increment();
        // assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        // counter.setNumber(x);
        // assertEq(counter.number(), x);
    }
}

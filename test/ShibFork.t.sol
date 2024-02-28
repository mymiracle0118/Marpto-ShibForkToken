// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console, console2} from "forge-std/Test.sol";
import {ShibFork} from "src/ShibFork.sol";

contract ShibForkTest is Test {
    ShibFork public shib;
    address tokenOnwer = address(1);

    function setUp() public {
        shib = new ShibFork(tokenOnwer);
    }

    function test_Increment() public {
    }

    function testFuzz_SetNumber(uint256 x) public {
    }
}

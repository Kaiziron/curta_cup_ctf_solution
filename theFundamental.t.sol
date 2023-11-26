// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/theFundamental.sol";

contract theFundamentalTest is Test {
    Challenge public challenge;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 18597420);
        challenge = Challenge(0x12B9e49E4d6241CB005cC70CaDeEEb3b10d11A53);
    }

    function testSolve() public {
        // set mode to maintenance
        challenge.setSlot(uint256(keccak256(abi.encode(address(this), uint256(1)))), 2);
        challenge.applySlot();
        // set serv helper function jump destination
        challenge.setSlot(uint256(keccak256(abi.encode(address(this), uint256(0)))), 0x203);
        challenge.applySlot();
        // after jumping to 0x203 it will jump to the first arg in 0x284, so just jump to 0x295 to continue
        // and it's using second arg as the seed for generate
        challenge.solve(0x295, uint256(uint160(address(this))));
        assertTrue(challenge.verify(challenge.generate(address(this)), uint256(uint160(address(this)))));
    }
}


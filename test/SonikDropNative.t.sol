// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {SonikDropNative} from "../src/facets/nativefacets/SonikDropNative.sol";
import {GetProof} from "./helpers/GetProof.sol";

// TODO test for nft  requirment

contract SonikDropNativeTest is GetProof {
    SonikDropNative sonikDropNative;

    address user1;
    uint256 keyUser1;
    address user2;
    uint256 keyUser2;
    address badUser;
    uint256 keybadUser;
    address owner;
    bytes32 merkleRoot =
        0x95d6e8d85e932a1fb33f70a0b15e42ab823ffc4e34a7e53c602529c2478cd823;
    bytes32 hash = keccak256("claimed sonik droppppppppppp");

    function setUp() public {
        owner = msg.sender;
        sonikDropNative = new SonikDropNative(
            msg.sender,
            merkleRoot,
            "test ",
            address(0),
            0,
            10,
            25 ether
        );
        emit log_address(owner);
        vm.deal(address(sonikDropNative), 25 ether);
        (user1, keyUser1) = makeAddrAndKey("user1");
        (user2, keyUser2) = makeAddrAndKey("user2");
        (badUser, keybadUser) = makeAddrAndKey("badUser");
    }

    //// public/ external  view functions

    function test_getContractBalance() public {
        assertEq(sonikDropNative.getContractBalance(), 25 ether);
    }

    function test_hasAidropTimeEnded() public {
        //  the airdrop is not time locked by default
        assertEq(sonikDropNative.hasAirdropTimeEnded(), false);
    }

    function test_hasAidropTimeEndedWithTimeLock() public {
        vm.prank(owner);
        sonikDropNative.updateClaimTime(1 days);
        assertEq(sonikDropNative.hasAirdropTimeEnded(), false);
    }

    function test_hasAidropTimeEndedWithTimeLockTrue() public {
        vm.prank(owner);
        sonikDropNative.updateClaimTime(1 days);

        vm.warp(block.timestamp + 2 days);
        assertEq(sonikDropNative.hasAirdropTimeEnded(), true);
    }

    function test_checkEligibility() public {
        bytes32[] memory proof = getProof(user1);
        vm.prank(user1);
        assertEq(sonikDropNative.checkEligibility(10 ether, proof), true);
    }

    function test_checkEligibility_wrong_value() public {
        bytes32[] memory proof = getProof(user1);
        vm.prank(user1);
        assertEq(sonikDropNative.checkEligibility(69 ether, proof), false);
    }

    function test_checkEligibility_wrong_proof() public {
        bytes32[] memory proof = getProof(user2);

        // using user 1 proof to check user2 eligitbity
        vm.prank(user1);
        assertEq(sonikDropNative.checkEligibility(10 ether, proof), false);
    }

    //// Owned   functions

    function test_updateClaimTime() public {
        vm.prank(owner);
        sonikDropNative.updateClaimTime(1 days);
        assertEq(sonikDropNative.isTimeLocked(), true);
        assertEq(sonikDropNative.airdropEndTime(), block.timestamp + 1 days);
    }

    function test_updateClaimTime_notOwner() public {
        vm.startPrank(user1);

        vm.expectRevert(abi.encodeWithSignature("UnAuthorizedFunctionCall()"));

        sonikDropNative.updateClaimTime(1 days);
        assertEq(sonikDropNative.isTimeLocked(), false);

        vm.stopPrank();
    }

    function test_claimAirdrop() public {
        bytes32[] memory proof = getProof(user1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(keyUser1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(user1);
        sonikDropNative.claimAirdrop(10e18, proof, hash, signature);
        assertEq(user1.balance, 10e18);
    }

    function test_claimAirdrop_duplicateClaim() external {
        bytes32[] memory proof = getProof(user1);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(keyUser1, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // First claim
        vm.startPrank(user1);
        sonikDropNative.claimAirdrop(10e18, proof, hash, signature);

        // Attempt to claim again
        vm.expectRevert(abi.encodeWithSignature("InvalidClaim()"));
        sonikDropNative.claimAirdrop(10e18, proof, hash, signature);
        vm.stopPrank();
    }

    function test_ClaimAirdrop_InvalidProof() external {
        // Generating an invalid proof for user2

        vm.startPrank(user2);
        bytes32[] memory invalidProof = new bytes32[](0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(keyUser2, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSignature("InvalidClaim()"));
        sonikDropNative.claimAirdrop(10e18, invalidProof, hash, signature);
        vm.stopPrank();
    }

    function test_ClaimAirdrop_InsufficientFunds() external {
        test_claimAirdrop();

        // Attempt to claim more than the available balance
        vm.expectRevert(
            abi.encodeWithSignature("InsufficientContractBalance()")
        );
        vm.startPrank(user2);
        bytes32[] memory proof = getProof(user2);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(keyUser2, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        sonikDropNative.claimAirdrop(20e18, proof, hash, signature);
        vm.stopPrank();
    }

    function test_ClaimAirdrop_TimeLock() external {
        // Set a claim time to test time-lock functionality
        vm.prank(owner);
        sonikDropNative.updateClaimTime(1 days);

        vm.startPrank(user2);
        bytes32[] memory proof = getProof(user2);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(keyUser2, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Fast forward time to simulate claim after time-lock
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(abi.encodeWithSignature("AirdropClaimEnded()"));

        sonikDropNative.claimAirdrop(20e18, proof, hash, signature);
        vm.stopPrank();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {AirdropFactoryFacet} from "../src/facets/erc20facets/FactoryFacet.sol";
import {PoapFactoryFacet} from "../src/facets/erc721facets/PoapFactoryFacet.sol";
import {FactoryFacetNative} from "../src/facets/nativefacets/FactoryFacetNative.sol";

import "forge-std/Script.sol";

contract SoniKDeployer is Script {
    // Facets

    AirdropFactoryFacet airdropFactoryFacet;
    PoapFactoryFacet poapFactoryFacet;
    FactoryFacetNative factoryFacetNative;

    bytes32 constant SALT_AIRDROP = keccak256("SonikDropAirdropFactoryFacet");
    bytes32 constant SALT_POAP = keccak256("SonikDropPoapFactoryFacet");
    bytes32 constant SALT_NATIVE = keccak256("SonikDropFactoryFacetNative");

    function run() external {
        vm.startBroadcast();

        // Deploy facets
        deployFacets();

        vm.stopBroadcast();
    }

    function deployFacets() internal {
        airdropFactoryFacet = new AirdropFactoryFacet{salt: SALT_AIRDROP}();
        console.log("AirdropFactoryFacet deployed at:", address(airdropFactoryFacet));

        poapFactoryFacet = new PoapFactoryFacet{salt: SALT_POAP}();
        console.log("PoapFactoryFacet deployed at:", address(poapFactoryFacet));
        factoryFacetNative = new FactoryFacetNative{salt: SALT_NATIVE}();
        console.log("factoryFacetNative deployed at:", address(factoryFacetNative));
    }
}

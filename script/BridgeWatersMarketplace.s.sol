// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {BridgeWatersMarketplace} from "../src/BridgeWatersMarketplace.sol";

contract CounterScript is Script {
    function setUp() public {}

    BridgeWatersMarketplace bridgeWaters;

    function run() public {
        vm.broadcast();
        bridgeWaters = new BridgeWatersMarketplace();
    }
}

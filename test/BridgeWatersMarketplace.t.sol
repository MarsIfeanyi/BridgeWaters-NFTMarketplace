// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BridgeWatersMarketplace} from "../src/BridgeWatersMarketplace.sol";

contract BridgeWatersMarketplaceTest is Test {
    BridgeWatersMarketplace public bridgeWaters;

    function setUp() public {
        bridgeWaters = new BridgeWatersMarketplace();
    }

    function test_CreateOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _deadline,
        bytes memory _signature
    ) public {}

    function test_BuyOrder(uint256 _orderId) public {}
}

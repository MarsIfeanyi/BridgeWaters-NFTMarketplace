// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BridgeWatersMarketplace} from "../src/BridgeWatersMarketplace.sol";

contract BridgeWatersMarketplaceTest is Test {
    BridgeWatersMarketplace public bridgeWaters;

    address tokenAddress = 0x06448574948e481E395C702B65e13bB23C2f5aeF;
    uint256 tokenId;
    uint256 price = 0.05 ether;
    uint256 deadline = block.timestamp + 1 days;
    bytes signature;
    uint256 itemsCounter;

    function setUp() public {
        bridgeWaters = new BridgeWatersMarketplace();
    }

    function test_ListItem(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _deadline,
        bytes memory _signature
    ) public {
        BridgeWatersMarketplace.ItemInfo storage itemInfo = bridgeWaters
            .listedItems[itemsCounter];

        assertEq(bridgeWaters.ItemInfo.tokenAddress(), _tokenAddress);
    }

    function test_BuyItem(uint256 _orderId) public {}
}

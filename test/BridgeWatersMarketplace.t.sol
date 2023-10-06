// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BridgeWatersMarketplace, ListingInfo} from "../src/BridgeWatersMarketplace.sol";

contract BridgeWatersMarketplaceTest is Test {
    BridgeWatersMarketplace public bridgeWaters;

    address tokenAddress;
    uint256 tokenId;
    uint256 price;
    uint256 deadline;
    bytes signature;
    uint256 itemsCounter;

    function setUp() public {
        bridgeWaters = new BridgeWatersMarketplace();

        tokenAddress = 0x06448574948e481E395C702B65e13bB23C2f5aeF;
        tokenId = 10;
        price = 0.05 ether;
        deadline = block.timestamp + 1 days;
    }

    function test_ListItem(
        address _token,
        uint256 _tokenId,
        uint256 _price,
        uint256 _deadline,
        bytes memory _signature,
        uint _listingId
    ) public {
        ListingInfo memory listingInfo = bridgeWaters.getListing(_listingId);

        assertEq(listingInfo.token, _token);
        assertEq(listingInfo.tokenId, _tokenId);
        assertEq(listingInfo.price, _price);
        assertEq(listingInfo.deadline, _deadline);
        assertEq(listingInfo.signature, _signature);
    }

    function test_BuyItem(uint256 _orderId) public {}
}

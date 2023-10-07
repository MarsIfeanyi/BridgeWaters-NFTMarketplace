// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BridgeWatersMarketplace} from "../src/BridgeWatersMarketplace.sol";
import "../src/ERC721Mock.sol";
import "./Helpers.sol";

contract BridgeWatersMarketplaceTest is Helpers {
    BridgeWatersMarketplace public bridgeWaters;
    BridgeWaterNFT public bridgeWaterNFT;

    uint256 currentListingId;

    address creator1;
    address creator2;
    address spender;

    uint256 privateKey1;
    uint256 privateKey2;
    uint256 privateKey3;

    // getting and declaring the struct state variable
    BridgeWatersMarketplace.ListingInfo listingInfo;

    // BridgeWatersMarketplace.listingsInfo[currentListingId];

    function setUp() public {
        bridgeWaters = new BridgeWatersMarketplace();

        bridgeWaterNFT = new BridgeWaterNFT();

        // Calling the helper function
        (creator1, privateKey1) = mkaddr("CREATOR1");
        (creator2, privateKey2) = mkaddr("CREATOR2");
        (spender, privateKey3) = mkaddr("SPENDER");

        // Accessing the data is the struct and saving it to the state variable
        // _listingInfo = _BridgeWatersMarketplace._ListingInfo({
        //     token: address(bridgeWaterNFT),
        //     tokenId: 1,
        //     price: 1 ether,
        //     signature: bytes(""),
        //     deadline: 0,
        //     seller: address(0),
        //     isActive: false
        // });

        listingInfo.token = address(bridgeWaterNFT);
        listingInfo.tokenId = 1;
        listingInfo.price = 1 ether;
        listingInfo.signature = bytes("");
        listingInfo.deadline = 0;
        listingInfo.seller = address(0);
        listingInfo.isActive = false;

        bridgeWaterNFT.mint(creator1, 1);
    }

    function _createListing() internal returns (uint256 _listingId) {
        _listingId = bridgeWaters.createListing(
            listingInfo.token,
            listingInfo.tokenId,
            listingInfo.price,
            listingInfo.signature,
            listingInfo.deadline,
            listingInfo.seller
        );
    }

    function testCreateListing_OnlyOwnerCanCreateListing() public {
        listingInfo.seller = spender;
        switchSigner(spender);

        vm.expectRevert(BridgeWatersMarketplace.NotOwner.selector);
        _createListing();
    }

    function testCreateListing_NotApprovedNFTForUser() public {
        switchSigner(creator1);

        vm.expectRevert(BridgeWatersMarketplace.NotApproved.selector);
        _createListing();
    }

    function testCreateListing_MinimumPriceTooLow() public {
        switchSigner(creator1);

        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        listingInfo.price = 0;

        vm.expectRevert(BridgeWatersMarketplace.MinPriceTooLow.selector);
        _createListing();
    }

    function testCreateListing_DeadlineTooSoon() public {
        switchSigner(creator1);

        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        vm.expectRevert(BridgeWatersMarketplace.DeadlineTooSoon.selector);
        _createListing();
    }

    function testCreateListing_MinimumDurationNotMet() public {
        switchSigner(creator1);

        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        listingInfo.deadline = uint88(block.timestamp + 30 minutes);

        vm.expectRevert(BridgeWatersMarketplace.MinDurationNotMet.selector);
        _createListing();
    }

    function testCreateListing_InValidSignature() public {
        switchSigner(creator1);

        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        listingInfo.deadline = uint88(block.timestamp + 3 hours);

        listingInfo.signature = constructSig(
            listingInfo.token,
            listingInfo.tokenId,
            listingInfo.price,
            listingInfo.deadline,
            listingInfo.seller,
            privateKey2
        );

        vm.expectRevert(BridgeWatersMarketplace.InValidSignature.selector);
        _createListing();
    }

    function testCreateListing() public {
        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        _createListing();

        assertEq(listingInfo.token, address(bridgeWaterNFT));
        assertEq(listingInfo.tokenId, 1);
        assertEq(listingInfo.price, 1 ether);
        assertEq(listingInfo.signature, bytes(""));
        assertEq(listingInfo.deadline, 0);
        assertEq(listingInfo.seller, address(0));
        assertEq(listingInfo.isActive, false);
    }

    // executeListing

    function _executeListing() internal {
        bridgeWaters.executeListing(4);
    }

    function testExecuteListing_ListingDoesNotExist() public {
        switchSigner(creator1);

        vm.expectRevert(BridgeWatersMarketplace.ListingDoesNotExist.selector);

        _executeListing();
    }
}

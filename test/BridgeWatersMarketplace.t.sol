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

    struct ListingInfo {
        address token;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        // slot packing... Slot 4
        uint256 deadline;
        address seller;
        bool isActive;
    }

    // getting and declaring the struct state variable
    BridgeWatersMarketplace.ListingInfo listingInfo;

    // BridgeWatersMarketplace.listingsInfo[currentListingId];

    event ListingCreated(uint256 indexed listingId);
    event ListingExecuted(uint256 indexed listingId, ListingInfo);
    event ListingEdited(uint256 indexed listingId, ListingInfo);

    function setUp() public {
        bridgeWaters = new BridgeWatersMarketplace();

        bridgeWaterNFT = new BridgeWaterNFT();

        // Calling the helper function
        (creator1, privateKey1) = mkaddr("CREATOR1");
        (creator2, privateKey2) = mkaddr("CREATOR2");
        (spender, privateKey3) = mkaddr("SPENDER");

        bridgeWaterNFT.mint(creator1, 2);

        listingInfo.token = address(bridgeWaterNFT);
        listingInfo.tokenId = 2;
        listingInfo.price = 2 ether;
        listingInfo.deadline = 2 days;
        listingInfo.seller;
        listingInfo.isActive = true;
        listingInfo.signature;
    }

    function testCreateListing() public {
        // vm.startPrank(creator1);
        switchSigner(creator1);
        //bridgeWaterNFT.mint(creator1, 2);
        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        bytes memory _signature = constructSig(
            address(bridgeWaterNFT),
            2,
            2 ether,
            2 days,
            creator1,
            privateKey1
        );
        listingInfo.signature = _signature;
        listingInfo.seller = creator1;
        listingInfo.tokenId = 2;

        currentListingId = bridgeWaters.createListing(
            listingInfo.token,
            listingInfo.tokenId,
            listingInfo.price,
            listingInfo.signature,
            listingInfo.deadline,
            listingInfo.seller,
            listingInfo.isActive = true
        );

        assertEq(listingInfo.token, address(bridgeWaterNFT));
        assertEq(listingInfo.tokenId, 2);
        assertEq(listingInfo.price, 2 ether);
        assertEq(listingInfo.signature, _signature);
        assertEq(listingInfo.deadline, 2 days);
        assertEq(listingInfo.seller, creator1);
        assertEq(listingInfo.isActive, true);
    }

    function _createListing() internal returns (uint256 _listingId) {
        // listingInfo.seller = creator1;
        _listingId = bridgeWaters.createListing(
            listingInfo.token,
            listingInfo.tokenId,
            listingInfo.price,
            listingInfo.signature,
            listingInfo.deadline,
            listingInfo.seller,
            listingInfo.isActive
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
        //bridgeWaterNFT.mint(creator1, 2);
        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        bytes memory _signature = constructSig(
            address(bridgeWaterNFT),
            2,
            1 ether,
            2 days,
            creator1,
            privateKey1
        );
        // vm.warp(2 days);
        listingInfo.signature = _signature;
        listingInfo.seller = creator1;
        listingInfo.tokenId = 2;
        listingInfo.deadline = 0 minutes;

        vm.expectRevert(BridgeWatersMarketplace.DeadlineTooSoon.selector);
        bridgeWaters.createListing(
            listingInfo.token,
            listingInfo.tokenId,
            listingInfo.price,
            listingInfo.signature,
            listingInfo.deadline,
            listingInfo.seller,
            listingInfo.isActive
        );
    }

    function testCreateListing_MinimumDurationNotMet() public {
        switchSigner(creator1);

        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        listingInfo.deadline = 30 minutes;

        vm.expectRevert(BridgeWatersMarketplace.MinDurationNotMet.selector);
        _createListing();
    }

    function testCreateListing_InValidSignature() public {
        switchSigner(creator1);

        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        listingInfo.deadline = uint88(block.timestamp + 3 hours);
        listingInfo.seller = creator1;
        bytes memory _signature = constructSig(
            address(bridgeWaterNFT),
            2,
            3 ether,
            3 days,
            creator1,
            privateKey1
        );
        listingInfo.signature = _signature;
        vm.expectRevert(BridgeWatersMarketplace.InValidSignature.selector);
        bridgeWaters.createListing(
            listingInfo.token,
            listingInfo.tokenId,
            listingInfo.price,
            listingInfo.signature,
            listingInfo.deadline,
            listingInfo.seller,
            listingInfo.isActive
        );
    }

    // function _testCreateListing_Emitevent_ListingCreated() public {
    //  switchSigner(creator1);

    //     vm.expectEmit();

    //     emit ListingCreated(currentListingId);

    //     _createListing();
    // }

    // executeListing

    function _buyListing() internal {
        switchSigner(creator1);
        bridgeWaters.buyListing(currentListingId);
    }

    function testBuyListing_ListingDoesNotExist() public {
        testCreateListing();

        vm.expectRevert(BridgeWatersMarketplace.ListingDoesNotExist.selector);

        _buyListing();
    }

    function testBuyListing_ListingExpired() public {
        testCreateListing();

        vm.warp(1641070800);

        vm.expectRevert(BridgeWatersMarketplace.ListingExpired.selector);
        // When listing expires, the listingId becomes zero

        bridgeWaters.buyListing(0);
    }

    function testBuyListing_ListingNotActive() public {
        switchSigner(creator1);
        // bridgeWaterNFT.mint(creator1, 2);
        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        bytes memory _signature = constructSig(
            address(bridgeWaterNFT),
            2,
            2 ether,
            2 days,
            creator1,
            privateKey1
        );
        listingInfo.signature = _signature;
        listingInfo.seller = creator1;
        listingInfo.tokenId = 2;

        bridgeWaters.createListing(
            listingInfo.token,
            listingInfo.tokenId,
            listingInfo.price,
            listingInfo.signature,
            listingInfo.deadline,
            listingInfo.seller,
            listingInfo.isActive = false
        );

        // vm.warp(1641070800);

        vm.expectRevert(BridgeWatersMarketplace.ListingNotActive.selector);
        // bridgeWaters.buyListing(_currentListingId);

        _buyListing();
    }

    function testBuyListing_PriceMismatch() public {
        _createBuyListing();

        vm.expectRevert(
            abi.encodeWithSelector(
                BridgeWatersMarketplace.PriceMismatch.selector,
                listingInfo.price
            )
        );

        bridgeWaters.buyListing{value: 3 ether}(currentListingId);
    }

    function testBuyListing_PriceNotMet() public {
        _createBuyListing();

        vm.expectRevert(
            abi.encodeWithSelector(
                BridgeWatersMarketplace.PriceNotMet.selector,
                (listingInfo.price - 1 ether)
            )
        );

        bridgeWaters.buyListing{value: 1 ether}(currentListingId);
    }

    function _createBuyListing() internal {
        switchSigner(creator1);
        // bridgeWaterNFT.mint(creator1, 2);
        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        bytes memory _signature = constructSig(
            address(bridgeWaterNFT),
            2,
            2 ether,
            2 days,
            creator1,
            privateKey1
        );
        listingInfo.signature = _signature;
        listingInfo.seller = creator1;
        listingInfo.tokenId = 2;

        bridgeWaters.createListing(
            listingInfo.token,
            listingInfo.tokenId,
            listingInfo.price,
            listingInfo.signature,
            listingInfo.deadline,
            listingInfo.seller,
            listingInfo.isActive
        );
    }

    // UPDATE LISTING

    function _updateListing() internal {
        switchSigner(creator1);
        bridgeWaters.updateListing(
            currentListingId,
            3 ether,
            listingInfo.isActive
        );
    }

    function testUpdateListing_ListingDoesNotExist() public {
        switchSigner(creator1);
        // bridgeWaterNFT.mint(creator1, 2);
        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        bytes memory _signature = constructSig(
            address(bridgeWaterNFT),
            2,
            2 ether,
            2 days,
            creator1,
            privateKey1
        );
        listingInfo.signature = _signature;
        listingInfo.seller = creator1;
        listingInfo.tokenId = 2;

        currentListingId = bridgeWaters.createListing(
            listingInfo.token,
            listingInfo.tokenId,
            listingInfo.price,
            listingInfo.signature,
            listingInfo.deadline,
            listingInfo.seller,
            listingInfo.isActive
        );

        vm.expectRevert(BridgeWatersMarketplace.ListingDoesNotExist.selector);

        bridgeWaters.updateListing(currentListingId, 0, false);
    }

    function testUpdateListing_NotOwner() public {
        switchSigner(creator1);
        bridgeWaterNFT.mint(creator1, 3);
        bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

        bytes memory _signature = constructSig(
            address(bridgeWaterNFT),
            2,
            2 ether,
            2 days,
            creator1,
            privateKey1
        );
        listingInfo.signature = _signature;
        listingInfo.seller = creator1;
        //listingInfo.tokenId

        uint256 _currentListingId = bridgeWaters.createListing(
            listingInfo.token,
            listingInfo.tokenId,
            listingInfo.price,
            listingInfo.signature,
            listingInfo.deadline,
            listingInfo.seller,
            listingInfo.isActive
        );

        vm.startPrank(spender);

        vm.expectRevert(BridgeWatersMarketplace.NotOwner.selector);

        bridgeWaters.updateListing(_currentListingId, 1 ether, true);
    }

    // function testUpdateListing() public {
    //     listingInfo.seller = creator1;

    //     switchSigner(creator1);
    //     //bridgeWaterNFT.mint(creator1, 2);
    //     bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

    //     bytes memory _signature = constructSig(
    //         address(bridgeWaterNFT),
    //         2,
    //         2 ether,
    //         2 days,
    //         creator1,
    //         privateKey1
    //     );
    //     listingInfo.signature = _signature;

    //     listingInfo.tokenId = 2;

    //     currentListingId = bridgeWaters.createListing(
    //         listingInfo.token,
    //         listingInfo.tokenId,
    //         listingInfo.price,
    //         listingInfo.signature,
    //         listingInfo.deadline,
    //         listingInfo.seller,
    //         listingInfo.isActive
    //     );

    //     uint256 newPrice = 3 ether;

    //     assertEq(
    //         bridgeWaterNFT.ownerOf(listingInfo.tokenId),
    //         address(bridgeWaters)
    //     );

    //     bridgeWaters.updateListing(
    //         currentListingId,
    //         newPrice,
    //         listingInfo.isActive
    //     );

    //     listingInfo = bridgeWaters.getListing(currentListingId);

    //     assertEq(listingInfo.price, newPrice);
    //     assertEq(listingInfo.isActive, true);
    // }

    // function testBuyListing() public {
    //         switchSigner(creator1);

    //         vm.warp(1641070800);

    //         listingInfo.deadline = uint88(block.timestamp + 120 minutes);

    //         bridgeWaterNFT.setApprovalForAll(address(bridgeWaters), true);

    //         listingInfo.signature = constructSig(
    //             listingInfo.token,
    //             listingInfo.tokenId,
    //             listingInfo.price,
    //             listingInfo.deadline,
    //             listingInfo.seller,
    //             privateKey1
    //         );

    //         currentListingId = bridgeWaters.createListing(
    //             listingInfo.token,
    //             listingInfo.tokenId,
    //             listingInfo.price,
    //             listingInfo.signature,
    //             listingInfo.deadline,
    //             listingInfo.seller,
    //             listingInfo.isActive
    //         );

    //         switchSigner(spender);
    //         //vm.warp(1641070800);
    //         bridgeWaters.buyListing{value: listingInfo.price}(currentListingId);
    //         assertEq(bridgeWaterNFT.ownerOf(currentListingId), spender);
    //     }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SignUtils} from "./libraries/SignUtils.sol";

struct ListingInfo {
    address token;
    uint256 tokenId;
    uint256 price;
    bytes signature;
    // slot packing... Slot 4
    uint88 deadline;
    address seller;
    bool isActive;
}

contract BridgeWatersMarketplace {
    mapping(uint256 => ListingInfo) public listingsInfo;
    address public admin;
    uint256 public listingId;

    /* ERRORS */
    error NotOwner();
    error NotApproved();
    error MinPriceTooLow();
    error DeadlineTooSoon();
    error MinDurationNotMet();
    error InvalidSignature();
    error ListingNotExistent();
    error ListingNotActive();
    error PriceNotMet(int256 difference);
    error ListingExpired();
    error PriceMismatch(uint256 originalPrice);

    /* EVENTS */
    event ListingCreated(uint256 indexed listingId, ListingInfo);
    event ListingExecuted(uint256 indexed listingId, ListingInfo);
    event ListingEdited(uint256 indexed listingId, ListingInfo);

    constructor() {
        admin = msg.sender;
    }

    function createListing(
        address _token,
        uint256 _tokenId,
        uint256 _price,
        uint88 _deadline,
        address _seller,
        bytes memory _signature
    ) public returns (uint256 _listingId) {
        if (IERC721(_token).ownerOf(_tokenId) != msg.sender) revert NotOwner();
        if (!IERC721(_token).isApprovedForAll(msg.sender, address(this)))
            revert NotApproved();
        if (_price < 0.01 ether) revert MinPriceTooLow();
        if (_deadline < block.timestamp) revert DeadlineTooSoon();
        if (_deadline - block.timestamp < 60 minutes)
            revert MinDurationNotMet();

        // Assert signature
        if (
            !SignUtils.isValid(
                SignUtils.constructMessageHash(
                    _token,
                    _tokenId,
                    _price,
                    _deadline,
                    _seller
                ),
                _signature,
                msg.sender
            )
        ) revert InvalidSignature();

        // transfer the NFT from owner to marketplace
        IERC721(_token).transferFrom(msg.sender, address(this), _tokenId);

        // append to Storage
        ListingInfo storage newListingInfo = listingsInfo[listingId];

        newListingInfo.token = _token;
        newListingInfo.tokenId = _tokenId;
        newListingInfo.price = _price;
        newListingInfo.signature = _signature;
        newListingInfo.deadline = _deadline;
        newListingInfo.seller = msg.sender;
        newListingInfo.isActive = true;

        _listingId = listingId;
        listingId++;

        // Emit event
        emit ListingCreated(listingId, newListingInfo);

        return listingId;
    }

    function executeListing(uint256 _listingId) public payable {
        if (_listingId >= listingId) revert ListingNotExistent();

        ListingInfo storage listing = listingsInfo[_listingId];

        if (listing.deadline < block.timestamp) revert ListingExpired();

        if (!listing.isActive) revert ListingNotActive();

        if (listing.price < msg.value) revert PriceMismatch(listing.price);

        if (listing.price != msg.value)
            revert PriceNotMet(int256(listing.price) - int256(msg.value));

        // Update state
        listing.isActive = false;

        // transfer
        IERC721(listing.token).transferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        // transfer eth
        payable(listing.seller).transfer(listing.price);

        // Update storage
        emit ListingExecuted(_listingId, listing);
    }

    function editListing(
        uint256 _listingId,
        uint256 _newPrice,
        bool _isActive
    ) public {
        if (_listingId >= listingId) revert ListingNotExistent();
        ListingInfo storage listing = listingsInfo[_listingId];
        if (listing.seller != msg.sender) revert NotOwner();
        listing.price = _newPrice;
        listing.isActive = _isActive;

        emit ListingEdited(_listingId, listing);
    }

    // add getter for listing
    function getListing(
        uint256 _listingId
    ) public view returns (ListingInfo memory) {
        // if (_listingId >= listingId)
        return listingsInfo[_listingId];
    }
}

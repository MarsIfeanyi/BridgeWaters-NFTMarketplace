// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BridgeWatersMarketplace {
    struct ItemInfo {
        address payable owner;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        uint256 deadline;
        bool isActive;
    }

    uint256 public itemsCounter;
    mapping(uint256 itemsCounter => ItemInfo) public listedItems;

    event ItemListed(
        address owner,
        uint256 indexed _tokenId,
        address indexed _tokenAddress,
        uint256 indexed _price,
        uint256 _deadline
    );

    event ItemSold(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed price
    );

    function getSigHash(
        address _tokenAddress,
        address _owner,
        uint256 _tokenId,
        uint256 _price,
        uint256 _deadline
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _tokenAddress,
                    _owner,
                    _tokenId,
                    _price,
                    _deadline
                )
            );
    }

    function verifySignature(
        bytes32 _sigHash,
        bytes memory _signature,
        address _expectedSigner
    ) public pure returns (bool) {
        return ECDSA.recover(_sigHash, _signature) == _expectedSigner;
    }

    function listItem(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _deadline,
        bytes memory _signature
    ) public {
        // checks
        require(
            msg.sender == IERC721(_tokenAddress).ownerOf(_tokenId),
            "Not owner"
        );
        require(
            IERC721(_tokenAddress).isApprovedForAll(msg.sender, address(this)),
            "ERC721: Insufficient Approval"
        );
        require(_tokenAddress != address(0), "Invalid tokenAddress");
        require(_price > 0, "Zero Price Not Allowed");
        require(_tokenId != 0, "Invalid tokenId");
        require(
            _deadline > block.timestamp + 1 days,
            "Deadline should be in the future"
        );

        // increment counter
        itemsCounter += 1;

        // transfer the NFT from owner to marketplace
        IERC721(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        // Access storage loaction
        ItemInfo storage itemInfo = listedItems[itemsCounter];

        // Update the struct mapping
        itemInfo.tokenId = _tokenId;
        itemInfo.tokenAddress = _tokenAddress;
        itemInfo.deadline = _deadline;
        itemInfo.owner = payable(msg.sender);
        itemInfo.price = _price;
        itemInfo.signature = _signature;
        itemInfo.isActive = true;

        // emit event
        emit ItemListed(msg.sender, _tokenId, _tokenAddress, _price, _deadline);
    }

    function buyItem(uint256 _listingId) external payable {
        require(
            _listingId != 0 && _listingId <= itemsCounter,
            "Wrong _listingId"
        );

        ItemInfo storage itemInfo = listedItems[_listingId];

        require(
            block.timestamp <= itemInfo.deadline,
            "Order deadline has passed"
        );
        require(msg.value == itemInfo.price, "Wrong ETH was sent");
        require(!itemInfo.isActive, "NFT-Order is already sold");

        bytes32 sigHash = getSigHash(
            itemInfo.tokenAddress,
            itemInfo.owner,
            itemInfo.tokenId,
            itemInfo.price,
            itemInfo.deadline
        );
        require(
            verifySignature(sigHash, itemInfo.signature, itemInfo.owner),
            "Invalid signature"
        );

        itemInfo.isActive = true;

        (bool sent, ) = itemInfo.owner.call{value: msg.value}("");
        require(sent, "Failed to transfer ETH");

        IERC721(itemInfo.tokenAddress).transferFrom(
            address(this),
            msg.sender,
            itemInfo.tokenId
        );

        emit ItemSold(msg.sender, itemInfo.tokenId, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BridgeWatersMarketplace {
    struct OrderInfo {
        address payable owner;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        uint256 deadline;
        bool isSold;
    }

    uint256 public odersCounter;
    mapping(uint256 odersCounter => OrderInfo) public listedOrders;

    constructor() {}

    function getOrderHash(
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
        bytes32 _orderHash,
        bytes memory _signature,
        address _expectedSigner
    ) public pure returns (bool) {
        return ECDSA.recover(_orderHash, _signature) == _expectedSigner;
    }

    function createOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _deadline,
        bytes memory _signature
    ) public {
        // address owner = msg.sender;
        // require(owner != address(0), "Invalid address");
        require(_tokenAddress != address(0), "Invalid tokenAddress");
        require(_price != 0, "Wrong Price");
        require(_tokenId != 0, "Invalid tokenId");
        // todo: check that the creator is the owner
        require(
            msg.sender == IERC721(_tokenAddress).ownerOf(_tokenId),
            "Not owner"
        );

        // bytes32 orderHash = getOrderHash(
        //     _tokenAddress,
        //     address(owner),
        //     _tokenId,
        //     _price,
        //     _deadline
        // );
        // require(
        //     verifySignature(orderHash, _signature, msg.sender),
        //     "Invalid signature"
        // );

        odersCounter += 1;

        // TODO: Add check for approvals... Approval for all

        IERC721(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        OrderInfo storage orderinfo = listedOrders[odersCounter];
        orderinfo.tokenId = _tokenId;
        orderinfo.tokenAddress = _tokenAddress;
        orderinfo.deadline = _deadline;
        orderinfo.owner = payable(msg.sender);
        orderinfo.price = _price;
        orderinfo.signature = _signature;
    }

    function buyOrder(uint256 _orderId) external payable {
        require(_orderId != 0 && _orderId <= odersCounter, "Wrong _orderId");

        OrderInfo storage orderinfo = listedOrders[_orderId];

        require(
            block.timestamp <= orderinfo.deadline,
            "Order deadline has passed"
        );
        require(msg.value == orderinfo.price, "Wrong ETH was sent");
        require(!orderinfo.isSold, "NFT-Order is already sold");

        bytes32 orderHash = getOrderHash(
            orderinfo.tokenAddress,
            orderinfo.owner,
            orderinfo.tokenId,
            orderinfo.price,
            orderinfo.deadline
        );
        require(
            verifySignature(orderHash, orderinfo.signature, orderinfo.owner),
            "Invalid signature"
        );

        orderinfo.isSold = true;

        IERC721(orderinfo.tokenAddress).transferFrom(
            address(this),
            msg.sender,
            orderinfo.tokenId
        );

        (bool sent, ) = orderinfo.owner.call{value: msg.value}("");
        require(sent, "Failed to transfer ETH");
    }
}

// use the sign cheatcode

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BridgeWaterNFT is ERC721("BridgeWatersNFT", "BWN") {
    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return "BridgeWaters";
    }

    function mint(address recipient, uint256 tokenId) public payable {
        _mint(recipient, tokenId);
    }
}

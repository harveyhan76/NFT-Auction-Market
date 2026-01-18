// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;

    // 构造函数：初始化 NFT 名称和符号，设置部署者为所有者
    constructor() ERC721("AuctionNFT", "ANFT") Ownable(msg.sender) {}

    // 铸造 NFT：对任意地址开放
    function mint(address to) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    // 获取当前最大 TokenID
    function getTokenIdCounter() public view returns (uint256) {
        return _tokenIdCounter;
    }
}
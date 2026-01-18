// 继承 V1 合约，追加新功能
contract AuctionV2 is Auction {
    // 新增存储变量：必须追加在最后
    mapping(uint256 => uint256) public feeTiers; // 动态手续费档位

    // 新增初始化函数（可选，升级后初始化新变量）
    function initializeV2() external onlyOwner {
        // 设置动态手续费档位
        feeTiers[100 * 1e18] = 50; // < $100: 0.5%
        feeTiers[1000 * 1e18] = 40; // $100-$1000: 0.4%
    }

    // 重写手续费计算逻辑（新增功能）
    function _getDynamicFeeRate(uint256 _usdAmount) internal view returns (uint256) {
        // 动态手续费逻辑
        if (_usdAmount < 100 * 1e18) return feeTiers[100 * 1e18];
        if (_usdAmount < 1000 * 1e18) return feeTiers[1000 * 1e18];
        return 30; // > $1000: 0.3%
    }

    // 重写结束拍卖函数，使用动态手续费
    function endAuction(uint256 _auctionId) external override {
        AuctionItem storage auction = auctions[_auctionId];
        require(auction.status == AuctionStatus.Active, "Not active");
        require(block.timestamp >= auction.endTime, "Not ended");

        auction.status = AuctionStatus.Ended;
        if (auction.highestBidder != address(0)) {
            // 使用动态手续费
            uint256 feeRate = _getDynamicFeeRate(auction.highestBidUsd);
            uint256 fee = (auction.highestBidAmount * feeRate) / 10000;
            uint256 sellerAmount = auction.highestBidAmount - fee;

            // 转移 NFT 和资金（逻辑不变）
            IERC721(auction.nftContract).transferFrom(address(this), auction.highestBidder, auction.tokenId);
            if (auction.bidCurrency == address(0)) {
                (bool success, ) = auction.seller.call{value: sellerAmount}("");
                require(success, "ETH transfer failed");
            } else {
                IERC20(auction.bidCurrency).transfer(auction.seller, sellerAmount);
            }
        }
    }

    // 升级权限控制（继承 V1，也可重写）
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
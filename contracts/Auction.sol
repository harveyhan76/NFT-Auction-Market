// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Auction is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // 拍卖状态枚举
    enum AuctionStatus { Created, Active, Ended }

    // 拍卖结构体
    struct AuctionItem {
        uint256 auctionId;          // 拍卖ID
        address nftContract;        // NFT 合约地址
        uint256 tokenId;            // NFT TokenID
        address seller;             // 卖家地址
        uint256 startTime;          // 开始时间
        uint256 endTime;            // 结束时间
        address highestBidder;      // 最高出价者
        uint256 highestBidAmount;   // 最高出价金额
        uint256 highestBidUsd;      // 最高出价美元价值
        address bidCurrency;        // 出价代币地址（0x0 代表 ETH）
        AuctionStatus status;       // 拍卖状态
    }

    // 状态变量
    uint256 private _auctionIdCounter;
    mapping(uint256 => AuctionItem) public auctions;          // 拍卖ID => 拍卖信息
    mapping(address => mapping(uint256 => uint256)) public userBids; // 用户 => 拍卖ID => 出价金额

    // Chainlink 价格预言机
    AggregatorV3Interface public ethUsdPriceFeed;
    mapping(address => AggregatorV3Interface) public erc20UsdPriceFeeds;

    // 手续费配置（万分之）
    uint256 public feeRate; // 例如：50 = 0.5%

    // 事件定义
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, uint256 indexed tokenId);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 usdValue);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 amount);

    // 初始化函数（替代构造函数）
    function initialize(
        address _ethUsdPriceFeed,
        uint256 _feeRate
    ) external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        feeRate = _feeRate;
        _auctionIdCounter = 1;
    }

    // UUPS 升级权限控制
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // 添加 ERC20 价格预言机
    function addERC20PriceFeed(address _token, address _priceFeed) external onlyOwner {
        erc20UsdPriceFeeds[_token] = AggregatorV3Interface(_priceFeed);
    }

    // 创建拍卖
    function createAuction(
        address _nftContract,
        uint256 _tokenId,
        uint256 _duration, // 拍卖时长（秒）
        address _bidCurrency // 0x0 代表 ETH
    ) external {
        // 检查 NFT 所有权
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        
        // 转移 NFT 到合约
        nft.transferFrom(msg.sender, address(this), _tokenId);

        // 创建拍卖
        uint256 auctionId = _auctionIdCounter++;
        auctions[auctionId] = AuctionItem({
            auctionId: auctionId,
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            highestBidder: address(0),
            highestBidAmount: 0,
            highestBidUsd: 0,
            bidCurrency: _bidCurrency,
            status: AuctionStatus.Active
        });

        emit AuctionCreated(auctionId, msg.sender, _tokenId);
    }

    // 以 ETH 出价
    function bidWithETH(uint256 _auctionId) external payable {
        require(msg.value > 0, "Bid amount must be > 0");
        _placeBid(_auctionId, msg.sender, msg.value, address(0));
    }

    // 以 ERC20 出价
    function bidWithERC20(uint256 _auctionId, uint256 _amount) external {
        require(_amount > 0, "Bid amount must be > 0");
        AuctionItem storage auction = auctions[_auctionId];
        require(auction.bidCurrency != address(0), "Auction not for ERC20");
        
        // 转移 ERC20 代币到合约
        IERC20 token = IERC20(auction.bidCurrency);
        require(token.transferFrom(msg.sender, address(this), _amount), "ERC20 transfer failed");
        
        _placeBid(_auctionId, msg.sender, _amount, auction.bidCurrency);
    }

    // 核心出价逻辑
    function _placeBid(
        uint256 _auctionId,
        address _bidder,
        uint256 _amount,
        address _currency
    ) internal {
        AuctionItem storage auction = auctions[_auctionId];
        
        // 检查拍卖状态
        require(auction.status == AuctionStatus.Active, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(_currency == auction.bidCurrency, "Invalid currency");
        require(_bidder != auction.seller, "Seller cannot bid");

        // 计算出价的美元价值
        uint256 bidUsd = _convertToUsd(_amount, _currency);
        require(bidUsd > auction.highestBidUsd, "Bid not highest");

        // 更新最高出价
        auction.highestBidder = _bidder;
        auction.highestBidAmount = _amount;
        auction.highestBidUsd = bidUsd;

        // 记录用户出价
        userBids[_bidder][_auctionId] += _amount;

        emit BidPlaced(_auctionId, _bidder, _amount, bidUsd);
    }

    // 结束拍卖
    function endAuction(uint256 _auctionId) external {
        AuctionItem storage auction = auctions[_auctionId];
        
        // 检查拍卖状态
        require(auction.status == AuctionStatus.Active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");
        require(msg.sender == auction.seller || msg.sender == owner(), "Not authorized");

        // 更新拍卖状态
        auction.status = AuctionStatus.Ended;

        if (auction.highestBidder != address(0)) {
            // 计算手续费
            uint256 fee = (auction.highestBidAmount * feeRate) / 10000;
            uint256 sellerAmount = auction.highestBidAmount - fee;

            // 转移 NFT 给最高出价者
            IERC721(auction.nftContract).transferFrom(address(this), auction.highestBidder, auction.tokenId);

            // 转移资金
            if (auction.bidCurrency == address(0)) {
                // ETH 处理
                (bool ownerSuccess, ) = owner().call{value: fee}("");
                (bool sellerSuccess, ) = auction.seller.call{value: sellerAmount}("");
                require(ownerSuccess && sellerSuccess, "ETH transfer failed");
            } else {
                // ERC20 处理
                IERC20 token = IERC20(auction.bidCurrency);
                require(token.transfer(owner(), fee), "Fee transfer failed");
                require(token.transfer(auction.seller, sellerAmount), "Seller transfer failed");
            }
        } else {
            // 无出价，返还 NFT 给卖家
            IERC721(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);
        }

        emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBidAmount);
    }

    // 转换金额到美元
    function _convertToUsd(uint256 _amount, address _currency) internal view returns (uint256) {
        if (_currency == address(0)) {
            // ETH 转 USD
            (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
            return (_amount * uint256(price)) / 1e18;
        } else {
            // ERC20 转 USD
            AggregatorV3Interface priceFeed = erc20UsdPriceFeeds[_currency];
            require(address(priceFeed) != address(0), "Price feed not found");
            (, int256 price, , , ) = priceFeed.latestRoundData();
            return (_amount * uint256(price)) / 1e18;
        }
    }

    // 外部调用：转换金额到美元（供前端使用）
    function convertToUsd(uint256 _amount, address _currency) external view returns (uint256) {
        return _convertToUsd(_amount, _currency);
    }

    // 更新手续费率（仅所有者）
    function updateFeeRate(uint256 _newFeeRate) external onlyOwner {
        require(_newFeeRate <= 1000, "Fee rate too high (max 10%)");
        feeRate = _newFeeRate;
    }

    // 接收 ETH
    receive() external payable {}
}
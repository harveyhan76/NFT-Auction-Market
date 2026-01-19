const { ethers, upgrades } = require("hardhat"); 

async function main() {
  // 1. 配置参数（Sepolia ETH/USD 预言机地址）
  const ethUsdPriceFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";
  const feeRate = 50; // 0.5% 手续费

  console.log("🚀 开始部署 UUPS 可升级 Auction 合约...");

  // 2. 创建合约工厂（Hardhat 3.x 标准写法）
  const Auction = await ethers.getContractFactory("Auction");

  // 3. 部署 UUPS 代理合约（核心！）
  const auctionProxy = await upgrades.deployProxy(
    Auction,
    [ethUsdPriceFeed, feeRate], // initialize 函数参数
    {
      kind: "uups", // 明确指定 UUPS 模式
      initializer: "initialize", // 初始化函数名
    }
  );

  // 4. 等待部署完成，打印关键信息
  await auctionProxy.waitForDeployment();
  const proxyAddress = await auctionProxy.getAddress();
  const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);

  console.log(`✅ UUPS 代理合约部署完成：${proxyAddress}`);
  console.log(`✅ 实现合约地址（可升级替换）：${implAddress}`);
  console.log(`💡 注意：用户永远交互代理地址，升级时仅替换实现合约`);
}

// 执行部署并捕获错误
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ 部署失败：", error);
    process.exit(1);
  });
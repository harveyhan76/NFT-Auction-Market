const { ethers, upgrades } = require("hardhat"); 

// 替换为你部署的代理合约地址（从部署脚本输出复制）
const PROXY_ADDRESS = "YOUR_DEPLOYED_PROXY_ADDRESS";

async function main() {
  console.log(`🚀 开始升级 UUPS 合约（代理地址：${PROXY_ADDRESS}）...`);

  // 1. 加载 V2 合约工厂（需先编写 AuctionV2.sol）
  const AuctionV2 = await ethers.getContractFactory("AuctionV2");

  // 2. 执行升级（核心：代理地址不变，仅替换实现合约）
  const upgradedProxy = await upgrades.upgradeProxy(PROXY_ADDRESS, AuctionV2);
  await upgradedProxy.waitForDeployment();

  // 3. 验证升级结果
  const newImplAddress = await upgrades.erc1967.getImplementationAddress(PROXY_ADDRESS);
  console.log(`✅ 合约升级完成！新实现合约地址：${newImplAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ 升级失败：", error);
    process.exit(1);
  });
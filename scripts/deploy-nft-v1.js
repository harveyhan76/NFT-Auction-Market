// scripts/deploy-nft.js
const { ethers } = require("hardhat"); // Hardhat 3.x 兼容写法

async function main() {
  // ===================== 1. 配置部署参数（根据你的NFT合约调整）=====================
  // NFT 名称、符号（对应合约构造函数参数）
  const NFT_NAME = "MyAuctionNFT";
  const NFT_SYMBOL = "MAN";
  // 部署者地址（自动获取 Hardhat 签名者）
  const [deployer] = await ethers.getSigners();

  console.log("🚀 开始部署普通 NFT 合约...");
  console.log("部署者地址：", deployer.address);
  console.log("NFT 配置：名称 =", NFT_NAME, "，符号 =", NFT_SYMBOL);

  // ===================== 2. 创建 NFT 合约工厂 =====================
  // 注意：括号内的字符串要和你的 NFT 合约文件名/合约名完全一致（比如你的合约是 MyNFT.sol，合约名 MyNFT）
  const NFTContract = await ethers.getContractFactory("MyAuctionNFT");

  // ===================== 3. 部署 NFT 合约（核心：普通合约用 deploy()）=====================
  // 括号内传入合约构造函数的参数（如果你的合约无构造函数，直接写 await NFTContract.deploy()）
  const nftContract = await NFTContract.deploy(NFT_NAME, NFT_SYMBOL);

  // ===================== 4. 等待部署上链确认 =====================
  // waitForDeployment() 是 Ethers v6+ 写法（Hardhat 3.x 配套）
  await nftContract.waitForDeployment();
  // 获取最终部署的合约地址
  const nftContractAddress = await nftContract.getAddress();

  // ===================== 5. 打印部署结果 =====================
  console.log("✅ NFT 合约部署完成！");
  console.log("NFT 合约地址：", nftContractAddress);
  console.log("💡 验证命令（部署到测试网/主网后执行）：");
  console.log(`npx hardhat verify --network sepolia ${nftContractAddress} "${NFT_NAME}" "${NFT_SYMBOL}"`);
}

// ===================== 6. 执行部署 + 错误处理 =====================
main()
  .then(() => process.exit(0)) // 部署成功退出
  .catch((error) => {
    console.error("❌ NFT 合约部署失败：", error);
    process.exit(1); // 部署失败退出（非0码标识错误）
  });
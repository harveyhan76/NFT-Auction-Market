// import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
// import { getHardhatRuntimeEnvironment } from "@nomicfoundation/hardhat-ignition/internal/core/hardhat-runtime";

// // 替换为你部署的代理合约地址（部署后从终端复制）
// const PROXY_ADDRESS = "YOUR_DEPLOYED_PROXY_ADDRESS";

// // 封装升级逻辑
// async function upgradeAuctionToV2(hre: HardhatRuntimeEnvironment) {
//     const { ethers, upgrades } = hre;

//     // 步骤1：加载 V2 合约工厂（需先编写 AuctionV2.sol）
//     const AuctionV2Factory = await ethers.getContractFactory("AuctionV2");

//     // 步骤2：执行升级（代理地址不变，替换实现合约）
//     const upgradedProxy = await upgrades.upgradeProxy(PROXY_ADDRESS, AuctionV2Factory);
//     await upgradedProxy.waitForDeployment();

//     // 验证升级结果
//     const newImplAddress = await upgrades.erc1967.getImplementationAddress(PROXY_ADDRESS);
//     console.log(`✅ 合约升级完成！新实现合约地址：${newImplAddress}`);

//     return upgradedProxy;
// }

// // 定义升级模块
// export default buildModule("AuctionUUPSUpgradeModule", (m) => {
//     const upgradedAuction = m.action("UpgradeAuctionToV2", async () => {
//         const hre = getHardhatRuntimeEnvironment();
//         return await upgradeAuctionToV2(hre);
//     });

//     m.exports({ upgradedAuction });
//     return { upgradedAuction };
// });
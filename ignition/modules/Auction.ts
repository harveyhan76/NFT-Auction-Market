// import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
// // 1. 导入 Ignition 内置的 HRE 获取函数 + Hardhat 类型
// import { getHardhatRuntimeEnvironment } from "@nomicfoundation/hardhat-ignition/internal/core/hardhat-runtime";
// import type { HardhatRuntimeEnvironment } from "hardhat/types";

// // 2. 封装 UUPS 部署逻辑（独立函数，便于复用/维护）
// async function deployUUPSContract(hre: HardhatRuntimeEnvironment) {
//     // 从 HRE 动态获取 ethers/upgrades（Hardhat 3.x 标准写法）
//     const { ethers, upgrades } = hre;

//     // 配置参数（Sepolia ETH/USD 预言机地址）
//     const ethUsdPriceFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";
//     const feeRate = 50; // 0.5% 手续费

//     // 步骤1：创建合约工厂
//     const AuctionFactory = await ethers.getContractFactory("Auction");

//     // 步骤2：部署 UUPS 代理合约（核心！）
//     const auctionProxy = await upgrades.deployProxy(
//         AuctionFactory,
//         [ethUsdPriceFeed, feeRate], // initialize 函数的参数
//         {
//             kind: "uups", // 明确指定 UUPS 模式（必须！）
//             initializer: "initialize", // 初始化函数名
//         }
//     );

//     // 步骤3：等待部署完成，打印关键信息
//     await auctionProxy.waitForDeployment();
//     const proxyAddress = await auctionProxy.getAddress();
//     const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);

//     console.log(`✅ UUPS 代理合约部署完成：${proxyAddress}`);
//     console.log(`✅ 实现合约地址（可升级替换）：${implAddress}`);

//     return auctionProxy;
// }

// // 3. 定义 Ignition 模块（最新 API）
// export default buildModule("AuctionUUPSModule", (m) => {
//     // 使用 m.action() 执行自定义异步逻辑（替代旧的 m.run()）
//     const auctionProxy = m.action("DeployAuctionUUPS", async () => {
//         // 获取 Ignition 运行时的 HRE
//         const hre = getHardhatRuntimeEnvironment();
//         // 执行 UUPS 部署
//         return await deployUUPSContract(hre);
//     });

//     // 导出合约实例（供前端/其他模块引用）
//     m.exports({ auctionProxy });

//     return { auctionProxy };
// });
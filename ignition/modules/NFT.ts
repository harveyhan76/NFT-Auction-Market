import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("NFTModule", (m) => {
  // 部署 NFT 合约（无构造函数参数）
  const nft = m.contract("NFT");

  // 铸造一个测试 NFT 给部署者
  m.call(nft, "mint", [m.getAccount(0)]);

  return { nft };
});
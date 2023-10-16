const { ethers } = require("hardhat");

async function main() {

  // 部署工厂合约。
  const Factory = await ethers.deployContract("Factory", { gasLimit: "0x1000000" });
  await Factory.waitForDeployment();
  console.log(`Factory deployed to ${Factory.target}`);

  // 部署逻辑合约。
  const AreYouInTrouble = await ethers.deployContract("AreYouInTrouble", { gasLimit: "0x1000000" });
  await AreYouInTrouble.waitForDeployment();
  console.log(`AreYouInTrouble deployed to ${AreYouInTrouble.target}`);

}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
const hre = require("hardhat");

async function main() {
  const TradeContract = await hre.ethers.getContractFactory("TradeFactory");
  const tradeContract = await TradeContract.deploy();
  await tradeContract.deployed();
  console.log("Contract deployed to:", tradeContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

const hre = require("hardhat");

async function main() {
  const TokenContract = await hre.ethers.getContractFactory("TestERC20");
  const tokenContract = await TokenContract.deploy();
  await tokenContract.deployed();
  console.log("Contract deployed to:", tokenContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

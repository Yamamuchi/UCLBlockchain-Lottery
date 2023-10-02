import * as dotenvenc from '@chainlink/env-enc'
import { ethers } from "hardhat";

async function main() {
  const UCLBLottery = await ethers.deployContract("UCLBLottery");
  await UCLBLottery.waitForDeployment();

  console.log("UCLBLottery deployed to:", UCLBLottery.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

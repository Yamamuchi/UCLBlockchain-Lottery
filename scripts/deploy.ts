import { ethers } from "hardhat";
import * as fs from 'fs';
import csv from 'csv-parser';

// Extract first names from the entries dataset
async function getFirstNamesFromCsv(filePath: string): Promise<string[]> {
  return new Promise((resolve, reject) => {
      const names: string[] = [];
      
      fs.createReadStream(filePath)
          .pipe(csv())
          .on('data', (row) => {
              const fullName: string = row["Full name"];
              const firstName: string = fullName.split(' ')[0].trim();
              names.push(firstName);
          })
          .on('end', () => {
              resolve(names);
          })
          .on('error', reject);
  });
}

async function main() {
  // Constructor arguments
  const subscriptionId = 5755;
  const vrfCoordinator = '0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625';
  const keyHash = '0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c';
  const firstNames = await getFirstNamesFromCsv('../UCLBlockchain-Lottery/datasets/entries.xls');

  console.log("Deploying contract...");

  // Deploy lottery contract with the constructor arguments
  const UCLBLottery = await ethers.deployContract("UCLBLottery", [subscriptionId, vrfCoordinator, keyHash, firstNames]);

  await UCLBLottery.waitForDeployment();
  console.log(UCLBLottery)
  console.log("UCLBLottery address:", UCLBLottery.target);

  // Wait for 7 confirmations
  await UCLBLottery.deploymentTransaction()!.wait(7);

  // Verify contract on Etherscan
  await run("verify:verify", {
    address: UCLBLottery.target,
    constructorArguments: [subscriptionId, vrfCoordinator, keyHash, firstNames],
    contract: "contracts/UCLBLottery.sol:UCLBLottery"
});
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

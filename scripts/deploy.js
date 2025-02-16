const hre = require("hardhat");

async function main() {
  // Get the deployer's address
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy GreenGiraffeTracibility
  const GreenGiraffeTracibility = await hre.ethers.getContractFactory(
    "GreenGiraffeTracibility"
  );
  const greenGiraffe = await GreenGiraffeTracibility.deploy();

  await greenGiraffe.waitForDeployment();

  const contractAddress = await greenGiraffe.getAddress();
  console.log("GreenGiraffeTracibility deployed to:", contractAddress);

  // Log some additional info
  console.log("Owner address:", await greenGiraffe.owner());
  console.log(
    "Deployment transaction hash:",
    greenGiraffe.deploymentTransaction().hash
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

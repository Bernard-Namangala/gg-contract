const hre = require("hardhat");

async function main() {
  const contractAddress = "YOUR_DEPLOYED_CONTRACT_ADDRESS";
  const GreenGiraffeTracibility = await hre.ethers.getContractAt(
    "GreenGiraffeTracibility",
    contractAddress
  );

  // Example interaction
  const batchInput = {
    cropName: "Test Crop",
    start: Math.floor(Date.now() / 1000),
    end: Math.floor(Date.now() / 1000) + 86400, // 24 hours later
    farmer: "Farmer John",
    expectedYield: 1000,
    land: "Field A",
    status: "Active",
  };

  const tx = await GreenGiraffeTracibility.createBatch(batchInput);
  await tx.wait();
  console.log("Batch created, transaction hash:", tx.hash);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

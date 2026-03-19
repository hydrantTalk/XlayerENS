import hre from "hardhat";

async function main() {
  const connection = await hre.network.connect();
  const ethers = connection.ethers;

  const [deployer] = await ethers.getSigners();
  const balance = await ethers.provider.getBalance(deployer.address);

  console.log("Deploying ENSBadge with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "OKB");

  const ENSBadge = await ethers.getContractFactory("ENSBadge");
  const ensBadge = await ENSBadge.deploy(deployer.address);
  await ensBadge.waitForDeployment();

  const contractAddress = await ensBadge.getAddress();
  console.log("ENSBadge deployed to:", contractAddress);
  console.log("Badge #1 pre-minted to:", deployer.address);
  console.log("Total minted:", (await ensBadge.totalMinted()).toString());

  // Save deployed address
  const fs = await import("fs");
  fs.writeFileSync(
    "deployed-address.json",
    JSON.stringify({ address: contractAddress, network: "xlayer", chainId: 196 }, null, 2)
  );
  console.log("Contract address saved to deployed-address.json");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

import { ethers } from "hardhat";

async function main() {
  // // Deploy ConduitController first
  const ConduitController = await ethers.getContractFactory(
    "ConduitController"
  );
  const conduitController = await ConduitController.deploy();
  await conduitController.deployed();
  console.log("ConduitController deployed to:", conduitController.address);

  // Now deploy Seaport, passing in the address of the deployed ConduitController
  const Seaport = await ethers.getContractFactory("Seaport");
  const seaport = await Seaport.deploy(conduitController.address,
    { gasLimit: 10_000_000 }
  );
  await seaport.deployed();
  console.log("Seaport deployed to:", seaport.address);
  const seaportName = await seaport.name();
  console.log("Seaport name:", seaportName);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// HEDERA TESTNET
// ConduitController deployed to: 0xB3736767943853811084cc8e0AB2D95EdBBFDfBa
// Seaport deployed to: 0x5533047b1dB46F2Dd5EE13F7b4763e1735eFE7FA

// SERV TESTNET
// ConduitController deployed to: 0x2f5b471293a4bDF7b56f7193b82a9f8029Dae33B
// Seaport deployed to: 0x9913bCaF9B1Bd71a150D0F79c048Db8Fabe6928d
// Seaport name: Seaport

// npx hardhat run scripts/deploy_seaport_and_conduit.ts --network serv
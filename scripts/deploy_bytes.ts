import { ethers } from "hardhat";

async function main() {
    // Get the signer to deploy the contract
    const [deployer] = await ethers.getSigners();

    // The bytecode of the contract you want to deploy
    const bytecode = "0xab53e92aee85880427878492ca92e3e08f056b39b314c2900e884f11c34e0720deecf1b6bdafc1d56db25768a8eacdff794fc581f85630e9ccb82a4eed64c850"
    // Create and send the transaction
    const tx = await deployer.sendTransaction({
        data: bytecode,
        gasLimit: 1000000
    });

    console.log("Transaction hash:", tx.hash);

    // Wait for the transaction to be mined
    const receipt = await tx.wait();

    // The contract address can be found in the transaction receipt
    console.log("Contract deployed to:", receipt.contractAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
// ConduitController deployed to: 0xB3736767943853811084cc8e0AB2D95EdBBFDfBa
// Seaport deployed to: 0x5533047b1dB46F2Dd5EE13F7b4763e1735eFE7FA

//   Deploying contracts with the account: 0x79F8275d4e10c54832662AD2Ac40Bd83305D2803
// ERC20 Token deployed to: 0x637f1392B71fdaC399bCf5690B0582b2fc641d1B
// ERC721 Token deployed to: 0xAF472BE92F956Aa13a9f983E8b8B6100278D7eC2
// Minted ERC20 and ERC721 tokens to 0x79F8275d4e10c54832662AD2Ac40Bd83305D2803

// createSeaportOrder:signed 0xab53e92aee85880427878492ca92e3e08f056b39b314c2900e884f11c34e0720deecf1b6bdafc1d56db25768a8eacdff794fc581f85630e9ccb82a4eed64c850

import { ethers } from "hardhat";

const hre = require("hardhat");

const buyerAddress = "0xb70157B606A70Eac30791fC9Daef93e07Bd58581";
const buyerPrivateKey =
  "724e1aab19fb26ff9ba4822cf7f28551b5baedb14835105bfc6fa5d3e5e3595f";

const seaportAddress = "0x5533047b1dB46F2Dd5EE13F7b4763e1735eFE7FA";
const conduitAddress = "0xB3736767943853811084cc8e0AB2D95EdBBFDfBa";

const erc20TokenAddress = "0x637f1392B71fdaC399bCf5690B0582b2fc641d1B";
const erc721TokenAddress = "0xAF472BE92F956Aa13a9f983E8b8B6100278D7eC2";

async function deployMockERC20() {
  const Token = await hre.ethers.getContractFactory("MockERC20");
  const token = await Token.deploy(
    "Token",
    "TKN",
    18,
    hre.ethers.utils.parseEther("1000")
  );

  await token.deployed();
  console.log("ERC20 Token deployed to:", token.address);
  return token;
}

async function deployMockERC721() {
  const Token = await hre.ethers.getContractFactory("TestERC721");
  const token = await Token.deploy();

  await token.deployed();
  console.log("ERC721 Token deployed to:", token.address);
  return token;
}

async function mintTokens(erc20: any, erc721: any, deployer: any) {

  // Mint ERC20 tokens to the caller
  await erc20.mint(deployer.address, hre.ethers.utils.parseEther("10000"));
  await erc20.mint(buyerAddress, hre.ethers.utils.parseEther("10000"));

  // Mint an ERC721 token to the caller
  await erc721.mint(deployer.address, 1);
  await erc721.mint(buyerAddress, 2);

  console.log(`Minted ERC20 and ERC721 tokens to ${deployer.address}`);
}

async function approveERC20(ownerSigner: any) {
  const token = await ethers.getContractAt(
    "MockERC20",
    erc20TokenAddress,
    ownerSigner
  );
  let tx = await token.approve(seaportAddress, ethers.constants.MaxUint256);
  await tx.wait();
     tx = await token.approve(conduitAddress, ethers.constants.MaxUint256);
    await tx.wait();
  console.log(`Approved ERC20 token at ${erc20TokenAddress} for Seaport`);
}

async function approveERC721(ownerSigner: any) {
  const token = await ethers.getContractAt(
    "TestERC721",
    erc721TokenAddress,
    ownerSigner
  );
  let tx = await token.setApprovalForAll(seaportAddress, true);
  await tx.wait();
     tx = await token.setApprovalForAll(conduitAddress, true);
    await tx.wait();
  console.log(`Approved ERC721 token at ${erc721TokenAddress} for Seaport`);
}

async function doFulfilBasicOrder(signer) {
  const seaport = await ethers.getContractAt("Seaport", seaportAddress, signer);

  enum BasicOrderRouteType {
    ETH_TO_ERC721,
    ETH_TO_ERC1155,
    ERC20_TO_ERC721,
    ERC20_TO_ERC1155,
    ERC721_TO_ERC20,
    ERC1155_TO_ERC20,
  }
  const basicOrderRouteType = BasicOrderRouteType.ERC20_TO_ERC721;
  const basicOrderParameters = {
    offerer: "0x79F8275d4e10c54832662AD2Ac40Bd83305D2803",
    offererConduitKey:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    zone: "0x0000000000000000000000000000000000000000",
    basicOrderType: 0 + 4 * basicOrderRouteType,
    offerToken: erc721TokenAddress,
    offerAmount: 1,
    offerIdentifier: 1,
    considerationToken: erc20TokenAddress,
    considerationIdentifier: 0,
    considerationAmount: "92500000000000000",
    startTime: 1708457077,
    endTime: 1709144675,
    salt: "1522399221563110400", // "0x0000000000000000000000000000000000000000000000001520a606a799b42d",
    totalOriginalAdditionalRecipients: 1,

    fulfillerConduitKey:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    additionalRecipients: [
      {
        amount: "2500000000000000",
        recipient: "0xe1fe7A4DBF33e6dA8c9e2628d102c67FB9E94549",
      },
    ],
    zoneHash:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    signature:
      "0x6008bd57b3807cf843268d242d863d649e39b950109539d2919302181fab6f4f4e04c3b87fd9d0e2a687a593842bfb4fb6d02cd315f35ad6c455f38cde07632a",
  };

  const result = await seaport.fulfillBasicOrder(basicOrderParameters, {
    gasLimit: 10000000,
  });
  const receipt = await result.wait();
  console.log(receipt);
}

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const buyerWallet = new ethers.Wallet(buyerPrivateKey, ethers.provider);
  // Now you can use buyerWallet to send transactions or interact with contracts
  console.log(`Buyer address: ${buyerWallet.address}`);
  console.log("Deploying contracts with the account:", deployer.address);

    // const erc20 = await ethers.getContractAt(
    //     "MockERC20",
    //     erc20TokenAddress,
    //     deployer
    // )
    // const erc721 = await ethers.getContractAt(
    //     "TestERC721",
    //     erc721TokenAddress,
    //     deployer
    // )

    // await mintTokens(erc20, erc721, deployer);

    // await approveERC20(deployer);
    // await approveERC721(deployer);

    await approveERC20(buyerWallet);
    await approveERC721(buyerWallet);

  //   const erc20 = await deployMockERC20();
  //   const erc721 = await deployMockERC721();

  //   

//   await doFulfilBasicOrder(buyerWallet);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

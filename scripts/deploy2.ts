import { ethers } from 'hardhat';

async function main() {

  const Lock = await ethers.getContractFactory("UniswapV2Factory");
  const lock = await Lock.deploy("0x61224822ed31db4deA05c5784267c521f541Def5");

  await lock.deployed();

  console.log("Contract address:", lock.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

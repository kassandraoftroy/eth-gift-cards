import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  if (
    hre.network.name === "mainnet" ||
    hre.network.name === "rinkeby" ||
    hre.network.name === "ropsten" //||
    //hre.network.name === "goerli"
  ) {
    console.log(
      `!! Deploying EthGiftCards to mainnet/testnet. Hit ctrl + c to abort`
    );
    await new Promise((r) => setTimeout(r, 20000));
  }

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("EthGiftCards", {
    from: deployer,
    args: [
        "Eth Gift Cards",
        "NF-ETH",
        [
          '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: green; font-family: courier; font-size: 11px; }</style><rect width="100%" height="100%" fill="pink" /><text x="10" y="20" class="base">value: ',
          '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: #d7d9ce; font-family: courier; font-size: 11px; }</style><rect width="100%" height="100%" fill="#0c7489" /><text x="10" y="20" class="base">value: ',
          '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: #19231a; font-family: courier; font-size: 11px; }</style><rect width="100%" height="100%" fill="#33673b" /><text x="10" y="20" class="base">value: ',
          '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: courier; font-size: 11px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">value: '
        ]
    ],
  });
};

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip =
    hre.network.name === "mainnet" ||
    hre.network.name === "rinkeby" ||
    hre.network.name === "ropsten" //||
    //hre.network.name === "goerli";
  return shouldSkip ? true : false;
};

func.tags = ["EthGiftCards"];

export default func;
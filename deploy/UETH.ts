import assert from 'assert'

import { type DeployFunction } from 'hardhat-deploy/types'

const contractName = 'OutrunOmnichainUniversalPrincipalToken'

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    console.log(`Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)

    // This is an external deployment pulled in from @layerzerolabs/lz-evm-sdk-v2
    //
    // @layerzerolabs/toolbox-hardhat takes care of plugging in the external deployments
    // from @layerzerolabs packages based on the configuration in your hardhat config
    //
    // For this to work correctly, your network config must define an eid property
    // set to `EndpointId` as defined in @layerzerolabs/lz-definitions
    //
    // For example:
    //
    // networks: {
    //   fuji: {
    //     ...
    //     eid: EndpointId.AVALANCHE_V2_TESTNET
    //   }
    // }
    const endpointV2Deployment = await hre.deployments.get('EndpointV2')
    const constructorArgs = [
        'Omnichain Universal Principal ETH', // name
        'UETH', // symbol
        18, // decimals
        endpointV2Deployment.address, // LayerZero's EndpointV2 address
        deployer, // owner
    ];
    const { address } = await deploy(contractName, {
        from: deployer,
        args: constructorArgs,
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`)

    try {
        console.log("Verifying contract...");
        await hre.run("verify:verify", {
            address: address,
            constructorArguments: constructorArgs,
        });
        console.log(`Contract: ${contractName} verified!, network: ${hre.network.name}, address: ${address}`);
    } catch (err) {
        console.error(`Contract: ${contractName} verification failed!, network: ${hre.network.name}, address: ${address}`, err);
    }
}

deploy.tags = [contractName]

export default deploy

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

    // Verifying contract
    try {
        console.log("Verifying contract...");
        await hre.run("verify:verify", {
            address: address,
            constructorArguments: constructorArgs,
        });
        console.log(`Contract: ${contractName} on ${hre.network.name} verified!, address: ${address}`);
    } catch (err) {
        console.error(`Contract: ${contractName} on ${hre.network.name} verification failed!, address: ${address}`, err);
    }
}

deploy.tags = [contractName]

export default deploy

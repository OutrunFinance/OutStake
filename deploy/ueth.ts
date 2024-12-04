import assert from 'assert';
import { type DeployFunction } from 'hardhat-deploy/types';

const contractName = 'OutrunUniversalPrincipalToken';

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre;

    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    assert(deployer, 'Missing named deployer account');

    console.log(`Network: ${hre.network.name}`);
    console.log(`Deployer: ${deployer}`);

    const outrunDeployerAddress = '0x72e0BfFab2672B6EDDEBdC4B48f3dD2FC65520C0';
    const outrunDeployer = await hre.ethers.getContractAt('OutrunDeployer', outrunDeployerAddress);
    
    const endpointV2Deployment = await hre.deployments.get('EndpointV2');
    const constructorArgs = [
        'Omnichain Universal Principal ETH', // name
        'UETH', // symbol
        18, // decimals
        endpointV2Deployment.address, // LayerZero's EndpointV2 address
        deployer // owner
    ];

    const salt = hre.ethers.utils.id('Outrun');
    const creationCode = await hre.artifacts.readArtifact(contractName);
    const encodedArgs = hre.ethers.utils.defaultAbiCoder.encode(
        ['string', 'string', 'uint8', 'address', 'address'],
        constructorArgs
    );
    const bytecodeWithArgs = creationCode.bytecode + encodedArgs.slice(2);
    const deployTx = await outrunDeployer.deploy(salt, bytecodeWithArgs, { value: hre.ethers.utils.parseEther('0') });
    const deployedAddress = deployTx.address;

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${deployedAddress}`)

    // Verifying contract
    let count = 0;
    do {
        try {
            console.log(`Verifying contract ${contractName} on ${hre.network.name}, address: ${deployedAddress}`);
            await hre.run("verify:verify", {
                address: deployedAddress,
                constructorArguments: constructorArgs,
            });
            console.log(`Contract: ${contractName} on ${hre.network.name} verified!, address: ${deployedAddress}`);
            count = 5;
        } catch (err) {
            console.error(`Contract: ${contractName} on ${hre.network.name} verification failed!, address: ${deployedAddress}`, err);
        }
    } while (count < 5);
}

deploy.tags = [contractName]

export default deploy

// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@layerzerolabs/toolbox-hardhat'
import { HardhatUserConfig, HttpNetworkAccountsUserConfig } from 'hardhat/types'

import { EndpointId } from '@layerzerolabs/lz-definitions'

// Set your preferred authentication method
//
// If you prefer using a mnemonic, set a MNEMONIC environment variable
// to a valid mnemonic
const MNEMONIC = process.env.MNEMONIC

// If you prefer to be authenticated using a private key, set a PRIVATE_KEY environment variable
const PRIVATE_KEY = process.env.PRIVATE_KEY

const accounts: HttpNetworkAccountsUserConfig | undefined = MNEMONIC
    ? { mnemonic: MNEMONIC }
    : PRIVATE_KEY
      ? [PRIVATE_KEY]
      : undefined

if (accounts == null) {
    console.warn(
        'Could not find MNEMONIC or PRIVATE_KEY environment variables. It will not be possible to execute transactions.'
    )
}

const config: HardhatUserConfig = {
    paths: {
        sources: "src",
        tests: "test",
        cache: "cache/hardhat",
        artifacts: "artifacts"
    },
    solidity: {
        compilers: [
            {
                version: '0.8.26',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100000,
                    },
                },
            },
        ],
    },
    // Get eid from https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts
    networks: {
        'bsc-testnet': {
            eid: EndpointId.BSC_V2_TESTNET,
            url: process.env.BSC_TESTNET_RPC,
            accounts,
        },
        'base-sepolia': {
            eid: EndpointId.BASESEP_V2_TESTNET,
            url: process.env.BASE_SEPOLIA_RPC,
            accounts,
        },
        'blast-sepolia': {
            eid: EndpointId.BLAST_V2_TESTNET,
            url: process.env.BLAST_SEPOLIA_RPC,
            accounts,
        },
    },
    namedAccounts: {
        deployer: {
            default: 0xcae21365145C467F8957607aE364fb29Ee073209, // wallet address of index[0], of the mnemonic in .env
        },
    },
}

export default config

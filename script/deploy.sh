source ../.env
forge clean && forge build
forge script OutstakeScript.s.sol:OutstakeScript --rpc-url blast_sepolia --broadcast --verify --ffi -vvvv
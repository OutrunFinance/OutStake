source ../.env
forge clean && forge build
forge script OutstakeScript.s.sol:OutstakeScript --rpc-url blast_sepolia --priority-gas-price 300 --with-gas-price 1200000 --optimize --optimizer-runs 100000 --broadcast --verify --ffi -vvvv
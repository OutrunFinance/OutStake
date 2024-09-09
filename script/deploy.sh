source ../.env
forge clean && forge build
# forge script OutstakeScript.s.sol:OutstakeScript --rpc-url blast_sepolia \
#     --priority-gas-price 300 --with-gas-price 1200000 \
#     --optimize --optimizer-runs 100000 \
#     --via-ir \
#     --broadcast --ffi -vvvv \
#     --verify 

forge script OutstakeScript.s.sol:OutstakeScript --rpc-url bsc_testnet \
    --with-gas-price 4000000000 \
    --optimize --optimizer-runs 100000 \
    --via-ir \
    --broadcast --ffi -vvvv \
    --verify 
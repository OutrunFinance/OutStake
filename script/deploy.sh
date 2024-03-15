source ../.env
# forge clean && forge build
# forge create --rpc-url blast_sepolia \
# --constructor-args 0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8 0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8 0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8 0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8 100 \
# --private-key $PRIVATE_KEY \
# src/OutETHVault.sol:OutETHVault
forge script OutstakeScript.s.sol:OutstakeScript --rpc-url blast_sepolia --broadcast --verify --ffi -vvvv
# magic-shop-contracts
The 1M$ contracts that handles all the important transaction

# Instructions and CLI

Our setup API and testing network

        module.exports = {
        solidity: '0.8.4',
        networks: {
            rinkeby: {
            url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
            accounts: [`0x${RINKEBY_PRIVATE_KEY}`],
            },
        },
        etherscan: {
            // Your API key for Etherscan
            // Obtain one at https://etherscan.io/
            apiKey: ETHERSCAN_API_KEY,
        },
        };

To compile the code and retrieve the bytecodes and ABIs

        yarn hardhat compile

To deploy contract

        yarn hardhat run scripts/deployX.js --network rinkeby

To verify

        yarn hardhat verify --contract contracts/MagicShop/MagicShop.sol:MagicShop --network rinkeby 0xFAb4628f67B89bccbcd913E1c946F91f4ABF4034


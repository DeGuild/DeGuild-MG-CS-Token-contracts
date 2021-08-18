// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DeGuildCoinERC777.sol";

contract DeGuildCoin is DeGuildCoinERC777 {
    address[] arr;

    constructor()
        public
        DeGuildCoinERC777(
            "DeGuild Coin",
            "DGC",
            arr,
            100000000,
            0xAe488A5e940868bFFA6D59d9CDDb92Da11bb2cD9
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeGuildCoinERC20 is ERC20 {
    constructor() ERC20("DeGuild Coin", "DGC") {
        _mint(msg.sender, 1000000 * 10 **18);
    }
}
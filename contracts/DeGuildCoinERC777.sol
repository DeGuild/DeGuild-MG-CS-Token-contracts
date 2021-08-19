// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract DeGuildCoinERC777 is ERC777 {
    constructor() ERC777("DeGuild Coin", "DGC", new address[](0)) {
        _mint(msg.sender, 1000000 * 10 **18, "", "");
    }
}
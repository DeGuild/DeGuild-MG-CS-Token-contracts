// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Based from ERC20, this contract provide 1,000,000 DGT to the owner of this contract.
 * The decimal places is 10^18 which is the most precise.
 */

contract DeGuildCoinERC20 is ERC20 {
    constructor() ERC20("DeGuild Token", "DGT") {
        _mint(msg.sender, 1000000 * 10 **18);
    }
}
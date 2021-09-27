// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

/**
 * @dev We are not using this contract yet, since there are vulneralbilities that we cannot guard, aka reentrancy attack.
 */
contract DeGuildCoinERC777 is ERC777 {
    constructor() ERC777("DeGuild Coin", "DGC", new address[](0)) {
        _mint(msg.sender, 1000000 * 10 **18, "", "");
    }
}
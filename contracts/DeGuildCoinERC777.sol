// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract DeGuildCoinERC777 is ERC777 {
    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators,
        uint256 initialSupply,
        address owner
    ) ERC777(name, symbol, defaultOperators) {
        _mint(owner, initialSupply, "", "");
    }
}
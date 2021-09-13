// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MagicScrolls.sol";

contract MagicShop {

    string public name;
    string public owner;

    MagicScrolls public scrolls;

    constructor() {
        scrolls = new MagicScrolls();
    }
}
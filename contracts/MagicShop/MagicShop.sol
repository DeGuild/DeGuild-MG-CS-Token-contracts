// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MagicScroll.sol";

contract MagicShop {

    string public name;
    string public owner;
    address private _DGC = address(0x4312D992940D0b110525f553160c9984b77D1EF4);

    MagicScroll[] public scrolls;

    constructor() {
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MagicScrolls.sol";

contract MagicShop is MagicScrolls {
    constructor()
        MagicScrolls(
            "Mona's Magic Shop",
            "MMS",
            "https://us-central1-deguild-2021.cloudfunctions.net/shop/readMagicScroll/",
            address(0x4312D992940D0b110525f553160c9984b77D1EF4)
        )
    {}
}

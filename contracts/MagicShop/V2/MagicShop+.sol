// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MagicScrolls+.sol";
import "./IMagicScrolls+.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

contract MagicShopPlus is MagicScrollsPlus, ERC165Storage {
    constructor()
        MagicScrollsPlus(
            "Mona's Magic Shop",
            "MMS",
            "https://us-central1-deguild-2021.cloudfunctions.net/app/readMagicScroll/",
            address(0x4312D992940D0b110525f553160c9984b77D1EF4)
        )
    {
        _registerInterface(type(IMagicScrollsPlus).interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/DeGuild/V2/DeGuild+.sol";
import "./IDeGuild+.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

// starting in October.
contract DeGuildCenterPlus is DeGuildPlus, ERC165Storage {
    constructor()
        DeGuildPlus(
            "G01 Guild",
            "G01",
            "https://us-central1-deguild-2021.cloudfunctions.net/app/readJob/",
            address(0x4312D992940D0b110525f553160c9984b77D1EF4)
        )
    {
        _registerInterface(type(IDeGuildPlus).interfaceId);
    }
}

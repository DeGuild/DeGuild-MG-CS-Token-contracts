// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/DeGuild/DeGuild+.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

// starting in October.
contract DeGuildCenterPlus is DeGuildPlus {
    constructor()
        DeGuildPlus(
            "MUIC Guild",
            "MUICG",
            "https://us-central1-deguild-2021.cloudfunctions.net/app/readJob/",
            address(0x4312D992940D0b110525f553160c9984b77D1EF4)
        )
    {
        _registerInterface(type(DeGuild).interfaceId);
    }
}

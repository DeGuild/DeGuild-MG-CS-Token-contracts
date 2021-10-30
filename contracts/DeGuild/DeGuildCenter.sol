// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/DeGuild/DeGuild.sol";

// starting in October.
contract DeGuildCenter is DeGuild {

    constructor()
        DeGuild(
            "Polygon Guild",
            "PGDG",
            "https://us-central1-deguild-2021.cloudfunctions.net/public/readJob/",
            address(0x4312D992940D0b110525f553160c9984b77D1EF4)
        )
    {}

}
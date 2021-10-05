// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SkillCertificate.sol";

contract CertificateManager is SkillCertificate {
    constructor()
        SkillCertificate(
            "Introduction to Computer Programming",
            "ICCS101",
            "https://us-central1-deguild-2021.cloudfunctions.net/readCertificate/",
            address(0x706787872D518F91fB9B7a86055AB616a2C64958),
            0
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SkillCertificate.sol";

contract CertificateManager is SkillCertificate {
    constructor()
        SkillCertificate(
            "Introduction to Computer Programming",
            "ICCS101",
            "https://us-central1-deguild-2021.cloudfunctions.net/app/readCertificate/",
            address(0x1B362371f11cAA26B1A993f7Ffd711c0B9966f70),
            1
        )
    {}
}
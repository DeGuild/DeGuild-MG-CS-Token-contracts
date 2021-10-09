// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SkillCertificate.sol";

contract CertificateManager is SkillCertificate {
    constructor()
        SkillCertificate(
            "Computer Architecture",
            "ICCS324",
            "https://us-central1-deguild-2021.cloudfunctions.net/app/readCertificate/",
            address(0x09eE5D4916b0c937540F2A5a7fB2621564628Fbf),
            16
        )
    {}
}
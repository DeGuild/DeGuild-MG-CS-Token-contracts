// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SkillCertificate.sol";

contract CertificateManager is SkillCertificate {
    constructor()
        SkillCertificate(
            "Introduction to Computer Programming",
            "ICCS101",
            "https://us-central1-deguild-2021.cloudfunctions.net/app/readCertificate/",
            address(0xfE7992D9292491b3Cd7d2F3f25716c3f5f579660),
            0
        )
    {}
}

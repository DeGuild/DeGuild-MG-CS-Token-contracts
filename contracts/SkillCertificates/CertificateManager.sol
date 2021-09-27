// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SkillCertificate.sol";

contract CertificateManager is SkillCertificate {
    constructor()
        SkillCertificate(
            "Blockchain Lv.1",
            "BCM",
            "https://atlas-content1-cdn.pixelsquid.com/assets_v2/",
            address(0xe92fb62A09D32bF1b3E3b8F00Ac3CA11e891B0f1),
            0
        )
    {}
}

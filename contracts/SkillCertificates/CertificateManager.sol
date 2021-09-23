// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SkillCertificate.sol";

contract CertificateManager is SkillCertificate {
    constructor()
        SkillCertificate(
            "Blockchain Lv.1",
            "BCM",
            "https://atlas-content1-cdn.pixelsquid.com/assets_v2/",
            address(0xABfc5448A4F0544cBdA2686df2535ec11aEbD5DE),
            0
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SkillCertificate+.sol";
import "./ISkillCertificate+.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

contract CertificateManagerPlus is SkillCertificatePlus, ERC165Storage {
    constructor()
        SkillCertificatePlus(
            "Genius Manager",
            "GM",
            "https://us-central1-deguild-2021.cloudfunctions.net/app/readCertificate/",
            address(0x644e8f14A53ec9DeA89875942fB001E82dDc0CA7)
        )
    {
        _registerInterface(type(ISkillCertificatePlus).interfaceId);
    }
}
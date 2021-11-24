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
            address(0x11786516237f1c7bb3b17C9D70739655cF550cD6)
        )
    {
        _registerInterface(type(ISkillCertificatePlus).interfaceId);
    }
}
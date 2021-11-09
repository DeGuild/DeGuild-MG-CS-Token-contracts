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
            address(0x10b166e2a93f06F7b9b2c28A2d5CFab3c14987D3)
        )
    {
        _registerInterface(type(ISkillCertificatePlus).interfaceId);
    }
}
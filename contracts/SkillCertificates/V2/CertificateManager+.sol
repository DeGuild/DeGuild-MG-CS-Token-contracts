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
            address(0xC1BbF9Bd648BC0c85aF179FB0C20722f678ac31e)
        )
    {
        _registerInterface(type(ISkillCertificatePlus).interfaceId);
    }
}
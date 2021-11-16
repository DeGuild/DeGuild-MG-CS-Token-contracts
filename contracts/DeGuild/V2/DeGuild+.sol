// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDeGuild+.sol";
import "contracts/SkillCertificates/V2/ISkillCertificate+.sol";
import "contracts/Utils/EIP-55.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

// starting in October.
contract DeGuildPlus is Context, Ownable, IDeGuildPlus {
    /**
     * Libraries required, please use these!
     */
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;
    using ChecksumLib for address;
    using ERC165Checker for address;

    /**
     * @dev Classic ERC721 mapping, tracking down the scrolls existed
     * We need to know exactly what happened to the scroll
     * so we keep track of those scrolls here.
     */
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _currentJob;
    mapping(address => bool) private _occupied;

    /**
     * @dev This mapping store all scrolls.
     */
    mapping(uint256 => Job) private _JobsCreated;

    /**
     * @dev Store the address of Deguild Token
     */
    address private _addressDGT;
    string private _name;
    string private _symbol;
    string private _baseURIscroll;

    /**
     * @dev Store the ID of scrolls and types
     */
    Counters.Counter private tracker = Counters.Counter(1);

    /**
     * @dev Store the interface of Deguild Token
     */
    IERC20 private _DGT;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address addressDGT_
    ) {
        _name = name_;
        _symbol = symbol_;
        _addressDGT = addressDGT_;
        _baseURIscroll = baseURI_;
        _DGT = IERC20(addressDGT_);
    }

    /**
     * @dev See {IMagicScrolls-name}.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IMagicScrolls-symbol}.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IMagicScrolls-tokenURI}.
     */
    function jobURI(uint256 jobId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(jobId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        abi.encodePacked(baseURI, address(this).getChecksum()),
                        abi.encodePacked("/", jobId.toString())
                    )
                )
                : "";
    }

    /**
     * @dev See {IMagicScrolls-numberOfScrollTypes}.
     */
    function jobsCount() external view virtual override returns (uint256) {
        return tracker.current() - 1;
    }

    /**
     * @dev See {IMagicScrolls-deguildCoin}.
     */
    function deguildCoin() external view virtual override returns (address) {
        return _addressDGT;
    }

    /**
     * @dev See {IMagicScrolls-ownerOf}.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownersOf(uint256 jobId)
        public
        view
        virtual
        override
        returns (address, address)
    {
        require(_exists(jobId), "ERC721: owner query for nonexistent token");
        return (_JobsCreated[jobId].client, _JobsCreated[jobId].taker);
    }

    function isQualified(uint256 jobId, address taker)
        public
        view
        virtual
        override
        returns (bool)
    {
        require(_exists(jobId), "ERC721: owner query for nonexistent token");

        address[] memory certificates = _JobsCreated[jobId].certificates;
        uint256[][] memory skills = _JobsCreated[jobId].skills;

        for (uint256 i = 0; i < certificates.length; i++) {
            address certificate = certificates[i];
            for (uint256 j = 0; j < skills[i].length; j++) {
                if (
                    !ISkillCertificatePlus(certificate).verify(
                        taker,
                        skills[i][j]
                    )
                ) {
                    return false;
                }
            }
        }

        return true;
    }

    function jobInfo(uint256 jobId)
        public
        view
        virtual
        override
        returns (
            uint256,
            address,
            address,
            address[] memory,
            uint256[][] memory,
            uint8,
            uint8
        )
    {
        require(_exists(jobId), "ERC721: owner query for nonexistent token");

        Job memory info = _JobsCreated[jobId];
        return (
            info.reward,
            info.client,
            info.taker,
            info.certificates,
            info.skills,
            info.state,
            info.difficulty
        );
    }

    function jobOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(_occupied[account], "This account is free to work");
        return _currentJob[account];
    }

    function forceCancel(uint256 id)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        require(
            _JobsCreated[id].state != 99 && _JobsCreated[id].state != 3,
            "Already cancelled or completed"
        );
        require(
            _DGT.transfer(_owners[id], _JobsCreated[id].reward),
            "Not enough fund"
        );

        _JobsCreated[id].state = 99;
        _occupied[_JobsCreated[id].taker] = false;
        _owners[id] = address(0);

        return true;
    }

    function cancel(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        require(
            _JobsCreated[id].client == _msgSender(),
            "Only client can cancel this job!"
        );
        require(_JobsCreated[id].state == 1, "This job is already taken!");
        require(
            _DGT.transfer(_owners[id], _JobsCreated[id].reward),
            "Not enough fund"
        );

        _JobsCreated[id].state = 99;
        _owners[id] = address(0);

        return true;
    }

    function take(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        require(
            _msgSender() != _JobsCreated[id].client,
            "Abusing job taking is not allowed!"
        );
        require(isQualified(id, _msgSender()), "You are not qualified!");
        require(!_occupied[_msgSender()], "You are already occupied!");
        require(
            _JobsCreated[id].state == 1,
            "This job is not availble to be taken!"
        );
        if (_JobsCreated[id].assigned) {
            require(
                _JobsCreated[id].taker == _msgSender(),
                "Assigned person is not you"
            );
        } else {
            _JobsCreated[id].taker = _msgSender();
        }

        _occupied[_msgSender()] = true;
        _currentJob[_msgSender()] = id;
        _JobsCreated[id].state = 2;
        return true;
    }

    function complete(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        require(
            _JobsCreated[id].state == 2,
            "This job is not availble to be completed!"
        );
        require(
            _JobsCreated[id].client == _msgSender(),
            "Only client can complete this job!"
        );

        require(
            _DGT.transfer(_JobsCreated[id].taker, _JobsCreated[id].reward),
            "Not enough fund"
        );

        _JobsCreated[id].state = 3;
        _owners[id] = _JobsCreated[id].taker;
        _occupied[_JobsCreated[id].taker] = false;

        emit JobCompleted(id, _JobsCreated[id].taker);

        return true;
    }

    function report(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        require(
            _JobsCreated[id].state == 2,
            "This job is not availble to be reported!"
        );
        require(
            _JobsCreated[id].client == _msgSender() ||
                _JobsCreated[id].taker == _msgSender(),
            "Only stakeholders can report this job!"
        );

        uint256 fee = _JobsCreated[id].reward / 10;
        require(_DGT.transfer(owner(), fee), "Not enough fund");

        unchecked {
            _JobsCreated[id].reward = _JobsCreated[id].reward - fee;
        }
        _JobsCreated[id].state = 0;
        _owners[id] = owner();

        return true;
    }

    function judge(uint256 id, bool decision)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        require(
            _JobsCreated[id].state == 0,
            "This job is not availble to be judged!"
        );

        address winner;
        address loser;
        if (decision) {
            winner = _JobsCreated[id].client;
            loser = _JobsCreated[id].taker;
        } else {
            winner = _JobsCreated[id].taker;
            loser = _JobsCreated[id].client;
        }

        require(
            _DGT.transfer(winner, _JobsCreated[id].reward),
            "Not enough fund"
        );
        emit JobCaseClosed(id, loser);
        _occupied[_JobsCreated[id].taker] = false;

        return true;
    }

    function verifySkills(
        address[] memory certificates,
        uint256[][] memory skills
    ) public view virtual override returns (bool) {
        for (uint256 i = 0; i < certificates.length; i++) {
            address certificateManager = certificates[i];
            if (
                !certificateManager.supportsInterface(
                    type(ISkillCertificatePlus).interfaceId
                )
            ) {
                return false;
            }
            require(skills[i].length < 20, "Too many skills required");
            for (uint256 j = 0; j < skills[i].length; j++) {
                if (
                    skills[i][j] >=
                    ISkillCertificatePlus(certificateManager).typesExisted()
                ) {
                    return false;
                }
            }
        }
        return true;
    }

    function addJob(
        uint256 bonus,
        address taker,
        address[] memory certificates,
        uint256[][] memory skills,
        uint8 difficulty
    ) public virtual override returns (bool) {
        require(_msgSender() != taker, "Abusing job taking is not allowed!");

        require(
            certificates.length < 30,
            "Please keep your requirement certificates addresses under 30 address"
        );

        require(
            skills.length == certificates.length,
            "Sizes of skills array and certificates array are not equal"
        );

        require(
            verifySkills(certificates, skills),
            "All skills must support our interface"
        );
        uint256 wage;
        unchecked {
            wage = ((difficulty * difficulty * 100) + bonus) * 1 ether;
        }
        require(
            _DGT.transferFrom(_msgSender(), address(this), wage),
            "Not enough fund"
        );

        _JobsCreated[tracker.current()] = Job({
            reward: wage,
            client: _msgSender(),
            taker: taker,
            state: 1,
            certificates: certificates,
            skills: skills,
            difficulty: difficulty,
            assigned: taker != address(0)
        });
        _owners[tracker.current()] = _msgSender();
        emit JobAdded(
            tracker.current(),
            _JobsCreated[tracker.current()].client
        );
        tracker.increment();

        return true;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseURIscroll;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
}

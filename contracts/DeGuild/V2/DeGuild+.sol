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
     * @dev Classic ERC721 mapping, tracking down whether the job is existed
     * We need to know exactly what happened to the user also,
     * so we are keeping track of employment.
     * Also, we have a banlist.
     */
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _currentJob;
    mapping(address => bool) private _banned;

    /**
     * @dev Tracking down the jobs existed
     * We need to know exactly what happened to the job
     * so we keep track of those jobs here.
     */
    mapping(uint256 => Job) private _JobsCreated;

    /**
     * @dev Store the address of Deguild Token
     */
    address private _addressDGT;

    /**
     * @dev Store the name of this contract
     */
    string private _name;

    /**
     * @dev Store the symbol of this contract
     */
    string private _symbol;

    /**
     * @dev Store the base URI of every job
     */
    string private _baseURIscroll;

    /**
     * @dev Store the ID of job, starting at 1 (0 reserved for unemployed)
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
     * @dev See {IDeGuildPlus-name}.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IDeGuildPlus-symbol}.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IDeGuildPlus-jobURI}.
     *
     * Requirements:
     *
     * - `jobId` cannot be non-existence token.
     *
     * Error messages
     * A0 - "IDeGuildPlus: URI query for nonexistent job"
     */
    function jobURI(uint256 jobId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(jobId), "IDeGuildPlus: A0");

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
     * @dev See {IDeGuildPlus-jobsCount}.
     */
    function jobsCount() external view virtual override returns (uint256) {
        return tracker.current() - 1;
    }

    /**
     * @dev See {IDeGuildPlus-deguildCoin}.
     */
    function deguildCoin() external view virtual override returns (address) {
        return _addressDGT;
    }

    /**
     * @dev See {IDeGuildPlus-ownersOf}.
     *
     * Requirements:
     *
     * - `id` must exist.
     *
     * Error messages
     * A0 - "IDeGuildPlus: URI query for nonexistent job"
     */
    function ownersOf(uint256 jobId)
        public
        view
        virtual
        override
        returns (address, address)
    {
        require(_exists(jobId), "IDeGuildPlus: A0");
        return (_JobsCreated[jobId].client, _JobsCreated[jobId].taker);
    }

    /**
     * @dev See {IDeGuildPlus-jobOf}.
     */
    function jobOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _currentJob[account];
    }

    /**
     * @dev See {IDeGuildPlus-isQualified}.
     *
     * Requirements:
     *
     * - `jobId` must exist.
     *
     * Error messages
     * A0 - "IDeGuildPlus: URI query for nonexistent job"
     */
    function isQualified(uint256 jobId, address taker)
        public
        view
        virtual
        override
        returns (bool)
    {
        require(_exists(jobId), "IDeGuildPlus: A0");

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

    /**
     * @dev See {IDeGuildPlus-jobInfo}.
     *
     * Requirements:
     *
     * - `jobId` must exist.
     *
     * Error messages
     * A0 - "IDeGuildPlus: URI query for nonexistent job"
     */
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
        require(_exists(jobId), "IDeGuildPlus: A0");

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

    /**
     * @dev See {IDeGuildPlus-verifySkills}.
     *
     * Requirements:
     *
     * - `certificates` must support the interface of ISkillCertificatePlus (ERC165).
     * - `skills` element cannot have more than 20 sub-elements (skills[0].length < 20).
     * - `skills` length must be equal to `certificates`.
     * - `certificates` array length must be less than 30.
     *
     * Error messages
     * C1 - "IDeGuildPlus: requirement certificate addresses larger than 30 address"
     * S1 - "IDeGuildPlus: sizes of skill array and certificate array are not equal"
     * SK - "IDeGuildPlus: more than 20 skills required for one certificate address"
     
     */
    function verifySkills(
        address[] memory certificates,
        uint256[][] memory skills
    ) public view virtual override returns (bool) {
        require(certificates.length < 30, "IDeGuildPlus: C1");

        require(skills.length == certificates.length, "IDeGuildPlus: S1");

        for (uint256 i = 0; i < certificates.length; i++) {
            address certificateManager = certificates[i];
            if (
                !certificateManager.supportsInterface(
                    type(ISkillCertificatePlus).interfaceId
                )
            ) {
                return false;
            }
            require(skills[i].length < 20, "IDeGuildPlus: SK");
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

    /**
     * @dev See {IDeGuildPlus-forceCancel}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of deGuild.
     * - `id` state must not be 99 or 3 (neither cancelled or completed).
     * - This contract has enough money to return all the reward of `id`.
     *
     * Error messages
     * A0 - "IDeGuildPlus: owner query for nonexistent token"
     * J0 - "IDeGuildPlus: this job is not availble to be judged"
     * NTR - "IDeGuildPlus: not enough fund to return reward"
     */
    function forceCancel(uint256 id)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(_exists(id), "IDeGuildPlus: A0");
        require(_JobsCreated[id].state == 0, "IDeGuildPlus: J0");
        require(
            _DGT.transfer(_owners[id], _JobsCreated[id].reward),
            "IDeGuildPlus: NTR"
        );

        _JobsCreated[id].state = 99;
        _currentJob[_JobsCreated[id].taker] = 0;
        _owners[id] = address(0);

        return true;
    }

    /**
     * @dev See {IDeGuildPlus-cancel}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the client.
     * - `id` state must be 1 (available).
     * - This contract has enough money to return all the reward of `id`.
     *
     * Error messages
     * A0 - "IDeGuildPlus: owner query for nonexistent token"
     * NC - "IDeGuildPlus: only client can cancel this job"
     * J1 - "IDeGuildPlus: this job is already taken"
     * NTR - "IDeGuildPlus: not enough fund to return reward"
     */
    function cancel(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "IDeGuildPlus: A0");
        require(_JobsCreated[id].client == _msgSender(), "IDeGuildPlus: NC");
        require(_JobsCreated[id].state == 1, "IDeGuildPlus: J1");
        require(
            _DGT.transfer(_owners[id], _JobsCreated[id].reward),
            "IDeGuildPlus: NTR"
        );

        _JobsCreated[id].state = 99;
        _owners[id] = address(0);

        return true;
    }

    /**
     * @dev See {IDeGuildPlus-take}.
     *
     * Requirements:
     *
     * - The caller must not be banned.
     * - `id` must exist.
     * - The caller cannot be the job's client.
     * - The caller must pass the qualification (might take longer as the skills are required).
     * - The caller must not have any job ongoing.
     * - `id` state must be 1 (available).
     * - If the job is assigned, the taker must be the same as the caller
     *
     * Error messages
     * BC - "IDeGuildPlus: caller has been banned"
     * A0 - "IDeGuildPlus: owner query for nonexistent token"
     * CC - "IDeGuildPlus: caller cannot be client"
     * NQ - "IDeGuildPlus: caller is not qualified"
     * NA - "IDeGuildPlus: caller is already occupied"
     * NC - "IDeGuildPlus: only client can cancel this job"
     * J1 - "IDeGuildPlus: this job is already taken"
     * WT - "IDeGuildPlus: assigned address is not the caller"
     */
    function take(uint256 id) public virtual override returns (bool) {
        require(!_banned[_msgSender()], "IDeGuildPlus: BC");

        require(_exists(id), "IDeGuildPlus: A0");
        require(_msgSender() != _JobsCreated[id].client, "IDeGuildPlus: CC");
        require(isQualified(id, _msgSender()), "IDeGuildPlus: NQ");
        require(_currentJob[_msgSender()] == 0, "IDeGuildPlus: NA");
        require(_JobsCreated[id].state == 1, "IDeGuildPlus: J1");
        if (_JobsCreated[id].assigned) {
            require(_JobsCreated[id].taker == _msgSender(), "IDeGuildPlus: WT");
        } else {
            _JobsCreated[id].taker = _msgSender();
        }

        _currentJob[_msgSender()] = id;
        _JobsCreated[id].state = 2;
        emit JobTaken(id, _JobsCreated[id].taker);

        return true;
    }

    /**
     * @dev See {IDeGuildPlus-complete}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - `id` state must be 2 (available).
     * - The caller must be the job's client.
     * - This contract must have enough fund to transfer fees.
     * - This contract must have enough fund to transfer rewards.
     *
     * Error messages
     * A0 - "IDeGuildPlus: owner query for nonexistent token"
     * J2 - "IDeGuildPlus: this job is not availble to be completed"
     * MC - "IDeGuildPlus: only client can complete this job"
     * NTF - "IDeGuildPlus: not enough fund to transfer fees"
     * NTR - "IDeGuildPlus: not enough fund to return reward"
     */
    function complete(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "IDeGuildPlus: A0");
        require(_JobsCreated[id].state == 2, "IDeGuildPlus: J2");
        require(_JobsCreated[id].client == _msgSender(), "IDeGuildPlus: MC");

        uint256 fee = (_JobsCreated[id].reward * 125) / 10000;
        require(_DGT.transfer(owner(), fee), "IDeGuildPlus: NTF");

        unchecked {
            _JobsCreated[id].reward = _JobsCreated[id].reward - fee;
        }

        require(
            _DGT.transfer(_JobsCreated[id].taker, _JobsCreated[id].reward),
            "IDeGuildPlus: NTR"
        );

        _JobsCreated[id].state = 3;
        _currentJob[_JobsCreated[id].taker] = 0;

        emit JobCompleted(id, _JobsCreated[id].taker);

        return true;
    }

    /**
     * @dev See {IDeGuildPlus-report}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - `id` state must be 2 (available).
     * - The caller must be the job's client or taker.
     *
     * Error messages
     * A0 - "IDeGuildPlus: owner query for nonexistent token"
     * J2 - "IDeGuildPlus: this job is not availble to be completed"
     * SOS - "IDeGuildPlus: only stakeholders can report this job"
     */
    function report(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "IDeGuildPlus: A0");
        require(_JobsCreated[id].state == 2, "IDeGuildPlus: J2");
        require(
            _JobsCreated[id].client == _msgSender() ||
                _JobsCreated[id].taker == _msgSender(),
            "IDeGuildPlus: SOS"
        );

        _JobsCreated[id].state = 0;
        emit JobCaseOpened(id);

        return true;
    }

    /**
     * @dev See {IDeGuildPlus-judge}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - `id` state must be 0 (investigating).
     * - the caller must be the owner of this contract
     * - This contract must have enough fund to transfer fees.
     * - This contract must have enough fund to transfer rewards.
     *
     * Error messages
     * A0 - "IDeGuildPlus: owner query for nonexistent token"
     * OF - "IDeGuildPlus: fee rate too large"
     * OC - "IDeGuildPlus: client rate too large"
     * OT - "IDeGuildPlus: taker rate too large"
     * 100 - "IDeGuildPlus: sum of rates is not 100%"
     * J0 - "IDeGuildPlus: this job is not availble to be judged"
     * MC - "IDeGuildPlus: only client can complete this job"
     * NTF - "IDeGuildPlus: not enough fund to transfer fees"
     * NTC - "IDeGuildPlus: not enough fund to transfer reward to client"
     * NTT - "IDeGuildPlus: not enough fund to transfer reward to taker"
     */
    function judge(
        uint256 id,
        bool decision,
        bool isCompleted,
        uint256 feeRate,
        uint256 clientRate,
        uint256 takerRate
    ) public virtual override onlyOwner returns (bool) {
        require(_exists(id), "IDeGuildPlus: A0");
        require(feeRate < 10000, "IDeGuildPlus: OF");
        require(clientRate < 10000, "IDeGuildPlus: OC");
        require(takerRate < 10000, "IDeGuildPlus: OT");
        require(feeRate + clientRate + takerRate == 10000, "IDeGuildPlus: 100");
        require(_JobsCreated[id].state == 0, "IDeGuildPlus: J0");

        uint256 fee;
        uint256 clientReturn;
        uint256 takerReturn;
        unchecked {
            fee = (_JobsCreated[id].reward * feeRate) / 10000;
            clientReturn = (_JobsCreated[id].reward * clientRate) / 10000;
            takerReturn = (_JobsCreated[id].reward * takerRate) / 10000;
        }
        require(_DGT.transfer(owner(), fee), "IDeGuildPlus: NTF");
        require(
            _DGT.transfer(_JobsCreated[id].client, clientReturn),
            "IDeGuildPlus: NTC"
        );
        require(
            _DGT.transfer(_JobsCreated[id].taker, takerReturn),
            "IDeGuildPlus: NTT"
        );
        unchecked {
            _JobsCreated[id].reward = _JobsCreated[id].reward - fee;
        }
        _currentJob[_JobsCreated[id].taker] = 0;
        if (isCompleted) {
            _JobsCreated[id].state = 3;
            emit JobCompleted(id, _JobsCreated[id].taker);
            if (decision) {
                _banned[_JobsCreated[id].client] = true;
                emit JobCaseClosed(id, _JobsCreated[id].client);
            } else {
                emit JobCaseClosed(id, address(0));
            }
        } else {
            _JobsCreated[id].state = 1;
            _JobsCreated[id].taker = address(0);
            _JobsCreated[id].assigned = false;
            if (decision) {
                _banned[_JobsCreated[id].taker] = true;
                emit JobCaseClosed(id, _JobsCreated[id].taker);
            } else {
                emit JobCaseClosed(id, address(0));
            }
        }

        return true;
    }

    /**
     * @dev See {IDeGuildPlus-addJob}.
     *
     * Requirements:
     *
     * - The caller must not be banned.
     * - The caller cannot set taker to be the caller.
     * - The skills must pass the verification (might take longer if the number of skills is large).
     * - This caller must have enough fund to transfer rewards.
     *
     * Error messages
     * BC       - "IDeGuildPlus: caller has been banned"
     * A0       - "IDeGuildPlus: owner query for nonexistent token"
     * ZT       - "IDeGuildPlus: caller cannot assign this taker address to this job"
     * ERC165   - "IDeGuildPlus: all skills must support ISkillCertificatePlus interface"
     * TR0      - "IDeGuildPlus: not enough fund to trasfer reward"
     */
    function addJob(
        uint256 bonus,
        address taker,
        address[] memory certificates,
        uint256[][] memory skills,
        uint8 difficulty
    ) public virtual override returns (bool) {
        require(!_banned[_msgSender()], "IDeGuildPlus: BC");
        require(_msgSender() != taker, "IDeGuildPlus: ZT");

        require(verifySkills(certificates, skills), "IDeGuildPlus: ERC165");
        uint256 wage;
        unchecked {
            wage =
                ((uint256(difficulty) * uint256(difficulty) * 100) + bonus) *
                1 ether;
        }
        require(
            _DGT.transferFrom(_msgSender(), address(this), wage),
            "IDeGuildPlus: TR0"
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

    /**
     * @dev Token exists if the owner is not address(0) (burned)
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
}

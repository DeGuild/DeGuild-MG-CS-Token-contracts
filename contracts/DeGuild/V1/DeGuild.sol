// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/DeGuild/IDeGuild.sol";
import "../SkillCertificates/ISkillCertificate.sol";
import "../Utils/EIP-55.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// starting in October.
contract DeGuild is Context, Ownable, IDeGuild {
    /**
     * Libraries required, please use these!
     */
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;
    using ChecksumLib for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Classic ERC721 mapping, tracking down the scrolls existed
     * We need to know exactly what happened to the scroll
     * so we keep track of those scrolls here.
     */
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _currentJob;
    mapping(address => uint256) private _exp;
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
    Counters.Counter private tracker = Counters.Counter(0);

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
        return tracker.current();
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
        returns (address[] memory)
    {
        require(_exists(jobId), "ERC721: owner query for nonexistent token");

        address[] memory owners = new address[](2);

        owners[0] = _owners[jobId];
        owners[1] = _JobsCreated[jobId].taker;
        // return [owner];
        return owners;
    }

    function isQualified(uint256 jobId, address taker)
        public
        view
        virtual
        override
        returns (bool)
    {
        require(_exists(jobId), "ERC721: owner query for nonexistent token");

        address[] memory skills = _JobsCreated[jobId].skills;

        for (uint256 index = 0; index < skills.length; index++) {
            address skill = skills[index];
            bool confirm = ISkillCertificate(skill).verify(taker);
            if (!confirm) {
                return false;
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
            uint256,
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
            info.skills,
            info.deadline,
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
        return _currentJob[account];
    }

    function expOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _exp[account];
    }

    function forceCancel(uint256 id)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        Job memory job = _JobsCreated[id];
        require(
            job.state != 99 && job.state != 3,
            "Already cancelled or completed"
        );
        require(
            _DGT.transferFrom(address(this), _owners[id], job.reward),
            "Not enough fund"
        );

        job.state = 99;
        _occupied[job.taker] = false;

        emit StateChanged(id, 99);
        return true;
    }

    function cancel(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        Job memory job = _JobsCreated[id];
        require(job.client == _msgSender(), "Only client can cancel this job!");
        require(job.state == 1, "This job is already taken!");
        require(
            _DGT.transferFrom(address(this), _owners[id], job.reward),
            "Not enough fund"
        );

        job.state = 99;

        emit StateChanged(id, 99);
        return true;
    }

    function take(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        Job memory job = _JobsCreated[id];
        require(
            _msgSender() != job.client,
            "Abusing job taking is not allowed!"
        );
        require(isQualified(id, _msgSender()), "You are not qualified!");
        require(!_occupied[_msgSender()], "You are already occupied!");
        require(job.state == 1, "This job is not availble to be taken!");
        if (job.assigned) {
            require(job.taker == _msgSender(), "Assigned person is not you");
        } else {
            job.taker = _msgSender();
        }

        _occupied[_msgSender()] = true;
        _currentJob[_msgSender()] = id;
        job.state = 2;
        emit StateChanged(id, 2);

        return true;
    }

    function complete(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        Job memory job = _JobsCreated[id];

        require(job.state == 2, "This job is not availble to be completed!");
        require(
            job.client == _msgSender(),
            "Only client can complete this job!"
        );

        require(
            _DGT.transferFrom(
                address(this),
                _JobsCreated[id].taker,
                _JobsCreated[id].reward
            ),
            "Not enough fund"
        );
        unchecked {
            _exp[job.taker] += job.difficulty * 100;
            _exp[job.client] += job.difficulty * 10;
        }

        job.state = 3;
        _owners[id] = job.taker;
        _occupied[job.taker] = false;

        emit StateChanged(id, 3);

        return true;
    }

    function report(uint256 id) public virtual override returns (bool) {
        require(_exists(id), "ERC721: owner query for nonexistent token");
        Job memory job = _JobsCreated[id];

        require(job.state == 2, "This job is not availble to be reported!");
        require(job.deadline <= block.timestamp, "Report after deadline only!");
        require(
            job.client == _msgSender() || job.taker == _msgSender(),
            "Only stakeholders can report this job!"
        );

        uint256 fee = _JobsCreated[id].reward / 10;
        require(
            _DGT.transferFrom(address(this), owner(), fee),
            "Not enough fund"
        );

        unchecked {
            _JobsCreated[id].reward = _JobsCreated[id].reward - fee;
        }
        _JobsCreated[id].state = 0;
        _owners[id] = owner();
        emit StateChanged(id, 0);

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
        Job memory job = _JobsCreated[id];

        require(job.state == 0, "This job is not availble to be judged!");

        address winner;
        if (decision) {
            winner = _JobsCreated[id].client;
            unchecked {
                _exp[job.client] += job.difficulty * 10;
            }
        } else {
            winner = _JobsCreated[id].taker;
            unchecked {
                _exp[job.taker] += job.difficulty * 100;
            }
        }

        require(
            _DGT.transferFrom(address(this), winner, _JobsCreated[id].reward),
            "Not enough fund"
        );
        _occupied[job.taker] = false;

        return true;
    }

    function verifySkills(address[] memory skills) public view returns (bool) {
        for (uint256 index = 0; index < skills.length; index++) {
            address skill = skills[index];
            bool confirm = skill.isContract();
            if (!confirm) {
                return false;
            }
        }
        return true;
    }

    function addJob(
        uint256 bonus,
        address taker,
        address[] memory skills,
        uint256 duration,
        uint8 difficulty
    ) public virtual override returns (bool) {
        require(_msgSender() != taker, "Abusing job taking is not allowed!");

        require(
            skills.length < 500,
            "Please keep your requirement skills under 1000 skills"
        );
        require(verifySkills(skills), "All skills must support our interface");

        uint256 level = 0;
        uint256 wage = 0;

        if (difficulty == 5) {
            level = 100;
            wage = 2000;
        } else if (difficulty == 4) {
            level = 75;
            wage = 1000;
        } else if (difficulty == 3) {
            level = 50;
            wage = 500;
        } else if (difficulty == 2) {
            level = 25;
            wage = 100;
        } else {
            level = 0;
            wage = 10;
        }
        unchecked {
            wage += bonus;
        }

        wage = wage * 1 ether;

        require(
            _DGT.transferFrom(_msgSender(), address(this), wage),
            "Not enough fund"
        );

        _JobsCreated[tracker.current()] = Job({
            reward: wage,
            client: _msgSender(),
            taker: taker,
            state: 1,
            skills: skills,
            deadline: block.timestamp + (duration * 1 days),
            level: level,
            difficulty: difficulty,
            assigned: taker == address(0)
        });
        _owners[tracker.current()] = _msgSender();
        emit JobAdded(
            tracker.current(),
            _JobsCreated[tracker.current()].reward,
            _JobsCreated[tracker.current()].client,
            _JobsCreated[tracker.current()].taker,
            _JobsCreated[tracker.current()].skills,
            _JobsCreated[tracker.current()].deadline,
            _JobsCreated[tracker.current()].level,
            _JobsCreated[tracker.current()].state,
            _JobsCreated[tracker.current()].difficulty,
            _JobsCreated[tracker.current()].assigned
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

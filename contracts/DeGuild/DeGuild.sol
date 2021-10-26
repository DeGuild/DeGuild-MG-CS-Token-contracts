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
    mapping(address => uint256) private _levels;

    mapping(address => uint256[]) private _jobsDone;
    mapping(address => bool) private _appraisers;
    EnumerableSet.AddressSet private _skillList;

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
        returns (bool)
    {
        require(_exists(jobId), "ERC721: owner query for nonexistent token");

        address[] memory skills = _skillList.values();

        for (uint256 index = 0; index < _skillList.length(); index++) {
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

    function jobOf(address account) public view returns (uint256) {
        require(account != address(0), "Querying on non-exist account");
        return _currentJob[account];
    }

    function jobsCompleted(address account)
        public
        view
        returns (uint256[] memory)
    {
        return _jobsDone[account];
    }

    function forceCancel(uint256 id) public onlyOwner returns (bool) {
        require(_exists(id), "Nonexistent token");
        require(
            _DGT.transfer(_owners[id], _JobsCreated[id].reward),
            "Not enough fund"
        );

        _JobsCreated[id].state = 99;
        emit StateChanged(id, 99);
        return true;
    }

    function take(uint256 id) public returns (bool) {
        require(_exists(id), "Nonexistent token");
        require(isQualified(id, _msgSender()), "Nonexistent token");
        _JobsCreated[id].state = 2;
        _JobsCreated[id].taker = _msgSender();

        emit StateChanged(id, 2);

        return true;
    }

    function complete(uint256 id) public returns (bool) {
        require(_exists(id), "Nonexistent token");
        require(
            _DGT.transfer(_JobsCreated[id].taker, _JobsCreated[id].reward),
            "Not enough fund"
        );

        _JobsCreated[id].state = 3;
        _owners[id] = _JobsCreated[id].taker;
        emit StateChanged(id, 3);

        return true;
    }

    function report(uint256 id) public returns (bool) {
        require(_exists(id), "Nonexistent token");
        uint256 fee = _JobsCreated[id].reward / 10;
        require(_DGT.transfer(owner(), fee), "Not enough fund");

        _JobsCreated[id].reward = _JobsCreated[id].reward - fee;
        _JobsCreated[id].state = 99;
        _owners[id] = owner();
        emit StateChanged(id, 99);

        return true;
    }

    function judge(uint256 id, uint8 decision) public returns (bool) {
        require(_exists(id), "Nonexistent token");

        address winner;
        if (decision > 0) {
            winner = _JobsCreated[id].client;
        } else {
            winner = _JobsCreated[id].taker;
        }

        require(
            _DGT.transfer(winner, _JobsCreated[id].reward),
            "Not enough fund"
        );

        return true;
    }

    function addJob(
        uint256 reward,
        address client,
        address taker,
        address[] memory skills,
        uint256 deadline,
        uint8 difficulty
    ) public returns (bool) {
        uint256 level = 0;

        if (difficulty == 5) {
            level = 100;
            reward += 1000;
        } else if (difficulty == 4) {
            level = 75;
            reward += 1000;
        } else if (difficulty == 3) {
            level = 50;
        } else if (difficulty == 2) {
            level = 25;
        } else {
            level = 0;
        }

        _JobsCreated[tracker.current()] = Job({
            reward: reward,
            client: client,
            taker: taker,
            state: 1,
            skills: skills,
            deadline: deadline,
            level: level,
            difficulty: difficulty
        });
        tracker.increment();

        return true;
    }

    function appraise(address user) public returns (bool) {
        address[] memory skills = _skillList.values();
        uint256 level = 0;

        for (uint256 index = 0; index < _skillList.length(); index++) {
            address skill = skills[index];
            bool confirm = ISkillCertificate(skill).verify(user);
            if (confirm) {
                level+=1;
            }
        }

        _levels[user] = level + _jobsDone[user].length;
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

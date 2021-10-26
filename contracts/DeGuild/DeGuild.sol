// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/DeGuild/IDeGuild.sol";
import "../Utils/EIP-55.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// starting in October.
contract DeGuild is Context, Ownable, IDeGuild {
    /**
     * Libraries required, please use these!
     */
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;
    using ChecksumLib for address;

    /**
     * @dev Classic ERC721 mapping, tracking down the scrolls existed
     * We need to know exactly what happened to the scroll
     * so we keep track of those scrolls here.
     */
    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _level;

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
    function ownersOf(uint256 id)
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        address[] memory owners = new address[](2);
        // owners[0] = _owners[id];
        // owners[0] = _owners[id];

        // require(
        //     owner != address(0),
        //     "ERC721: owner query for nonexistent token"
        // );
        // return [owner];
        return owners;
    }

    function isQualified(uint256 jobId, address taker)
        external
        view
        returns (bool)
    {
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
        return 0;
    }

    function jobsCompleted(address account)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory a = new uint256[](4);
        return a;
    }

    function forceCancel(uint256 id) public returns (bool) {
        return true;
    }

    function take(uint256 id) public returns (bool) {
        return true;
    }

    function complete(uint256 id) public returns (bool) {
        return true;
    }

    function addJob(
        uint256 reward,
        address client,
        address taker,
        address[] memory skills,
        uint256 deadline
    ) public returns (bool) {
        return true;
    }

    function appraise() public returns (bool) {
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

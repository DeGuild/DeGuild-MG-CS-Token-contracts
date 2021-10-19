// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SkillCertificates/ISkillCertificate.sol";
import "./IMagicScrolls.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MagicScrolls is Context, Ownable, IMagicScrolls {
    /**
     * Libraries required, please use these!
     */
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;

    /**
     * @dev Classic ERC721 mapping, tracking down the scrolls existed
     * We need to know exactly what happened to the scroll
     * so we keep track of those scrolls here.
     */
    mapping(uint256 => address) private _owners;

    /**
     * @dev This mapping store all scrolls.
     */
    mapping(uint256 => MagicScroll) private _scrollCreated;

    /**
     * @dev This mapping store just scroll types.
     */
    mapping(uint256 => MagicScroll) private _scrollTypes;

    /**
     * @dev Classic ERC1155 mapping, tracking down the balances of each address
     * Given a scroll type and an address, we know the quantity!
     */
    mapping(uint256 => mapping(address => uint256)) private _balances;

    /**
     * @dev This mapping handles permission to use burn().
     */
    mapping(address => bool) private _certificateManagers;

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
    Counters.Counter private variations = Counters.Counter(0);

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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 tokenType = _scrollCreated[tokenId].scrollID;
        return tokenTypeURI(tokenType);
    }

    /**
     * @dev See {IMagicScrolls-tokenURI}.
     */
    function tokenTypeURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _existsType(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        abi.encodePacked(baseURI, _getChecksum(address(this))),
                        abi.encodePacked("/", tokenId.toString())
                    )
                )
                : "";
    }

    /**
     * @dev See {IMagicScrolls-numberOfScrollTypes}.
     */
    function numberOfScrollTypes()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return variations.current();
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
    function ownerOf(uint256 id)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[id];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IMagicScrolls-balanceOfOne}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOfOne(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IMagicScrolls-balanceOfAll}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOfAll(address account)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](variations.current());

        for (uint256 i = 0; i < variations.current(); ++i) {
            batchBalances[i] = balanceOfOne(account, i);
        }

        return batchBalances;
    }

    /**
     * @dev See {IMagicScrolls-balanceUserOwned}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceUserOwned(address account)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256 balances = 0;

        for (uint256 i = 0; i < tracker.current(); i++) {
            if (_owners[i] == account) {
                balances++;
            }
        }

        uint256[] memory ownedBalances = new uint256[](balances);

        for (uint256 i = tracker.current() - 1; i > 0; i--) {
            if (_owners[i] == account) {
                ownedBalances[--balances] = i;
            }
        }
        return ownedBalances;
    }

    /**
     * @dev See {IMagicScrolls-isCertificateManager}.
     */
    function isCertificateManager(address manager)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _certificateManagers[manager];
    }

    /**
     * @dev See {IMagicScrolls-isPurchasableScroll}.
     */
    function isPurchasableScroll(uint256 scrollType, address buyer)
        public
        view
        virtual
        override
        returns (bool)
    {
        require(_existsType(scrollType), "Scroll does not exist.");
        require(
            _scrollTypes[scrollType].available,
            "This scroll type is no longer purchasable"
        );
        if (!_scrollTypes[scrollType].hasPrerequisite) {
            return true;
        } else {
            return
                ISkillCertificate(_scrollTypes[scrollType].prerequisite).verify(
                    buyer
                );
        }
    }

    /**
     * @dev See {IMagicScrolls-scrollTypes}.
     */
    function scrollTypes()
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory types;
        uint256 count = 0;

        for (uint256 i = 0; i < variations.current(); i++) {
            if (_scrollTypes[i].available) {
                count++;
            }
        }

        types = new uint256[](count);
        for (uint256 i = 0; i < variations.current(); i++) {
            if (_scrollTypes[i].available) {
                types[--count] = i;
            }
        }
        return types;
    }

    /**
     * @dev See {IMagicScrolls-scrollTypeInfo}.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function scrollTypeInfo(uint256 typeId)
        public
        view
        virtual
        override
        returns (
            uint256,
            uint256,
            address,
            bool,
            bool,
            bool
        )
    {
        require(_existsType(typeId), "This scroll type does not exist");
        MagicScroll memory scroll = _scrollTypes[typeId];
        return (
            typeId,
            scroll.price,
            scroll.prerequisite,
            scroll.lessonIncluded,
            scroll.hasPrerequisite,
            scroll.available
        );
    }

    /**
     * @dev See {IMagicScrolls-scrollInfo}.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function scrollInfo(uint256 tokenId)
        public
        view
        virtual
        override
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool,
            bool
        )
    {
        require(_exists(tokenId), "This scroll does not exist");
        MagicScroll memory scroll = _scrollCreated[tokenId];
        return (
            tokenId,
            scroll.scrollID,
            scroll.price,
            scroll.prerequisite,
            scroll.lessonIncluded,
            scroll.hasPrerequisite
        );
    }

    /**
     * @dev See {IMagicScrolls-forceCancel}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function forceCancel(uint256 id) external virtual override returns (bool) {
        _forceCancel(id);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-consume}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - If the caller is not a certificate manager, then we reject the call.
     * - If the certificate manager do not accept this type of scroll, we also reject this call.
     * - If the scroll is not fresh, reject it.
     */
    function consume(uint256 id) external virtual override returns (bool) {
        _consume(id);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-burn}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - If the caller is not a certificate manager, then we reject the call.
     * - If the certificate manager do not accept this type of scroll, we also reject this call.
     * - If the scroll is not fresh, reject it.
     */
    function burn(uint256 id) external virtual override returns (bool) {
        _burn(id);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-buyScroll}.
     *
     * Requirements:
     *
     * - `scroll` type must be purchasable.
     * - The caller must be able to transfer DGT properly and succesfully.
     */
    function buyScroll(uint256 scrollType)
        external
        virtual
        override
        returns (bool)
    {
        _buyScroll(scrollType);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-addScroll}.
     *
     * Requirements:
     *
     * - `scroll` type must be purchasable.
     * - The caller must be the owner of the shop.
     */
    function addScroll(
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) external virtual override onlyOwner returns (bool) {
        _addScroll(prerequisite, lessonIncluded, hasPrerequisite, price);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-setCertificateManager}.
     *
     * Requirements:
     *
     * - The caller must be the owner of the shop.
     */
    function setCertificateManager(address manager, bool status)
        external
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _certificateManagers[manager] = status;
        emit ApprovalForCM(manager, status);
        return true;
    }

    /**
     * @dev See {IMagicScrolls-sealScroll}.
     *
     * Requirements:
     *
     * - `scroll` type must exist.
     * - The caller must be the owner of the shop.
     */
    function sealScroll(uint256 scrollType)
        external
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _sealScroll(scrollType);
        return true;
    }

    function _addScroll(
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) internal virtual onlyOwner {
        _scrollTypes[variations.current()] = MagicScroll({
            scrollID: variations.current(),
            price: price,
            prerequisite: prerequisite, //certification required
            state: 1,
            lessonIncluded: lessonIncluded,
            hasPrerequisite: hasPrerequisite,
            available: true
        });
        emit ScrollAdded(
            variations.current(),
            price,
            prerequisite,
            lessonIncluded,
            hasPrerequisite,
            true
        );
        variations.increment();
    }

    function _sealScroll(uint256 scrollType)
        internal
        virtual
        onlyOwner
        returns (bool)
    {
        require(_existsType(scrollType), "This scroll type does not exist");

        _scrollTypes[scrollType].available = false;
        emit ScrollAdded(
            _scrollTypes[scrollType].scrollID,
            _scrollTypes[scrollType].price,
            _scrollTypes[scrollType].prerequisite,
            _scrollTypes[scrollType].lessonIncluded,
            _scrollTypes[scrollType].hasPrerequisite,
            _scrollTypes[scrollType].available
        );
        return true;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _existsType(uint256 tokenId) internal view virtual returns (bool) {
        require(
            variations.current() > tokenId,
            "There are not that many types of scroll"
        );
        return _scrollTypes[tokenId].available;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseURIscroll;
    }

    function _buyScroll(uint256 scrollType) internal virtual {
        // check for validity to buy from interface for certificate
        require(
            isPurchasableScroll(scrollType, _msgSender()),
            "This scroll is not purchasable."
        );
        require(
            _DGT.transferFrom(
                _msgSender(),
                owner(),
                _scrollTypes[scrollType].price
            ),
            "Cannot transfer DGC, approve the contract or buy more DGC!"
        );
        _scrollCreated[tracker.current()] = _scrollTypes[scrollType];
        _owners[tracker.current()] = _msgSender();
        _balances[scrollType][_msgSender()]++;

        emit ScrollBought(tracker.current(), scrollType);
        tracker.increment();
    }

    function _burn(uint256 id) internal virtual {
        uint256 scrollType = _scrollCreated[id].scrollID;
        require(_exists(id), "Nonexistent token");
        require(
            isCertificateManager(_msgSender()),
            "You are not the certificate manager, burning is reserved for the claiming certificate only."
        );
        require(
            ISkillCertificate(_msgSender()).typeAccepted() == scrollType,
            "Wrong type of scroll to be burned."
        );
        require(
            _scrollCreated[id].state == 1 || _scrollCreated[id].state == 2,
            "This scroll is no longer burnable."
        );
        _balances[_scrollCreated[id].scrollID][ownerOf(id)]--;
        _scrollCreated[id].state = 0; //consumed state id
        _owners[id] = address(0);

        emit StateChanged(id, _scrollCreated[id].state);
    }

    function _forceCancel(uint256 id) internal virtual onlyOwner {
        require(_exists(id), "Nonexistent token");
        _scrollCreated[id].state = 99; //Cancelled state id
        emit StateChanged(id, _scrollCreated[id].state);
    }

    function _consume(uint256 id) internal virtual {
        uint256 scrollType = _scrollCreated[id].scrollID;

        require(_exists(id), "Nonexistent token");
        require(
            isCertificateManager(_msgSender()),
            "You are not the certificate manager, consuming is reserved for the claiming exam key only."
        );
        require(
            ISkillCertificate(_msgSender()).typeAccepted() == scrollType,
            "Wrong type of scroll to be consumed."
        );
        require(
            _scrollCreated[id].state == 1,
            "This scroll is no longer consumable."
        );
        _scrollCreated[id].state = 2; //consumed state id
        emit StateChanged(id, _scrollCreated[id].state);
    }

    /*
     * @dev Get a checksummed string hex representation of an account address.
     * @param account address The account to get the checksum for.
     * @return The checksummed account string in ASCII format.
     */
    function _getChecksum(address account)
        private
        pure
        returns (string memory accountChecksum)
    {
        // call internal function for converting an account to a checksummed string.
        return string(abi.encodePacked("0x", _toChecksumString(account)));
    }

    /*
     * @dev Get a fixed-size array of whether or not each character in an account
     * will be capitalized in the checksum.
     * @param account address The account to get the checksum capitalization
     * information for.
     * @return A fixed-size array of booleans that signify if each character or
     * "nibble" of the hex encoding of the address will be capitalized by the
     * checksum.
     */
    function _getChecksumCapitalizedCharacters(address account)
        private
        pure
        returns (bool[40] memory characterCapitalized)
    {
        // call internal function for computing characters capitalized in checksum.
        return _toChecksumCapsFlags(account);
    }

    function _toChecksumString(address account)
        private
        pure
        returns (string memory asciiString)
    {
        // convert the account argument from address to bytes.
        bytes20 data = bytes20(account);

        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;
        bool leftCaps;
        bool rightCaps;
        uint8 asciiOffset;

        // get the capitalized characters in the actual checksum.
        bool[40] memory caps = _toChecksumCapsFlags(account);

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // locate and extract each capitalization status.
            leftCaps = caps[2 * i];
            rightCaps = caps[2 * i + 1];

            // get the offset from nibble value to ascii character for left nibble.
            asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset);

            // get the offset from nibble value to ascii character for right nibble.
            asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset);
        }

        return string(asciiBytes);
    }

    function _toChecksumCapsFlags(address account)
        private
        pure
        returns (bool[40] memory characterCapitalized)
    {
        // convert the address to bytes.
        bytes20 a = bytes20(account);

        // hash the address (used to calculate checksum).
        bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

        // declare variable types.
        uint8 leftNibbleAddress;
        uint8 rightNibbleAddress;
        uint8 leftNibbleHash;
        uint8 rightNibbleHash;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i; i < a.length; i++) {
            // locate the byte and extract each nibble for the address and the hash.
            rightNibbleAddress = uint8(a[i]) % 16;
            leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
            rightNibbleHash = uint8(b[i]) % 16;
            leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

            characterCapitalized[2 * i] = (leftNibbleAddress > 9 &&
                leftNibbleHash > 7);
            characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 &&
                rightNibbleHash > 7);
        }
    }

    /*
     * @dev Determine whether a string hex representation of an account address
     * matches the ERC-55 checksum of that address.
     * @param accountChecksum string The checksummed account string in ASCII
     * format. Note that a leading "0x" MUST NOT be included.
     * @return A boolean signifying whether or not the checksum is valid.
     */
    function _isChecksumValid(string memory provided)
        private
        pure
        returns (bool ok)
    {
        // convert the provided string into account type.
        address account = _toAddress(provided);

        // return false in the event the account conversion returned null address.
        if (account == address(0)) {
            // ensure that provided address is not also the null address first.
            bytes memory b = bytes(provided);
            for (uint256 i; i < b.length; i++) {
                if (b[i] != hex"30") {
                    return false;
                }
            }
        }

        // get the capitalized characters in the actual checksum.
        string memory actual = _toChecksumString(account);

        // compare provided string to actual checksum string to test for validity.
        return (keccak256(abi.encodePacked(actual)) ==
            keccak256(abi.encodePacked(provided)));
    }

    function _getAsciiOffset(uint8 nibble, bool caps)
        private
        pure
        returns (uint8 offset)
    {
        // to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
        if (nibble < 10) {
            offset = 48;
        } else if (caps) {
            offset = 55;
        } else {
            offset = 87;
        }
    }

    function _toAddress(string memory account)
        private
        pure
        returns (address accountAddress)
    {
        // convert the account argument from address to bytes.
        bytes memory accountBytes = bytes(account);

        // create a new fixed-size byte array for the ascii bytes of the address.
        bytes memory accountAddressBytes = new bytes(20);

        // declare variable types.
        uint8 b;
        uint8 nibble;
        uint8 asciiOffset;

        // only proceed if the provided string has a length of 40.
        if (accountBytes.length == 40) {
            for (uint256 i; i < 40; i++) {
                // get the byte in question.
                b = uint8(accountBytes[i]);

                // ensure that the byte is a valid ascii character (0-9, A-F, a-f)
                if (b < 48) return address(0);
                if (57 < b && b < 65) return address(0);
                if (70 < b && b < 97) return address(0);
                if (102 < b) return address(0); //bytes(hex"");

                // find the offset from ascii encoding to the nibble representation.
                if (b < 65) {
                    // 0-9
                    asciiOffset = 48;
                } else if (70 < b) {
                    // a-f
                    asciiOffset = 87;
                } else {
                    // A-F
                    asciiOffset = 55;
                }

                // store left nibble on even iterations, then store byte on odd ones.
                if (i % 2 == 0) {
                    nibble = b - asciiOffset;
                } else {
                    accountAddressBytes[(i - 1) / 2] = (
                        bytes1(16 * nibble + (b - asciiOffset))
                    );
                }
            }

            // pack up the fixed-size byte array and cast it to accountAddress.
            bytes memory packed = abi.encodePacked(accountAddressBytes);
            assembly {
                accountAddress := mload(add(packed, 20))
            }
        }
    }

    // based on https://ethereum.stackexchange.com/a/56499/48410
    function _toAsciiString(bytes20 data)
        private
        pure
        returns (string memory asciiString)
    {
        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
            asciiBytes[2 * i] = bytes1(
                leftNibble + (leftNibble < 10 ? 48 : 87)
            );
            asciiBytes[2 * i + 1] = bytes1(
                rightNibble + (rightNibble < 10 ? 48 : 87)
            );
        }

        return string(asciiBytes);
    }
}

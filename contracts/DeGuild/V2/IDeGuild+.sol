// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 * NFT style interface, but it does not allow transfer like other ERC721 and ERC1155
 * It requires DGT & SkillCertificate to work around with.
 * This contract will lock the payment of the client and taker until the client is satisfied.
 *
 * However, there is a report system that will prevent malicious intents between taker and client.
 * The owner of this contract has no power until the job is reported!
 *
 * When a job is reported, every process will be centralized!
 *
 * However, since anyone can report the job, you might get abused by 
 * malicious clone of this contract where owner take the job and report the job so
 * that the owner of this contract can steal the money.
 *
 * With trustable owner, this contract will be fine.
 * 
 * Use at your own risk!
 *
 * The solution to this is to put the reported job to undergo by the judges, possilbly a DAO system can be helpful.
 * Another approach is using automated script to test the job submission.
 * 
 */
interface IDeGuildPlus {
    /**
     * @dev This data type is used to store the data of a magic scroll.
     * reward           (uint256)       is the reward of that scroll.
     * client           (address)       is the address of the certificate manager (any address is fine, if it has no prerequisite).
     * taker            (address)       is the address of the certificate manager (any address is fine, if it has no prerequisite).
     * certificates     (address[])     is the address of the certificate manager (any address is fine, if it has no prerequisite).
     * skills           (address[][])   is the address of the certificate manager (any address is fine, if it has no prerequisite).
     * state            (uint8)         is the state of the scroll (Consumed or cancelled or fresh).
     * deadline         (uint256)       is the state telling that this scroll can be used for unlocking learning materials off-chain.
     * level            (uint256)       is the state telling that this scroll can be used for unlocking learning materials off-chain.
     * state            (uint8)         is the state telling that this scroll requires a certificate from the certificate manager given.
     * difficulty       (uint8)         is the state telling that this scroll is no longer purchasable
     *                                  (only used to check the availability to mint various magic scroll types)
     */
    struct Job {
        uint256 reward;
        address client;
        address taker;
        address[] certificates;
        uint256[][] skills;
        uint8 state;
        uint8 difficulty;
        bool assigned;
    }

    /**
     * @dev Emitted when `jobId` is minted.
     */
    event JobAdded(uint256 jobId, address indexed client);
    event JobTaken(uint256 jobId, address indexed taker);
    event JobCompleted(uint256 jobId, address indexed taker);
    event JobCaseOpened(uint256 indexed jobId);
    event JobCaseClosed(uint256 jobId, address indexed criminal);

    /**
     * @dev Returns the shop name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the shop symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `jobId` token.
     *
     * Requirements:
     *
     * - `jobId` cannot be non-existence token.
     */
    function jobURI(uint256 jobId) external view returns (string memory);

    /**
     * @dev Returns the acceptable token address.
     */
    function deguildCoin() external view returns (address);

    /**
     * @dev Returns the owners of the `id` token which are client and job taker.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownersOf(uint256 id) external view returns (address, address);

    /**
     * @dev Returns the current job that `account` owned
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function jobOf(address account) external view returns (uint256);

    /**
     * @dev Returns true if `jobId` is purchasable for `taker`.
     *      Each scroll has its own conditions to purchase.
     */
    function isQualified(uint256 jobId, address taker)
        external
        view
        returns (bool);

    /**
     * @dev Returns the latest `jobId` minted.
     */
    function jobsCount() external view returns (uint256);

    /**
     * @dev Returns the information of the token type of `typeId`.
     * [0] (uint256)    typeId
     * [1] (uint256)    price of this `typeId` type
     * [2] (address)    prerequisite of this `typeId` type
     * [3] (bool)       lessonIncluded of this `typeId` type
     * [4] (bool)       hasPrerequisite of this `typeId` type
     * [5] (bool)       available of this `typeId` type
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function jobInfo(uint256 typeId)
        external
        view
        returns (
            uint256,
            address,
            address,
            address[] memory,
            uint256[][] memory,
            uint8,
            uint8
        );

    function verifySkills(
        address[] memory certificates,
        uint256[][] memory skills
    ) external view returns (bool);

    /**
     * @dev Change `id` token state to 99 (Cancelled).
     *
     * Usage : Neutralize the scroll if something fishy occurred with the owner.
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of deGuild.
     */
    function forceCancel(uint256 id) external returns (bool);

    function cancel(uint256 id) external returns (bool);

    /**
     * @dev Change `id` token state to 2 (Consumed).
     *
     * Usage : Unlock a key from certificate manager to take examination
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - If the caller is not a certificate manager, then we reject the call.
     * - If the certificate manager do not accept this type of scroll, we also reject this call.
     * - If the scroll is not fresh, reject it.
     */
    function take(uint256 id) external returns (bool);

    /**
     * @dev Change `id` token state to 0 (Burned) and transfer ownership to address(0).
     *
     * Usage : Burn the token
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - If the caller is not a certificate manager, then we reject the call.
     * - If the certificate manager do not accept this type of scroll, we also reject this call.
     * - If the scroll is not fresh, reject it.
     */
    function complete(uint256 id) external returns (bool);

    function report(uint256 id) external returns (bool);

    function judge(uint256 id, bool decision) external returns (bool);

    /**
     * @dev Mint a type scroll.
     *
     * Usage : Add a magic scroll
     * Emits a {ScrollAdded} event.
     *
     * Requirements:
     *
     * - `scroll` type must be purchasable.
     * - The caller must be the owner of the shop.
     */
    function addJob(
        uint256 bonus,
        address taker,
        address[] memory certificates,
        uint256[][] memory skills,
        uint8 difficulty
    ) external returns (bool);
}

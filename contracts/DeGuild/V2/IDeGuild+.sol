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
 * malicious clone of this contract where owner could take the job and report the job so
 * that the owner of this contract can steal the money.
 *
 * Also, the owner of this contract can force cancel any job!
 * That means malicious owner can take any job for free and freelancers would not know.
 *
 * With trustable owner, this contract will be fine.
 * Though this is not really decentralized, but as long as client and taker
 * follow the rules, they will not even need this report system.
 *
 * However, crimes on Dapps (even normal apps) are really hard to deal with.
 * This contracts will guaranteed safety to the users in case of emergency.
 *
 * Use this contract at your own risk!
 *
 * The solution to this is to put the reported job to undergo by the judges, possilbly a DAO system can be helpful.
 * Another approach is using automated script to test the job submission.
 *
 */
interface IDeGuildPlus {
    /**
     * @dev This data type is used to store the data of a job.
     * reward           (uint256)       is the reward of that job.
     * client           (address)       is the address of the client.
     * taker            (address)       is the address of the taker.
     * certificates     (address[])     is the addresses of the certificate manager.
     * skills           (address[][])   is the array of the certificate manager tokens array.
     * state            (uint8)         is the state of the job.
     *                                      - 1 means the job is available
     *                                      - 2 means the job is taken
     *                                      - 3 means the job is completed
     *                                      - 0 means the job is reported
     *                                      - 99 means the job is cancelled and will be burned (not found)
     *
     * difficulty       (uint8)         is the level of job difficulty
     * assigned         (uint8)         is true when the job is assigned to specific account.
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
     * @dev Emitted when `jobId` is minted and state is 1.
     */
    event JobAdded(uint256 jobId, address indexed client);

    /**
     * @dev Emitted when `jobId` state is 2.
     */
    event JobTaken(uint256 jobId, address indexed taker);

    /**
     * @dev Emitted when `jobId` state is 3.
     */
    event JobCompleted(uint256 jobId, address indexed taker);

    /**
     * @dev Emitted when `jobId` state is 0.
     */
    event JobCaseOpened(uint256 indexed jobId);

    /**
     * @dev Emitted when `jobId` state is 3 and criminal is banned.
     */
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
     * @dev Returns the amount of `jobId` minted.
     */
    function jobsCount() external view returns (uint256);

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
     * @dev Returns the current job that `account` is working on
     */
    function jobOf(address account) external view returns (uint256);

    /**
     * @dev Returns true if `taker` is qualified to take `jobId`.
     *      Each job has its own conditions to purchase.
     *
     * Requirements:
     *
     * - `jobId` must exist.
     */
    function isQualified(uint256 jobId, address taker)
        external
        view
        returns (bool);

    /**
     * @dev Returns the information of the job of `jobId`.
     * [0] (uint256)        reward of this `jobId`
     * [1] (address)        client of this `jobId`
     * [2] (address)        taker of this `jobId`
     * [3] (address[])      certificates of this `jobId`
     * [4] (uint256[][])    skills (certificates' tokens) of this `jobId`
     * [5] (uint8)          state of this `jobId`
     * [6] (uint8)          difficulty of this `jobId`
     *
     * Requirements:
     *
     * - `jobId` must exist.
     */
    function jobInfo(uint256 jobId)
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

    /**
     * @dev Returns the result of verification of skills
     * If true, then these skills exist and valid for qualifying job taker.
     * Else, there are issues with these skills or certificate addresses
     *
     * Requirements:
     *
     * - `certificates` must support the interface of ISkillCertificatePlus (ERC165).
     * - `skills` element cannot have more than 20 sub-elements (skills[0].length < 20).
     * - `skills` length must be equal to `certificates`.
     * - `certificates` array length must be less than 30.
     */
    function verifySkills(
        address[] memory certificates,
        uint256[][] memory skills
    ) external view returns (bool);

    /**
     * @dev Change the `id` job's state to 99 (Cancelled), free the job taker and burn.
     *
     * Usage : Neutralize the job that violates rules and regulations and burn it.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of deGuild.
     * - `id` state must not be 99 or 3 (neither cancelled or completed).
     * - This contract has enough money to return all the reward of `id`.
     */
    function forceCancel(uint256 id) external returns (bool);

    /**
     * @dev Change the `id` job's state to 99 (Cancelled) and burn.
     *
     * Usage : Neutralize the job and burn it.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the client.
     * - `id` state must be 1 (available).
     * - This contract has enough money to return all the reward of `id`.
     */
    function cancel(uint256 id) external returns (bool);

    /**
     * @dev Change the `id` job's state to 2 (taken) and
     * set current of of caller to `id`.
     *
     * Usage : Take the job and start working!
     * Emits a {JobTaken} event.
     *
     * Requirements:
     *
     * - The caller must not be banned.
     * - `id` must exist.
     * - The caller cannot be the job's client.
     * - The caller must pass the qualification (might take longer if the number of skills is large).
     * - The caller must not have any job ongoing.
     * - `id` state must be 1 (available).
     * - If the job is assigned, the taker must be the same as the caller
     */
    function take(uint256 id) external returns (bool);

    /**
     * @dev Change `id` token state to 3 (Completed)
     * and transfer rewards to the taker with 2% fee deducted.
     *
     * Usage : Complete the job and give the reward the taker
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - `id` state must be 2 (available).
     * - The caller must be the job's client.
     * - This contract must have enough fund to transfer fees.
     * - This contract must have enough fund to transfer rewards.
     */
    function complete(uint256 id) external returns (bool);

    /**
     * @dev Change `id` token state to 0 (Investigating).
     *
     * Usage : Set a flag for the owner of this contract
     * to take care of malicious events
     * Emits a {JobCaseOpened} event.
     *
     * Notes : This is very centralized. Please read the header for more info.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - `id` state must be 2 (available).
     * - The caller must be the job's client or taker.
     */
    function report(uint256 id) external returns (bool);

    /**
     * @dev Change `id` token state to 3 (Completed), free the job taker.
     *
     * Usage : Complete the job and judge the ongoing case
     * setting `decision` to true will ban the taker
     * else, we ban the client
     * Emits a {JobCaseClosed} event.
     *
     * Notes : Banned clients can still download the job submission.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - `id` state must be 0 (investigating).
     * - the caller must be the owner of this contract
     * - This contract must have enough fund to transfer fees.
     * - This contract must have enough fund to transfer rewards.
     */
    function judge(
        uint256 id,
        bool decision,
        bool isCompleted,
        uint256 feeRate,
        uint256 clientRate,
        uint256 takerRate
    ) external returns (bool);

    /**
     * @dev Add a job to the job list.
     *
     * Usage : `bonus` is the bonus added to reward
     *          if taker is not address(0), it will be assigned to the taker.
     *          difficulty is used to calculate reward, it is used to calculate
     *          freelancers level later.
     *          Skills and certificate addresses are used to verify taker
     *
     * Emits a {jobAdded} event.
     *
     * Notes : Morally, difficulty is based on client feeling.
     *         It is important to give the wage fairly based on the job difficulty.
     *         Say we based on the level of education...
     *         - level 0 is for beginners (< 3 months exp)
     *         - level 1-2 is for intermediate (< 1 year exp)
     *         - level 3-4 is for experts (2+ year exp)
     *         - level 5+ is for pros (5+ year exp)
     *         Job taker is more likely attract to reward, so adding bonus will surely
     *         attract high-level job taker.
     *
     * Requirements:
     *
     * - The caller must not be banned.
     * - The caller cannot set taker to be the caller.
     * - The skills must pass the verification (might take longer if the number of skills is large).
     * - This caller must have enough fund to transfer rewards.
     */
    function addJob(
        uint256 bonus,
        address taker,
        address[] memory certificates,
        uint256[][] memory skills,
        uint8 difficulty
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract UCLBLottery is VRFConsumerBaseV2 {
    // The address of the Chainlink VRF Coordinator
    VRFCoordinatorV2Interface immutable COORDINATOR;

    // The subscription ID that this contract uses for funding requests
    uint64 immutable s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to
    bytes32 immutable s_keyHash;

    // The gas limit for the callback function.
    uint32 constant CALLBACK_GAS_LIMIT = 2500000;

    // The number of confirmations to wait for before the oracle responds.
    uint16 constant REQUEST_CONFIRMATIONS = 3;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    // Mapping of entry ID to entry first name
    mapping (uint256 => string) public entries;

    // Struct to store winner information
    struct Winner {
        uint256 id;
        string name;
    }

    // Array of winners
    Winner[] public winners;

    // Number of entries to the lottery
    uint256 numberOfEntries;

    // Event to emit when randomness is returned
    event ReturnedRandomness(uint256[] randomWords);

    /// @notice Constructor inherits VRFConsumerBaseV2
    /// @param subscriptionId - the subscription ID that this contract uses for funding requests
    /// @param vrfCoordinator - the address of the Chainlink VRF Coordinator
    /// @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
    /// @param initialEntries - list of firstnames that are entered into the lottery
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        string[] memory initialEntries
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;

        // Populate entries mapping
        for (uint256 i = 0; i < initialEntries.length; i++) {
            entries[i] = initialEntries[i];
        }

        // Set number of entries
        numberOfEntries = initialEntries.length;
    }

    /// @notice Request random numbers from Chainlink VRF service
    /// @dev Will call fulfillRandomWords once randomness is returned
    function requestRandomWords(uint32 _numWords) external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            _numWords
        );
    }

    /// @notice Callback function used by VRF Coordinator, computes the winners of the lottery
    /// @dev Called by VRF Coordinator
    /// @param requestId - id of the request
    /// @param randomWords - array of random results from VRF Coordinator
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Using a local memory array to avoid unnecessary storage operations
        uint256[] memory processedWords = new uint256[](randomWords.length);
        
        // Compute winners
        for (uint i = 0; i < randomWords.length; i++) {
            processedWords[i] = randomWords[i] % numberOfEntries;
            winners.push(Winner({
                id: processedWords[i],
                name: entries[processedWords[i]]
            }));
        }

        // Set random numbers
        s_randomWords = processedWords;
        emit ReturnedRandomness(s_randomWords);
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}
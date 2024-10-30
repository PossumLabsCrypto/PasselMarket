// SPDX-License-Identifier: GPL-2.0-only
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// ===================================
//    ERRORS
// ===================================
error questComplete();
error NotPasselExplorer();

/// @title Passel NFT Quests
/// @author Possum Labs
/// @notice This contract contains the on-chain quests for users to increase the Exploration Score of Passel NFTs

contract PasselQuests {
    constructor(address _passelExplorer) {
        PASSEL_EXPLORER = _passelExplorer;
    }

    // ===================================
    //    VARIABLES
    // ===================================
    address public immutable PASSEL_EXPLORER; // The explorer contract users interface with to level up their NFTs

    uint256 public constant QUESTS_AVAILABLE = 7;
    mapping(uint256 nftID => uint256[] quests) public completedQuests;

    // ===================================
    //    EVENTS
    // ===================================
    event QuestCompleted(uint256 indexed nftID, uint256 indexed questID);

    // ===================================
    //    MODIFIERS
    // ===================================
    modifier onlyExplorer() {
        if (msg.sender != PASSEL_EXPLORER) {
            revert NotPasselExplorer();
        }
        _;
    }

    // ===================================
    //    FUNCTIONS - quests
    // ===================================
    ///@dev Execute & verify quest 1, called by doQuest of the PasselExplorer
    function questOne() external onlyExplorer returns (bool completed) {}

    ///@dev Execute & verify quest 2, called by doQuest of the PasselExplorer
    function questTwo() external onlyExplorer returns (bool completed) {}

    ///@dev Execute & verify quest 3, called by doQuest of the PasselExplorer
    function questThree() external onlyExplorer returns (bool completed) {}

    ///@dev Execute & verify quest 4, called by doQuest of the PasselExplorer
    function questFour() external onlyExplorer returns (bool completed) {}

    ///@dev Execute & verify quest 5, called by doQuest of the PasselExplorer
    function questFive() external onlyExplorer returns (bool completed) {}

    ///@dev Execute & verify quest 6, called by doQuest of the PasselExplorer
    function questSix() external onlyExplorer returns (bool completed) {}

    ///@dev Execute & verify quest 7, called by doQuest of the PasselExplorer
    function questSeven() external onlyExplorer returns (bool completed) {}

    // ===================================
    //    FUNCTIONS - read
    // ===================================
    function isQuestCompleted(uint256 _nftID, uint256 _questID) public view returns (bool isCompleted) {}

    function getCompletedQuests(uint256 _nftID) external view returns (uint256[] memory completedQuestIDs) {}
}

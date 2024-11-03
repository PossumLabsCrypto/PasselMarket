// SPDX-License-Identifier: GPL-2.0-only
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IPasselQuests} from "./interfaces/IPasselQuests.sol";

// ===================================
//    ERRORS
// ===================================
error NotManager();
error IsRevoked();
error NullAddress();

/// @title Storage contract for information related to Passel NFTs for the purpose of on-chain governance
/// @author Possum Labs
/**
 * @notice This contract calculates and stores voting related information of Passel NFTs
 * Users can solve on-chain quests to increase the Exploration Score of a specific Passel NFT
 * Users can purchase Experience points for a specific Passel NFT using PSM
 * The PSM spent to buy Experience is directed to the psmReceiver
 * The manager can change the psmReceiver and the contract containing the Quests
 * The manager can revoke management rights but not transfer them. Management is supposed to be temporary.
 */
contract PasselExplorer {
    constructor(address _passelNFT, address _manager) {
        PASSEL_NFT = IERC721(_passelNFT);
        manager = _manager;
        psmReceiver = _manager;
    }

    // ===================================
    //    VARIABLES
    // ===================================
    IERC20 private constant PSM = IERC20(0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5); // PSM on Arbitrum
    IERC721 private immutable PASSEL_NFT;
    uint256 private constant MAX_EXPLORATION_SCORE = 10;

    address public manager;
    address public psmReceiver;
    IPasselQuests public passelQuests;

    mapping(uint256 nftID => uint256 exp) public getExperience;
    mapping(uint256 nftID => uint256 score) public getExplorationScore;

    // ===================================
    //    EVENTS
    // ===================================
    event EXP_Purchased(uint256 indexed nftID, uint256 amount);

    // ===================================
    //    MODIFIERS
    // ===================================
    modifier onlyManager() {
        if (msg.sender != manager) {
            revert NotManager();
        }
        _;
    }

    // ===================================
    //    FUNCTIONS - manager
    // ===================================
    /// @dev Revoke management rights & lock in current settings forever
    function revokeManager() external onlyManager {
        manager = address(0);
    }

    /// @dev Allow the controller to change the address that receives PSM from Experience purchases
    function setPsmReceiver(address _newReceiver) external onlyManager {
        if (_newReceiver == address(0)) revert NullAddress();
        psmReceiver = _newReceiver;
    }

    /// @dev Allow the controller to change the quest contract. Set address(0) to disable quests.
    /// @dev Completing quests can increase the Exploration Score of a Passel NFT up to the hard cap
    function setPasselQuests(address _newQuests) external onlyManager {
        passelQuests = IPasselQuests(_newQuests);
    }

    // ===================================
    //    FUNCTIONS - users
    // ===================================
    /// @notice Caller can buy experience for any Passel NFT with PSM where 1 PSM = 1 Experience
    function buyExperience(uint256 _tokenID, uint256 _amount) external {
        // Checks
        /// @dev Check if the NFT receiving the EXP exists
        /// @dev ownerOf reverts with error from ERC721 if ID does not exist
        if (PASSEL_NFT.ownerOf(_tokenID) == address(0)) {}

        // Effects
        /// @dev Add the purchased Experience to the mapping related to the NFT
        getExperience[_tokenID] = getExperience[_tokenID] + _amount;

        // Interactions
        /// @dev Transfer PSM from the buyer to the psmReceiver
        PSM.transferFrom(msg.sender, psmReceiver, _amount);

        /// @dev Emit event that Experience has been purchased for a specific NFT
        emit EXP_Purchased(_tokenID, _amount);
    }

    /// @notice The caller can complete a quest for any Passel NFT to increase the NFT's Exploration Score
    /// @dev The caller could do quests for NFTs of other owners if desired (e.g. sponsorship)
    function doQuest(uint256 _tokenID, uint256 _questID) external {
        // Checks
        /// @dev Check if the NFT receiving the Explorer Score exists
        /// @dev ownerOf reverts with error from ERC721 if ID does not exist
        if (PASSEL_NFT.ownerOf(_tokenID) == address(0)) {}

        address user = msg.sender;
        uint256 score;

        // Effects

        // Interactions
        /// @dev Execute the quest and receive the score if successful
        score = passelQuests.quest(user, _tokenID, _questID);

        /// @dev Increase the exploration score of the NFT if quest is successful
        getExplorationScore[_tokenID] += score;
    }
}

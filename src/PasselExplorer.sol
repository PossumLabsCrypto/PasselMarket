// SPDX-License-Identifier: GPL-2.0-only
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IPasselQuests} from "./interfaces/IPasselQuests.sol";

// ===================================
//    ERRORS
// ===================================
error NotController();
error IsRevoked();
error NullAddress();

/// @title Storage contract for information related to Passel NFTs for the purpose of on-chain governance
/// @author Possum Labs
/**
 * @notice This contract calculates and stores voting related information of Passel NFTs
 * Users can solve on-chain quests to increase the Exploration Score of a specific Passel NFT
 * Users can pay PSM to receive Experience to a specific Passel NFT
 * The PSM used to buy Experience is directed to the psmReceiver
 * The controller can change the psmReceiver and can revoke the controller
 */
contract PasselExplorer {
    constructor(address _passelNFT, address _passelQuests) {
        PASSEL_NFT = IERC721(_passelNFT);
        controller = 0xAb845D09933f52af5642FC87Dd8FBbf553fd7B33; // PSM MULTI-SIG (ARBITRUM)
        psmReceiver = controller;
        passelQuests = _passelQuests;
    }

    // ===================================
    //    VARIABLES
    // ===================================
    IERC20 private constant PSM = IERC20(0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5); // PSM on Arbitrum
    IERC721 private immutable PASSEL_NFT;
    uint256 private constant MAX_EXPLORATION_SCORE = 10;

    address public controller;
    address public psmReceiver;
    address public passelQuests;

    mapping(uint256 nftID => uint256 exp) public getExperience;
    mapping(uint256 nftID => uint256 score) public getExplorationScore;

    // ===================================
    //    EVENTS
    // ===================================

    // ===================================
    //    MODIFIERS
    // ===================================
    modifier onlyController() {
        if (msg.sender != controller) {
            revert NotController();
        }
        _;
    }

    // ===================================
    //    FUNCTIONS - controller
    // ===================================
    /// @dev Revokes control & lock in current settings forever
    function revokeController() external onlyController {
        if (controller == address(0)) revert IsRevoked();
        controller = address(0);
    }

    /// @dev Allow the controller to change the address that receives PSM from Experience purchases
    function changePsmReceiver(address _newReceiver) external onlyController {
        if (_newReceiver == address(0)) revert NullAddress();
        psmReceiver = _newReceiver;
    }

    /// @dev Allow the controller to change the quest contract
    /// @dev Completing quests can increase the Exploration Score of a Passel NFT up to the hard cap
    function changePasselQuests(address _newQuests) external onlyController {
        if (_newQuests == address(0)) revert NullAddress();
        passelQuests = _newQuests;
    }

    // ===================================
    //    FUNCTIONS - users
    // ===================================
    /// @notice Caller can buy experience for any Passel NFT with PSM where 1 PSM = 1 Experience
    function buyExperience(uint256 _nftID, uint256 _amount) external {}

    /// @notice Caller can complete a quest for any Passel NFT to increase the NFT's Exploration Score
    function doQuest(uint256 _nftID, uint256 _questID) external {}
}

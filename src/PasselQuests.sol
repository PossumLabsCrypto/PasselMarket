// SPDX-License-Identifier: GPL-2.0-only
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ICoreV1} from "./interfaces/ICoreV1.sol";
import {IPortalsV1} from "./interfaces/IPortalsV1.sol";
import {IPasselExplorer} from "./interfaces/IPasselExplorer.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ===================================
//    ERRORS
// ===================================
error QuestComplete();
error NotPasselExplorer();
error QuestCondition();

/// @title Passel NFT Quests
/// @author Possum Labs
/// @notice This contract contains the on-chain quests for users to increase the Exploration Score of Passel NFTs
contract PasselQuests {
    constructor(address _passelExplorer) {
        PASSEL_EXPLORER_ADDRESS = _passelExplorer;
        PASSEL_EXPLORER = IPasselExplorer(_passelExplorer);
    }

    // ===================================
    //    VARIABLES
    // ===================================
    using SafeERC20 for IERC20;

    IERC20 private constant PSM = IERC20(0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5); // PSM on Arbitrum
    IERC20 private constant PE_ETH = IERC20(0xA9Ee3b373843008a56178Fc3047fbD1C145c5a12); // PE-ETH token of the ETH Portal (V2) on Arbitrum
    address private constant USDCE_ADDRESS = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    ICoreV1 private constant CORE_V1 = ICoreV1(0xb12192f4E3AcCb5D33589Ed683701F69a272EA26);
    IPortalsV1 private constant PORTALS_V1 = IPortalsV1(0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa);
    IPasselExplorer private immutable PASSEL_EXPLORER;

    address public immutable PASSEL_EXPLORER_ADDRESS; // The explorer contract users interface with to level up their NFTs
    uint256 public constant QUESTS_AVAILABLE = 7;

    mapping(uint256 nftID => uint256[] quests) public getCompletedQuests;
    mapping(uint256 nftID => mapping(uint256 questID => bool completed)) public isQuestCompleted;

    // ===================================
    //    EVENTS
    // ===================================
    event QuestCompleted(uint256 indexed nftID, uint256 questID, uint256 score);

    // ===================================
    //    MODIFIERS
    // ===================================
    modifier onlyExplorer() {
        if (msg.sender != PASSEL_EXPLORER_ADDRESS) {
            revert NotPasselExplorer();
        }
        _;
    }

    // ===================================
    //    FUNCTIONS - quests
    // ===================================
    /// @notice Execute or verify the quest condition, called by doQuest of the PasselExplorer
    function quest(address _user, uint256 _tokenID, uint256 _questID) external onlyExplorer returns (uint256 score) {
        // Checks
        ///@dev Revert if the quest is already completed for this NFT
        if (isQuestCompleted[_tokenID][_questID]) revert QuestComplete();

        /// @dev Quest parameters
        uint256 requiredForScore1;
        uint256 requiredForScore2;

        // Effects
        _questEffects(_tokenID, _questID);

        // Interactions
        /// @dev Quest verification / execution
        // ========================================

        /// @dev Quest of owning PSM in wallet (ERC20 balance check)
        if (_questID == 1) {
            /// @dev set quest specific parameters
            requiredForScore1 = 100000 * 1e18; // 100k PSM
            requiredForScore2 = requiredForScore1 * 10; // 1M PSM

            /// @dev Get quest specific external data
            uint256 balancePSM = PSM.balanceOf(_user);

            /// @dev Evaluate quest condition and assign the score (1 or 2 or revert)
            score = _questCondition(requiredForScore1, requiredForScore2, balancePSM);
        }

        /// @dev Quest of staking PSM in the Core (staked balance check)
        if (_questID == 2) {
            /// @dev set quest specific parameters
            requiredForScore1 = 200000 * 1e18; // 200k PSM
            requiredForScore2 = requiredForScore1 * 10; // 2M PSM

            /// @dev Get quest specific external data
            ICoreV1.Stake memory userStake = CORE_V1.stakes(_user);
            uint256 stakeBalance = userStake.stakedBalance;

            /// @dev Evaluate quest condition and assign the score (1 or 2 or revert)
            score = _questCondition(requiredForScore1, requiredForScore2, stakeBalance);
        }

        /// @dev Quest of being active in the core (distributed balance check)
        if (_questID == 3) {
            /// @dev set quest specific parameters
            requiredForScore1 = 100000 * 1e18; // 100k CF
            requiredForScore2 = requiredForScore1 * 10; // 1M CF

            /// @dev Get quest specific external data
            uint256 distributedCF = CORE_V1.fragmentsDistributed(_user);

            /// @dev Evaluate quest condition and assign the score (1 or 2 or revert)
            score = _questCondition(requiredForScore1, requiredForScore2, distributedCF);
        }

        /// @dev Quest of accumulating surplus PE in the HLP PortalV1 (internal PE balance check)
        if (_questID == 4) {
            /// @dev set quest specific parameters
            requiredForScore1 = 10000 * 1e18; // 10k PE
            requiredForScore2 = requiredForScore1 * 10; // 100k PE

            /// @dev Get quest specific external data
            (,,,, uint256 maxStakeDebt, uint256 portalEnergy,) = PORTALS_V1.getUpdateAccount(_user, 0);
            uint256 surplusPE = (portalEnergy > maxStakeDebt) ? portalEnergy - maxStakeDebt : 0;

            /// @dev Evaluate quest condition and assign the score (1 or 2 or revert)
            score = _questCondition(requiredForScore1, requiredForScore2, surplusPE);
        }

        /// @dev Quest of creating / owning PE-ETH tokens (ERC20 balance check)
        if (_questID == 5) {
            /// @dev set quest specific parameters
            requiredForScore1 = 10 * 1e18; // 10 PE-ETH
            requiredForScore2 = requiredForScore1 * 10; // 100 PE-ETH

            /// @dev Get quest specific external data
            uint256 balancePE_ETH = PE_ETH.balanceOf(_user);

            /// @dev Evaluate quest condition and assign the score (1 or 2 or revert)
            score = _questCondition(requiredForScore1, requiredForScore2, balancePE_ETH);
        }

        /// @dev Quest of executing the arbitrage Tx on PortalsV1 (action)
        if (_questID == 6) {
            /// @dev set parameters and score
            uint256 convertAmountRequired = 100000 * 1e18; // 100k PSM
            score = 2;

            /// @dev transfer PSM from the user to this contract
            PSM.transferFrom(_user, address(this), convertAmountRequired);

            /// @dev approve the PortalsV1 contract for spending PSM
            PSM.approve(address(PORTALS_V1), convertAmountRequired);

            /// @dev Claim rewards for the Portal, execute the convert
            PORTALS_V1.claimRewardsHLPandHMX();
            PORTALS_V1.convert(USDCE_ADDRESS, 1, block.timestamp);

            /// @dev Send the received tokens (USDCE) to the user
            uint256 receivedAmount = IERC20(USDCE_ADDRESS).balanceOf(address(this));
            IERC20(USDCE_ADDRESS).transfer(_user, receivedAmount);
        }

        /// @dev Quest of increasing a Passel's EXP by 500k (action)
        if (_questID == 7) {
            /// @dev set parameters and score
            uint256 amountExperience = 500000 * 1e18; // 500k PSM -> EXP
            score = 1;

            /// @dev Transfer PSM from the user to this contract
            PSM.transferFrom(_user, address(this), amountExperience);

            /// @dev Approve the Passel Explorer to spend PSM and buy EXP for the specified NFT ID
            PSM.approve(address(PASSEL_EXPLORER), amountExperience);
            PASSEL_EXPLORER.buyExperience(_tokenID, amountExperience);
        }

        /// @dev Emit the event of successful quest completion
        emit QuestCompleted(_tokenID, _questID, score);
    }

    // ===================================
    //    FUNCTIONS - Internal
    // ===================================
    function _questCondition(uint256 _requiredForScore1, uint256 _requiredForScore2, uint256 _checkedValue)
        private
        pure
        returns (uint256 score)
    {
        /// @dev Evaluate quest condition and assign the score (1 or 2), revert if minimum condition is not met
        if (_checkedValue >= _requiredForScore2) {
            score = 2;
        } else {
            if (_checkedValue < _requiredForScore1) {
                revert QuestCondition();
            }
            score = 1;
        }
    }

    function _questEffects(uint256 _tokenID, uint256 _questID) private {
        /// @dev Update the mapping signalling that this quest has been completed
        /// @dev Keep quest 7 open - it is the only quest that can be executed multiple times
        isQuestCompleted[_tokenID][_questID] = (_questID == 7) ? false : true;

        /// @dev Update the quests array for the related getCompletedQuests mapping. Check if the array exists for this NFT ID
        if (getCompletedQuests[_tokenID].length == 0) {
            /// @dev If the array doesn't exist, create a new array with the new value
            getCompletedQuests[_tokenID] = new uint256[](_questID);
            getCompletedQuests[_tokenID][0] = _questID;
        } else {
            /// @dev If the array exists, append the new value
            /// @dev Quest 7 is appended each time it is executed but remains executable
            getCompletedQuests[_tokenID].push(_questID);
        }
    }
}

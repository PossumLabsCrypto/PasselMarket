// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IPasselQuests {
    function quest(address _user, uint256 _tokenID, uint256 _questID) external returns (uint256 score);

    function QUESTS_AVAILABLE() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IPortalsV1 {
    function claimRewardsHLPandHMX() external;
    function convert(address _token, uint256 _minReceived, uint256 _deadline) external;

    function getUpdateAccount(address _user, uint256 _amount)
        external
        view
        returns (
            address user,
            uint256 lastUpdateTime,
            uint256 lastMaxLockDuration,
            uint256 stakedBalance,
            uint256 maxStakeDebt,
            uint256 portalEnergy,
            uint256 availableToWithdraw
        );
}

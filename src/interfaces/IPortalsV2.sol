// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IPortalsV2 {
    function getUpdateAccount(address _user, uint256 _amount, bool _isPositiveAmount)
        external
        view
        returns (
            uint256 lastUpdateTime,
            uint256 lastMaxLockDuration,
            uint256 stakedBalance,
            uint256 maxStakeDebt,
            uint256 portalEnergy,
            uint256 availableToWithdraw,
            uint256 portalEnergyTokensRequired
        );
}

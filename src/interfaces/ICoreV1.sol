// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface ICoreV1 {
    struct Stake {
        uint256 stakedBalance;
        uint256 commitmentEnd;
        uint256 reservedRewards;
        uint256 storedCoreFragments;
        uint256 lastDistributionTime;
        uint256 coreFragmentsAPR;
    }

    function stakes(address _staker) external view returns (Stake memory);
    function fragmentsDistributed(address _staker) external view returns (uint256);
}

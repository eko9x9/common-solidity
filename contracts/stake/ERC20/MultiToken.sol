// SPDX-License-Identifier: MIT
// Generated with Spectral Syntax

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {
    struct Staker {
        uint256 amountStaked;
        uint256 unclaimedRewards;
        uint256[] stakedTokens;
    }

    bool public isInitialized;
    IERC1155 public stakingNft;
    IERC20 public earnedToken;
    uint256 public rewardPerBlock;
    uint256 public PRECISION_FACTOR;
    uint256 public startBlock;
    mapping(address => Staker) public stakers;

    constructor() {
        startBlock = block.number + 1;
    }

    function initialize(IERC1155 _stakingNft, IERC20 _earnedToken, uint256 _rewardPerBlock) external onlyOwner {
        require(!isInitialized, "Already initialized");

        isInitialized = true;

        stakingNft = _stakingNft;
        earnedToken = _earnedToken;
        rewardPerBlock = _rewardPerBlock;

        uint256 decimalsRewardToken = uint256(IERC20Metadata(address(_earnedToken)).decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10 ** (40 - decimalsRewardToken));
    }

    function deposit(uint256[] memory _tokenIds) external nonReentrant {
        require(startBlock > 0 && startBlock < block.number, "Staking hasn't started yet");
        require(_tokenIds.length > 0, "must add at least one tokenId");

        Staker storage staker = stakers[msg.sender];
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stakingNft.transferFrom(msg.sender, address(this), _tokenIds[i]);
            staker.stakedTokens.push(_tokenIds[i]);
            staker.amountStaked++;
        }
    }

    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage staker = stakers[msg.sender];

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(stakingNft.ownerOf(_tokenIds[i]) == msg.sender, "You don't own this token!");

            if (staker.amountStaked > 0) {
                uint256 rewards = calculateRewards(msg.sender);
                staker.unclaimedRewards += rewards;
            }

            stakingNft.transferFrom(msg.sender, address(this), _tokenIds[i]);
            staker.stakedTokens.push(_tokenIds[i]);
            staker.amountStaked++;
        }
    }

    function calculateRewards(address user) public view returns (uint256) {
        Staker storage staker = stakers[user];
        uint256 blockNumber = block.number;
        uint256 reward = staker.amountStaked * rewardPerBlock * blockNumber / PRECISION_FACTOR;
        return reward;
    }

    function claimRewards() external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        uint256 reward = calculateRewards(msg.sender);
        require(reward > 0, "No rewards to claim");

        staker.unclaimedRewards -= reward;
        earnedToken.transfer(msg.sender, reward);
    }

    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage staker = stakers[msg.sender];

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(staker.stakedTokens.length > 0, "No tokens to withdraw");

            staker.stakedTokens.pop();
            staker.amountStaked--;

            stakingNft.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }
    }
}

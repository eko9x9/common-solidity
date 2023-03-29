// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/library/SafeERC20.sol";
import "../utils/library/SafeMath.sol";
import "../utils/library/Ownable.sol";
import "../utils/library/ReentrancyGuard.sol";
import "../utils/interfaces/IPancakePair.sol";
import "../utils/interfaces/IPancakeFactory.sol";
import "../utils/interfaces/IPancakeRouter.sol";

contract LockerToken is Ownable, ReentrancyGuard {

    struct TokenLock {
        address lpToken;
        address owner;
        uint256 tokenAmount;
        uint256 unlockTime;
    }
    uint256 public lockNonce = 0;

    mapping(uint256 => TokenLock) public tokenLocks;

    // user locks lp's
    mapping(address => address[]) public userLocks;

    mapping(uint256 => address) public withdrawerLocks;

    modifier onlyLockOwner(uint lockId) {
        TokenLock storage lock = tokenLocks[lockId];
        require(lock.owner == address(msg.sender), "NO ACTIVE LOCK OR NOT OWNER");
        _;
    }

    function lockLiquidity(address lpToken, uint256 amount, uint256 unlockTime, address payable withdrawer) external payable nonReentrant returns (uint256 lockId) {
        
        TokenLock memory lock = TokenLock({
            lpToken: lpToken,
            owner: withdrawer,
            tokenAmount: amount,
            unlockTime: unlockTime
        });

        lockId = lockNonce++;
        tokenLocks[lockId] = lock;
        userLocks[msg.sender].push(lpToken);
        withdrawerLocks[lockId] = withdrawer;
    }

    function checkLpTokenIsPancake(address lpToken, address factoryAddress) private view returns (bool){
        IPancakePair pair = IPancakePair(lpToken);
        address factoryPair = IPancakeFactory(factoryAddress).getPair(pair.token0(), pair.token1());
        return factoryPair == lpToken;
    }

}
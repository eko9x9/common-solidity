// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/library/SafeERC20.sol";
import "../utils/library/SafeMath.sol";
import "../utils/library/Ownable.sol";
import "../utils/library/ReentrancyGuard.sol";
import "../utils/interfaces/IPancakePair.sol";
import "../utils/interfaces/IPancakeFactory.sol";
import "../utils/interfaces/IPancakeRouter.sol";

contract LpLock is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public feeReceiver;
    uint256 public ethFee;

    struct TokenLock {
        address lpToken;
        address owner;
        uint256 tokenAmount;
        uint256 unlockTime;
    }
    uint256 public lockNonce = 0;

    mapping(uint256 => TokenLock) public tokenLocks;

    // user locks lp's
    mapping(address => address[]) private userLocks;

    mapping(uint256 => address) public withdrawerLocks;

    modifier onlyLockOwner(uint lockId) {
        TokenLock storage lock = tokenLocks[lockId];
        require(lock.owner == address(msg.sender), "NO ACTIVE LOCK OR NOT OWNER");
        _;
    }

    constructor (address _feeReciver, uint256 _ethFee) {
        feeReceiver = _feeReciver;
        ethFee = _ethFee;
    }

    function lockLiquidity(address factoryAddress, address lpToken, uint256 amount, uint256 unlockTime, address payable withdrawer) external payable nonReentrant returns (uint256 lockId) {
        require(amount > 0, "ZERO AMOUNT");
        require(lpToken != address(0), "ZERO TOKEN");
        require(unlockTime > block.timestamp, "UNLOCK TIME IN THE PAST");
        require(unlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        require(checkIsLpToken(lpToken, factoryAddress), "NOT PAIR");
        transferFees();
        if(msg.value > ethFee){
            transferEth(msg.sender, msg.value.sub(ethFee));
        }

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

        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);

        return lockId;
    }

    function extendLockTime(uint256 lockId, uint256 newUnlockTime) external nonReentrant onlyLockOwner(lockId) {
        require(newUnlockTime > block.timestamp, "UNLOCK TIME IN THE PAST");
        require(newUnlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        TokenLock storage lock = tokenLocks[lockId];
        require(lock.unlockTime < newUnlockTime, "NOT INCREASING UNLOCK TIME");
        lock.unlockTime = newUnlockTime;
    }

    function increaseLockAmount(uint256 lockId, uint256 amountToIncrement) external nonReentrant onlyLockOwner(lockId) {
        require(amountToIncrement > 0, "ZERO AMOUNT");
        TokenLock storage lock = tokenLocks[lockId];

        lock.tokenAmount = lock.tokenAmount.add(amountToIncrement);
        IERC20(lock.lpToken).safeTransferFrom(msg.sender, address(this), amountToIncrement);
    }

    function checkIsLpToken(address lpToken, address factoryAddress) private view returns (bool){
        IPancakePair pair = IPancakePair(lpToken);
        address factoryPair = IPancakeFactory(factoryAddress).getPair(pair.token0(), pair.token1());
        return factoryPair == lpToken;
    }

    function withdraw(uint256 lockId) external {
        TokenLock storage lock = tokenLocks[lockId];
        withdrawPartially(lockId, lock.tokenAmount);
    }

    function withdrawPartially(uint256 lockId, uint256 amount) public nonReentrant onlyLockOwner(lockId) {
        TokenLock storage lock = tokenLocks[lockId];
        require(lock.tokenAmount >= amount, "AMOUNT EXCEEDS LOCKED");
        require(block.timestamp >= lock.unlockTime, "NOT YET UNLOCKED");
        IERC20(lock.lpToken).safeTransfer(lock.owner, amount);

        lock.tokenAmount = lock.tokenAmount.sub(amount);
        if(lock.tokenAmount == 0) {
            //clean up storage to save gas
            uint256 lpAddressIndex = indexOf(userLocks[lock.owner], lock.lpToken);
            delete userLocks[lock.owner][lpAddressIndex];
            delete withdrawerLocks[lockId];
        }
    }

    function transferLock(uint256 lockId, address newOwner) external onlyLockOwner(lockId) {
        require(newOwner != address(0), "ZERO NEW OWNER");
        TokenLock storage lock = tokenLocks[lockId];

        uint256 lpAddressIndex = indexOf(userLocks[lock.owner], lock.lpToken);
        delete userLocks[lock.owner][lpAddressIndex];
        userLocks[newOwner].push(lock.lpToken);

        lock.owner = newOwner;

    }

    function transferFees() private {
        require(msg.value >= ethFee, "Fees are not enough!");
        transferEth(feeReceiver, ethFee);
    }

    function transferEth(address recipient, uint256 amount) private {
        payable(recipient).transfer(amount);
    }

    function userLockTokens(address adress) external view returns (address[] memory){
        return userLocks[adress];
    }

    function setEthFee(uint256 newEthFee) external {
        ethFee = newEthFee;
    }

    function indexOf(address[] memory arr, address searchFor) private pure returns (uint256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return i;
            }
        }
        revert("Not Found");
    }
}
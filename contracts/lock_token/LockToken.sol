// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/library/SafeERC20.sol";
import "../utils/library/SafeMath.sol";
import "../utils/library/Ownable.sol";
import "../utils/library/ReentrancyGuard.sol";
import "../utils/interfaces/IPancakePair.sol";
import "../utils/interfaces/IPancakeFactory.sol";

contract locker is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct Lock {
        address token;
        uint amount;
        uint unlockTime;
        address owner;
        bool isLp;
    }

    struct UserLocks {
        uint256 lockId;
        address token;
        uint amount;
        uint unlockTime;
        bool isLp;
    }

    address public feeReceiver;
    uint256 public ethFee;

    mapping(uint256 => Lock) public tokenLocks;
    mapping(address => UserLocks[]) private userLocks;

    uint256 public lockNonce = 0;
    uint256 public lockLPNonce = 0;
    uint256 public lockTokenNonce = 0;

    modifier onlyLockOwner(uint lockId) {
        Lock storage lock = tokenLocks[lockId];
        require(lock.owner == address(msg.sender), "NO ACTIVE LOCK OR NOT OWNER");
        _;
    }

    constructor (address _feeReciver, uint256 _ethFee) {
        feeReceiver = _feeReciver;
        ethFee = _ethFee;
    }

    function lockToken(address token, uint256 amount, uint unlockTime, address payable owner) external payable nonReentrant returns (uint256 lockId){
        require(amount > 0, "ZERO AMOUNT");
        require(unlockTime > block.timestamp, "UNLOCK TIME IN THE PAST");
        require(unlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        transferFees();
        if(msg.value > ethFee){
            transferEth(msg.sender, msg.value.sub(ethFee));
        }

        lockId = lockNonce++;
        tokenLocks[lockId] = Lock({
            token: token,
            owner: owner,
            amount: amount,
            unlockTime: unlockTime,
            isLp: false
        });
        userLocks[msg.sender].push(
            UserLocks({
                lockId: lockId,
                token: token,
                amount: amount,
                unlockTime: unlockTime,
                isLp: false
            })
        );

        IERC20(token).transferFrom(msg.sender, address(this),amount);
        lockTokenNonce++;
        
        return lockId;
    }

    function lockLiquidity(address factoryAddress, address lpToken, uint256 amount, uint256 unlockTime, address payable owner) external payable nonReentrant returns (uint256 lockId) {
        require(amount > 0, "ZERO AMOUNT");
        require(lpToken != address(0), "ZERO TOKEN");
        require(unlockTime > block.timestamp, "UNLOCK TIME IN THE PAST");
        require(unlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        require(checkIsLpToken(lpToken, factoryAddress), "NOT PAIR");
        transferFees();
        if(msg.value > ethFee){
            transferEth(msg.sender, msg.value.sub(ethFee));
        }

        Lock memory lock = Lock({
            token: lpToken,
            owner: owner,
            amount: amount,
            unlockTime: unlockTime,
            isLp: true
        });

        lockId = lockNonce++;
        tokenLocks[lockId] = lock;
        userLocks[msg.sender].push(
            UserLocks({
                lockId: lockId,
                token: lpToken,
                amount: amount,
                unlockTime: unlockTime,
                isLp: true
            })
        );

        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);
        lockLPNonce++;

        return lockId;
    }

    function extendLockTime(uint256 lockId, uint256 newUnlockTime) external nonReentrant onlyLockOwner (lockId) {
        require(newUnlockTime > block.timestamp, "UNLOCK TIME IN THE PAST");
        require(newUnlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        Lock storage lock = tokenLocks[lockId];
        require(lock.unlockTime < newUnlockTime, "NOT INCREASING UNLOCK TIME");

        UserLocks memory token = UserLocks({
            lockId: lockId,
            token: lock.token,
            amount: lock.amount,
            unlockTime: newUnlockTime,
            isLp: lock.isLp
        });

        // Update UserLocks info
        uint256 tokenAddressIdx = indexOf(userLocks[lock.owner], token);
        userLocks[lock.owner][tokenAddressIdx] = token;

        lock.unlockTime = newUnlockTime;
    }

    function increaseLockAmount(uint256 lockId, uint256 amountToIncrement) external nonReentrant onlyLockOwner(lockId) {
        require(amountToIncrement > 0, "ZERO AMOUNT");
        Lock storage lock = tokenLocks[lockId];

        UserLocks memory token = UserLocks({
            lockId: lockId,
            token: lock.token,
            amount: lock.amount.add(amountToIncrement),
            unlockTime: lock.unlockTime,
            isLp: lock.isLp
        });

        // Update UserLocks info
        uint256 tokenAddressIdx = indexOf(userLocks[lock.owner], token);
        userLocks[lock.owner][tokenAddressIdx] = token;

        lock.amount = lock.amount.add(amountToIncrement);
        IERC20(lock.token).safeTransferFrom(msg.sender, address(this), amountToIncrement);
    }
    
    function withdraw(uint256 lockId) external nonReentrant onlyLockOwner(lockId) { 
        Lock memory lock = tokenLocks[lockId];
        require(block.timestamp > lock.unlockTime, "You must to attend your locktime!");
        IERC20(lock.token).transfer(lock.owner, lock.amount);

        UserLocks memory token = UserLocks({
            lockId: lockId,
            token: lock.token,
            amount: lock.amount,
            unlockTime: lock.unlockTime,
            isLp: lock.isLp
        });

        //clean up storage to save gas
        uint256 tokenAddressIdx = indexOf(userLocks[lock.owner], token);
        delete userLocks[lock.owner][tokenAddressIdx];
        delete tokenLocks[lockId];
    }

    function withdrawPartially(uint256 lockId, uint256 amount) public nonReentrant onlyLockOwner(lockId) {
        Lock storage lock = tokenLocks[lockId];
        require(block.timestamp > lock.unlockTime, "You must to attend your locktime!");

        IERC20(lock.token).transfer(lock.owner, amount);
        lock.amount = lock.amount.sub(amount);

        UserLocks memory token = UserLocks({
            lockId: lockId,
            token: lock.token,
            amount: lock.amount.sub(amount),
            unlockTime: lock.unlockTime,
            isLp: lock.isLp
        });

        // Update UserLocks info
        uint256 tokenAddressIdx = indexOf(userLocks[lock.owner], token);

        if(lock.amount == 0) {
            //clean up storage to save gas
            delete userLocks[lock.owner][tokenAddressIdx];
            delete tokenLocks[lockId];
        }else {
            // Update UserLocks info
            userLocks[lock.owner][tokenAddressIdx] = token;
        }
    }

    function transferLock(uint256 lockId, address newOwner) external onlyLockOwner(lockId) {
        require(newOwner != address(0), "ZERO NEW OWNER");
        Lock storage lock = tokenLocks[lockId];

        UserLocks memory token = UserLocks({
            lockId: lockId,
            token: lock.token,
            amount: lock.amount,
            unlockTime: lock.unlockTime,
            isLp: lock.isLp
        });
        
        uint256 tokenAddressIdx = indexOf(userLocks[lock.owner], token);
        delete userLocks[lock.owner][tokenAddressIdx];

        userLocks[newOwner].push(token);
        lock.owner = newOwner;
    }

    function transferFees() private {
        require(msg.value >= ethFee, "Fees are not enough!");
        transferEth(feeReceiver, ethFee);
    }

    function transferEth(address recipient, uint256 amount) private {
        payable(recipient).transfer(amount);
    }

    function userTokenLocks(address owner) external view returns (UserLocks[] memory){
        return userLocks[owner];
    }

    function checkIsLpToken(address lpToken, address factoryAddress) private view returns (bool){
        IPancakePair pair = IPancakePair(lpToken);
        address factoryPair = IPancakeFactory(factoryAddress).getPair(pair.token0(), pair.token1());
        return factoryPair == lpToken;
    }

    function setEthFee(uint256 newEthFee) external onlyOwner{
        ethFee = newEthFee;
    }

    function setFeeReceiver(address newFeeReceiver) external onlyOwner{
        feeReceiver = newFeeReceiver;
    }

    function chekBalance(address _token) public view returns (uint){
        return IERC20(_token).balanceOf(address(this));
    }

    function findLock(address tokenOrPool) external view returns (Lock memory token) {
        for (uint256 index = 0; index < lockNonce; index++) {
            if(tokenLocks[index].token == tokenOrPool){
                token = tokenLocks[index];

                return token;
            }
        }
        revert("Not Found");
    }

    function findLockOwner(address tokenOrPool, address owner) external view returns (Lock memory token) {
        for (uint256 index = 0; index < lockNonce; index++) {
            if(tokenLocks[index].token == tokenOrPool && tokenLocks[index].owner == owner){
                token = tokenLocks[index];

                return token;
            }
        }
        revert("Not Found");
    }

    function indexOf(UserLocks[] memory arr, UserLocks memory searchFor) private pure returns (uint256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].lockId == searchFor.lockId) {
                return i;
            }
        }
        revert("Not Found");
    }
}
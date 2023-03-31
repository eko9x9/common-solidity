// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/library/SafeERC20.sol";
import "../utils/library/SafeMath.sol";
import "../utils/library/Ownable.sol";
import "../utils/library/ReentrancyGuard.sol";

contract LockToken is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public feeReceiver;
    uint256 public ethFee;
    
    struct Lock {
        address token;
        uint amount;
        uint endtime;
        address owner;
    }

    mapping(address => address[]) private userLocks;

    modifier onlyLockOwner(uint lockId) {
        Lock storage lock = tokenLocks[lockId];
        require(lock.owner == address(msg.sender), "NO ACTIVE LOCK OR NOT OWNER");
        _;
    }

    constructor (address _feeReciver, uint256 _ethFee) {
        feeReceiver = _feeReciver;
        ethFee = _ethFee;
    }

    uint256 public lockNonce = 0;
    mapping(uint256 => Lock) public tokenLocks;

    function deposit(address _token, uint256 _amount, uint _lockTime) external payable nonReentrant returns (uint256 lockId){
        require(_amount > 0, "ZERO AMOUNT");
        require(_lockTime > block.timestamp, "UNLOCK TIME IN THE PAST");
        require(_lockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        transferFees();
        if(msg.value > ethFee){
            transferEth(msg.sender, msg.value.sub(ethFee));
        }

        lockId = lockNonce++;
        tokenLocks[lockId] = Lock(_token, _amount, _lockTime, msg.sender);
        userLocks[msg.sender].push(_token);

        IERC20(_token).transferFrom(msg.sender, address(this),_amount);

        return lockId;
    }

    function extendLockTime(uint256 lockId, uint256 newUnlockTime) external nonReentrant onlyLockOwner (lockId) {
        require(newUnlockTime > block.timestamp, "UNLOCK TIME IN THE PAST");
        require(newUnlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        Lock storage lock = tokenLocks[lockId];
        require(lock.endtime < newUnlockTime, "NOT INCREASING UNLOCK TIME");
        lock.endtime = newUnlockTime;
    }

    function increaseLockAmount(uint256 lockId, uint256 amountToIncrement) external nonReentrant onlyLockOwner(lockId) {
        require(amountToIncrement > 0, "ZERO AMOUNT");
        Lock storage lock = tokenLocks[lockId];

        lock.amount = lock.amount.add(amountToIncrement);
        IERC20(lock.token).safeTransferFrom(msg.sender, address(this), amountToIncrement);
    }
    
    function withdraw(uint256 lockId) external nonReentrant onlyLockOwner(lockId) { 
        Lock memory lock = tokenLocks[lockId];
        require(block.timestamp > lock.endtime, "You must to attend your locktime!");
        IERC20(lock.token).transfer(msg.sender, lock.amount);

        //clean up storage to save gas
        uint256 lpAddressIndex = indexOf(userLocks[lock.owner], lock.token);
        delete userLocks[lock.owner][lpAddressIndex];
    }

    function withdrawPartially(uint256 lockId, uint256 amount) public nonReentrant onlyLockOwner(lockId) {
        Lock memory lock = tokenLocks[lockId];
        require(block.timestamp > lock.endtime, "You must to attend your locktime!");

        IERC20(lock.token).transfer(msg.sender, amount);

        if(lock.amount == 0) {
            //clean up storage to save gas
            uint256 lpAddressIndex = indexOf(userLocks[lock.owner], lock.token);
            delete userLocks[lock.owner][lpAddressIndex];
        }
    }

    function transferLock(uint256 lockId, address newOwner) external onlyLockOwner(lockId) {
        require(newOwner != address(0), "ZERO NEW OWNER");
        Lock storage lock = tokenLocks[lockId];

        uint256 tokenAddressIdx = indexOf(userLocks[lock.owner], lock.token);
        delete userLocks[lock.owner][tokenAddressIdx];
        userLocks[newOwner].push(lock.token);

        lock.owner = newOwner;
    }

    function transferFees() private {
        require(msg.value >= ethFee, "Fees are not enough!");
        transferEth(feeReceiver, ethFee);
    }

    function transferEth(address recipient, uint256 amount) private {
        payable(recipient).transfer(amount);
    }

    function userLockToken(address owner) external view returns (address[] memory){
        return userLocks[owner];
    }

    function chekBalance(address _token) public view returns (uint){
        return IERC20(_token).balanceOf(address(this));
    }

    function setEthFee(uint256 newEthFee) external onlyOwner{
        ethFee = newEthFee;
    }

    function setFeeReceiver(address newFeeReceiver) external onlyOwner{
        feeReceiver = newFeeReceiver;
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
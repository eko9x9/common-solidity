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

    function lockLiquidity(address lpToken, uint256 amount, uint256 unlockTime, address payable withdrawer, address pair) external payable nonReentrant returns (uint256 lockId) {
        require(amount > 0, "ZERO AMOUNT");
        require(lpToken != address(0), "ZERO TOKEN");
        require(unlockTime > block.timestamp, "UNLOCK TIME IN THE PAST");
        require(unlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        require(checkIsLpToken(lpToken, pair), "NOT PAIR");

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

    function checkIsLpToken(address lpToken, address factoryAddress) private view returns (bool){
        IPancakePair pair = IPancakePair(lpToken);
        address factoryPair = IPancakeFactory(factoryAddress).getPair(pair.token0(), pair.token1());
        return factoryPair == lpToken;
    }

    function transferFees() private {
        require(msg.value >= ethFee, "Fees are not enough!");
        transferEth(feeReceiver, ethFee);
    }

    function transferEth(address recipient, uint256 amount) private {
        (bool res,  ) = recipient.call{value: amount}("");
        require(res, "BNB TRANSFER FAILED");
    }

    function userLockTokens(address adress) external view returns (address[] memory){
        return userLocks[adress];
    }
}
// SPDX-License-Identifier: MIT

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract TokenStake is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public stakeNonce;

    struct StakedInfo {
        uint256 totalAmount;
        uint256 totalStaked;
    }

    struct Stake {
        uint256 lockTime;
        uint256 interestRate;
        uint256 allocPercent;
    }

    struct UserStake {
        uint256 idTypeStake;
        uint256 startTime;
        uint256 lockTime;
        uint256 amount;
    }

    StakedInfo public stakedInfo;
    mapping(uint256 => StakedInfo) public stakedPerTypeInfo;
    mapping(uint256 => Stake) public typeStake;
    mapping(address => UserStake[]) public userStake;
    uint256[] public typeStakeIds;
    IERC20 public tokenStake;
    uint256 public minStake = 10000;
    uint256 public rewardDistributed = 0;

    uint256 private oneHundred = 100; 
    uint256 private oneThousand = 1000; 
    uint256 private oneHundredThousand = 100000; 
    uint256 private unixInADay = 86400;

    constructor(IERC20 _tokenStake) {
        tokenStake = _tokenStake;
    }

    function staking(uint256 idTypeStake, uint256 amount) public {
        require(typeStake[idTypeStake].lockTime != 0 && typeStake[idTypeStake].interestRate != 0, "Id stake not found");
        require(!_checkExistStake(idTypeStake, msg.sender), "Already stake");
        require(amount > minStake, "Less than minimum stake");
        require(_calcAllocPercent(idTypeStake, amount) <= typeStake[idTypeStake].allocPercent, "Max allocation supply reached!");
        tokenStake.transferFrom(msg.sender, address(this), amount);

        userStake[msg.sender].push(
            UserStake({
                idTypeStake: idTypeStake,
                startTime: block.timestamp,
                lockTime: block.timestamp.add(typeStake[idTypeStake].lockTime),
                amount: amount
            })
        );
        stakedPerTypeInfo[idTypeStake] = StakedInfo({
            totalAmount: stakedPerTypeInfo[idTypeStake].totalAmount.add(amount),
            totalStaked: stakedPerTypeInfo[idTypeStake].totalStaked.add(1)
        });
        stakedInfo = StakedInfo({
            totalAmount: stakedInfo.totalAmount.add(amount),
            totalStaked: stakedInfo.totalStaked.add(1)
        });
        stakeNonce++;
    }

    function addAmountStake(uint256 idTypeStake, uint256 amount) public  {
        require(_checkExistStake(idTypeStake, msg.sender), "No stake");
        UserStake memory staked = findStake(idTypeStake, msg.sender);
        require(_calcAllocPercent(idTypeStake, staked.amount.add(amount)) <= typeStake[idTypeStake].allocPercent, "Max allocation supply reached!");
        tokenStake.transferFrom(msg.sender, address(this), amount);

        UserStake memory updateStake = UserStake({
            idTypeStake: staked.idTypeStake,
            startTime: block.timestamp,
            lockTime: block.timestamp.add(typeStake[idTypeStake].lockTime),
            amount: staked.amount.add(amount)
        });
        _updateUserStake(idTypeStake, msg.sender, updateStake);

        stakedPerTypeInfo[idTypeStake] = StakedInfo({
            totalAmount: stakedPerTypeInfo[idTypeStake].totalAmount.add(amount),
            totalStaked: stakedPerTypeInfo[idTypeStake].totalStaked
        });
        stakedInfo = StakedInfo({
            totalAmount: stakedInfo.totalAmount.add(amount),
            totalStaked: stakedInfo.totalStaked
        });
    }

    function withdraw(uint256 idTypeStake) public {    
        require(_checkExistStake(idTypeStake, msg.sender), "No stake");
        require(findStake(idTypeStake, msg.sender).lockTime < block.timestamp, "Stake is not over yet");
        uint256 reward = calculateRewards(idTypeStake, msg.sender);
        uint256 totalSend = reward.add(findStake(idTypeStake, msg.sender).amount);
        tokenStake.transferFrom(msg.sender, address(this), totalSend);
        
        rewardDistributed.add(reward);
        _removeUserStake(idTypeStake, msg.sender);
    }

    function claim(uint256 idTypeStake) public {
        require(_checkExistStake(idTypeStake, msg.sender), "No stake");
        require(findStake(idTypeStake, msg.sender).lockTime < block.timestamp, "Stake is not over yet");
        uint256 reward = calculateRewards(idTypeStake, msg.sender);
        tokenStake.transferFrom(msg.sender, address(this), reward);
        
        rewardDistributed.add(reward);
        UserStake memory staked = findStake(idTypeStake, msg.sender);
        UserStake memory updateStake = UserStake({
            idTypeStake: staked.idTypeStake,
            startTime: block.timestamp,
            lockTime: block.timestamp.add(typeStake[idTypeStake].lockTime),
            amount: staked.amount
        });
        
        _updateUserStake(idTypeStake, msg.sender, updateStake);
    }

    function addTypeStake(uint256 idTypeStake, Stake calldata stake) external onlyOwner {
        require(typeStake[idTypeStake].lockTime == 0 && typeStake[idTypeStake].interestRate == 0, "Id stake must be unique");
        typeStake[idTypeStake] = stake;
        typeStakeIds.push(idTypeStake);
    }

    function updateTypeStake(uint256 idTypeStake, Stake calldata stake) external onlyOwner {
        require(typeStake[idTypeStake].lockTime != 0 && typeStake[idTypeStake].interestRate != 0, "Id stake not found");
        typeStake[idTypeStake] = stake;
    }

    function removeTypeStake(uint256 idTypeStake) external onlyOwner {
        delete typeStake[idTypeStake];
        for (uint i = 0; i < typeStakeIds.length; i++) {
            if(typeStakeIds[i] == idTypeStake){
                typeStakeIds[i] = typeStakeIds[typeStakeIds.length - 1];
                typeStakeIds.pop();
            }
        }
    }

    function emergency(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function _updateUserStake(uint256 idTypeStake, address user, UserStake memory update) private {
        for (uint i = 0; i < userStake[user].length; i++) {
            if(userStake[user][i].idTypeStake == idTypeStake){
                userStake[user][i] = update;
            }
        }
    }

    function _removeUserStake(uint256 idTypeStake, address user) private {
        for (uint i = 0; i < userStake[user].length; i++) {
            if(userStake[user][i].idTypeStake == idTypeStake){
                userStake[user][i] = userStake[user][userStake[user].length - 1];
                userStake[user].pop();

                stakedPerTypeInfo[idTypeStake] = StakedInfo({
                    totalAmount: stakedPerTypeInfo[idTypeStake].totalAmount.sub(userStake[user][i].amount),
                    totalStaked: stakedPerTypeInfo[idTypeStake].totalStaked.sub(1)
                });
                stakedInfo = StakedInfo({
                    totalAmount: stakedInfo.totalAmount.sub(userStake[user][i].amount),
                    totalStaked: stakedInfo.totalStaked.sub(1)
                });
            }
        }
    }

    function _calcAllocPercent(uint256 idTypeStake, uint256 amountStake) public view returns(uint256) {
        uint256 supplyToken = tokenStake.balanceOf(address(this));
        return stakedPerTypeInfo[idTypeStake].totalAmount.add(amountStake).mul(100).div(supplyToken);
    }

    function _checkExistStake(uint256 idTypeStake, address user) private view returns(bool) {
        for (uint i = 0; i < userStake[user].length; i++) {
            if(userStake[user][i].idTypeStake == idTypeStake){
                return true;
            }
        }
        return false;
    }

    function calculateRewards(uint256 idTypeStake, address user) public view returns(uint256) {
        UserStake memory staked = findStake(idTypeStake, user);
        uint256 unixTimeStake = staked.lockTime.sub(staked.startTime);
        uint256 daysCount = unixTimeStake.div(unixInADay);
        
        return _calculateInterest(staked.amount, typeStake[idTypeStake].interestRate, daysCount);
    }

    function _calculateInterest(uint256 amount, uint256 rate, uint256 inADays) private view returns(uint256) {
        return amount.mul(rate).mul((inADays.mul(oneThousand).div(365))).div(oneHundredThousand);
    }

    function userStaked(address user) external view returns(UserStake[] memory) {
        return userStake[user];
    }

    function findStake(uint256 idTypeStake, address user) public view returns(UserStake memory stake) {
        for (uint i = 0; i < userStake[user].length; i++) {
            if(userStake[user][i].idTypeStake == idTypeStake){
                stake = userStake[user][i];
            }
        }
    }

    function userStakeLength(address user) public view returns(uint256) {
        return userStake[user].length;
    }

    function getAllTypeStake() public view returns(uint256[] memory) {
        return typeStakeIds;
    }

    function typeStakeLength() public view returns(uint) {
        return typeStakeIds.length;
    }
}
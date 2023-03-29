// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SafeERC20.sol";
import "../../../utils/library/SafeMath.sol";
import "../Interfaces.sol";
import "../../../utils/library/Ownable.sol";
import "../../../utils/library/ReentrancyGuard.sol";
contract ArbistaleVault is ReentrancyGuard {
    // Library usage
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum TypeStake { LOCK, FLEXIBLE }

    struct TokenStake {
        uint amount;
        uint startTime;
        TypeStake typeStake;
    }

    // Fee on stake
    uint public feeStake = 0;
    // Max stake
    uint public maxAmountStake = 0;
    // 7 Days (7 * 24 * 60 * 60)
    uint public lockDuration = 604800;
    // 1 Days (1 * 24 * 60 * 60)
    uint public flexibleStakeDuration = 86400;
    // Reward rate token
    uint16 public rewardRateLockStake;
    uint16 public rewardRateFlexibleStake;
    /**
     * @notice The stakes for each stakeholder.
     */
    mapping(address => TokenStake) public stakes;
    /**
     * @notice The stakes for each stakeholder.
     */
    mapping(address => uint) public totalStakedToken;
    /**
     * @notice token stored to distribute reward
     */
    mapping(address => uint) internal tokenStored;
    address[] public stakeHolders;
    // dev address
    address public dev;

    // staking provaider token
    IERC20 public stakeProvaider;

    constructor(address _tokenProvaider, address _devAddress, uint _durationFlexibleStake, uint _durationLockStake, uint16 _rewardRateFlexibleStake, uint16 _rewardRateLockStake, uint _maxAmountStake) nonReentrant {
        maxAmountStake = _maxAmountStake;
        flexibleStakeDuration = _durationFlexibleStake;
        lockDuration = _durationLockStake;
        rewardRateLockStake = _rewardRateLockStake;
        rewardRateFlexibleStake = _rewardRateFlexibleStake;
        dev = _devAddress;

        stakeProvaider = IERC20(_tokenProvaider);
    }

    modifier onlyDev() {
        require(msg.sender == dev, "Whut?");
        _;
    }

    function stakeFlexible(uint _amount)
        public
        nonReentrant
    {
        require(_amount > 0, "amount = 0");
        require(maxAmountStake >= _amount, "Tokens exceed max stake!");
        // amount stake with fee
        uint amountStake = _amount + _amount * (feeStake / 1000);
        // check is the address already stakes
        if(!isStakeHolder(msg.sender)){
            // Add amount token stake holder
            stakes[msg.sender] = TokenStake(
                amountStake,
                block.timestamp,
                TypeStake.FLEXIBLE
            );
            stakeHolders.push(msg.sender);
        }else {
            require(stakes[msg.sender].typeStake == TypeStake.FLEXIBLE, "Account is on stake type lock!.");
            _addStake(amountStake);
        }

        stakeProvaider.safeTransferFrom(msg.sender, address(this), _amount);
        _updateTokenStored(address(stakeProvaider), tokenStored[address(stakeProvaider)] + _amount);
        _updateTotalStaked(address(stakeProvaider), totalStakedToken[address(stakeProvaider)] + amountStake);
    }

    function stakeLock(uint _amount)
        public
        nonReentrant
    {
        require(_amount > 0, "amount = 0");
        require(maxAmountStake >= _amount, "Tokens exceed max stake!");
        // amount stake with fee
        uint amountStake = _amount + _amount * (feeStake / 1000);
        // check is the address already stakes
        if(!isStakeHolder(msg.sender)){
            // Add amount token stake holder
            stakes[msg.sender] = TokenStake(
                amountStake,
                block.timestamp,
                TypeStake.LOCK
            );
            stakeHolders.push(msg.sender);
        }else {
            require(stakes[msg.sender].typeStake == TypeStake.LOCK, "Account is on stake type flexible!.");
            _addStake(amountStake);
        }

        stakeProvaider.safeTransferFrom(msg.sender, address(this), _amount);
        _updateTokenStored(address(stakeProvaider), tokenStored[address(stakeProvaider)] + _amount);
        _updateTotalStaked(address(stakeProvaider), totalStakedToken[address(stakeProvaider)] + amountStake);
    }

    function unstake() public nonReentrant {
        require(isStakeHolder(msg.sender), "Account not stake yet!");
        require(stakes[msg.sender].typeStake != TypeStake.LOCK, "Cannot unstake lock stake");
        uint amount = stakes[msg.sender].amount;

        if(tokenStored[address(stakeProvaider)] < amount){
            _requestTransferToAddressFromStakeProvaiderIfBalanceNotEnough(msg.sender, amount);
        }else {
            stakeProvaider.transfer(msg.sender, amount);
            _updateTokenStored(address(stakeProvaider), tokenStored[address(stakeProvaider)] - amount);
        }
        _updateTotalStaked(address(stakeProvaider), totalStakedToken[address(stakeProvaider)] - amount);

        delete stakes[msg.sender];
        for (uint256 s = 0; s < stakeHolders.length ; s += 1){
            if (msg.sender == stakeHolders[s]) {
                delete stakeHolders[s];
                break;
            }
        }
    }

    function claimRewardFlexibleStake() public nonReentrant {
        uint reward = rewardOfFlexibleStake(msg.sender);
        require(isStakeHolder(msg.sender), "Account not stake yet!");
        require(reward != 0, "Stake time is not over yet");

        _transferReward(msg.sender, reward);
        _resetStartTimeStakeUser(msg.sender);
    }

    function claimRewardLockStake() public nonReentrant {
        uint reward = rewardOfLockStake(msg.sender);
        require(isStakeHolder(msg.sender), "Account not stake yet!");
        require(reward != 0, "Stake time is not over yet");

        _transferReward(msg.sender, reward);
        _resetStartTimeStakeUser(msg.sender);
    }

    function claimRewardLockStakeAndUnstake() public nonReentrant {
        require(isStakeHolder(msg.sender), "Account not stake yet!");
        uint reward = rewardOfLockStake(msg.sender);
        require(reward != 0, "Stake time is not over yet");

        _transferReward(msg.sender, stakes[msg.sender].amount + reward);
        _updateTotalStaked(address(stakeProvaider), totalStakedToken[address(stakeProvaider)] - stakes[msg.sender].amount);
        
        delete stakes[msg.sender];
        for (uint256 s = 0; s < stakeHolders.length ; s += 1){
            if (msg.sender == stakeHolders[s]) {
                delete stakeHolders[s];
                break;
            }
        }
    }

    function isStakeHolder(address _address)
        public
        view
        returns(bool)
    {
        for (uint256 s = 0; s < stakeHolders.length ; s += 1){
            if (_address == stakeHolders[s]) {
                return (true);
            }
        }

        return false;
    }

    /**
     * @dev set stake provaider to give rewards or any
     */
    function setStakeProvaider(address _stakeProvaider)
        external
        onlyDev
    {
        stakeProvaider = IERC20(_stakeProvaider);
    }

    /**
     * @dev set reward rate of token / 1000
     */
    function setRewardRateLockStake(uint16 _rate)
        external
        onlyDev
    {
        rewardRateLockStake = _rate;
    }

    /**
     * @dev set reward rate of token / 1000
     */
    function setRewardRateFlexibleStake(uint16 _rate)
        external
        onlyDev
    {
        rewardRateFlexibleStake = _rate;
    }

    /**
     * @dev set fee on stake / 1000
     */
    function setFeeStake(uint _feeStake)
        external
        onlyDev
    {
        feeStake = _feeStake;
    }

    /**
     * @dev set duration in seconds
     */
    function setDurationLockStake(uint _duration) external onlyDev {
        lockDuration = _duration;
    }

    function setMaxStake(uint _amountStake) external onlyDev {
        maxAmountStake = _amountStake;
    }

    function setDurationFlexibleReward(uint _duration) external onlyDev {
        flexibleStakeDuration = _duration;
    }

    function stakingBalance(address _tokenAddress) external view returns(uint) {
        return tokenStored[_tokenAddress];
    }

    function stakingLength() public view returns(uint) {
        return stakeHolders.length;
    }

    function rewardOfFlexibleStake(address _account)
        public
        view
        returns (uint)
    {
        require(stakes[_account].typeStake == TypeStake.FLEXIBLE, "Account not stake on flexible stake!.");
        uint timeNow = block.timestamp;

        uint longStake = stakes[_account].startTime + flexibleStakeDuration;

        if(longStake > timeNow){
            return 0;
        }else {
            uint rate = rewardRateFlexibleStake;
            uint reward =  stakes[_account].amount * rate / 1000 ;
            uint unclaimedStake = _checkUnclaimedTimes(_account, stakes[_account].typeStake);

            return reward.mul(unclaimedStake);
        }
    }

    function rewardOfLockStake(address _account)
        public
        view
        returns (uint)
    {
        require(stakes[_account].typeStake == TypeStake.LOCK, "Account not stake on lock stake!.");
        uint timeNow = block.timestamp;

        uint longStake = stakes[_account].startTime + lockDuration;

        if(longStake > timeNow){
            return 0;
        }else {
            uint rate = rewardRateLockStake;
            uint reward =  stakes[_account].amount * rate / 1000 ;
            uint unclaimedStake = _checkUnclaimedTimes(_account, stakes[_account].typeStake);

            return reward.mul(unclaimedStake);
        }
    }

    function stakeTypeOf(address _account) public view returns(TypeStake) {
        require(isStakeHolder(_account), "Nothing stake!.");
        return stakes[_account].typeStake;
    }

    function stakeAmountOf(address _account) public view returns(uint) {
        require(isStakeHolder(_account), "Nothing stake!.");
        return stakes[_account].amount;
    }

    function currentTime() public view returns(uint) {
        return block.timestamp;
    }

    function _checkUnclaimedTimes(address _holderAddress, TypeStake _typeStake) private view returns(uint){
        require(stakes[_holderAddress].typeStake == _typeStake, "Account not stake on this type!.");

        uint timeNow = block.timestamp;
        uint typeStakeDuration = _typeStake == TypeStake.FLEXIBLE ? flexibleStakeDuration : lockDuration;
        uint userLongStake = stakes[_holderAddress].startTime + typeStakeDuration;
        uint totalUnclaimed = timeNow.sub(userLongStake) / typeStakeDuration;

        return totalUnclaimed.add(1);
    }

    function _addStake(uint _amount)
        private
    {
        require(isStakeHolder(msg.sender), "Address are not stake holder");
        require(maxAmountStake >= _amount, "Tokens exceed max stake!");

        stakes[msg.sender].amount = stakes[msg.sender].amount.add(_amount);
        stakes[msg.sender].startTime = block.timestamp;
        _updateTokenStored(address(stakeProvaider), tokenStored[address(stakeProvaider)] + _amount);
        _updateTotalStaked(address(stakeProvaider), totalStakedToken[address(stakeProvaider)] + _amount);
    }

    function _resetStartTimeStakeUser(address _account) private {
        require(isStakeHolder(_account) == true, "Address are not stake holder");
        stakes[msg.sender].startTime = block.timestamp;
    }

    function _transferReward(address _to, uint _amountReward) private {
        uint amountTokenStored = tokenStored[address(stakeProvaider)];

        if(amountTokenStored < _amountReward){
            _requestTransferToAddressFromStakeProvaiderIfBalanceNotEnough(_to, _amountReward);
        }else {
            stakeProvaider.safeTransfer(_to, _amountReward);
            _updateTokenStored(address(stakeProvaider), amountTokenStored - _amountReward);
        }
    }

    function _requestTransferToAddressFromStakeProvaiderIfBalanceNotEnough(address _account, uint _amount) private {
        stakeProvaider.transferFrom(address(stakeProvaider), _account, _amount);
    }

    function _updateTokenStored(address _tokenStored, uint _amount) private {
        tokenStored[_tokenStored] =  _amount;
    }

    function _updateTotalStaked(address _token, uint _amount) private {
        totalStakedToken[_token] =  _amount;
    }

    function addToken(IERC20 _token, uint _amount) external onlyDev nonReentrant {
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _updateTokenStored(address(_token), tokenStored[address(_token)] + _amount);
    }

    function sendBackTokenToProvaider(uint _amount) external onlyDev nonReentrant {
        stakeProvaider.safeTransfer(address(stakeProvaider), _amount);
        _updateTokenStored(address(stakeProvaider), tokenStored[address(stakeProvaider)] - _amount);
    }

    function removeStoredToken(IERC20 _token, uint _amount) external onlyDev nonReentrant {
        _token.safeTransfer(msg.sender, _amount);
        _updateTokenStored(address(_token), tokenStored[address(_token)] - _amount);
    }

    function requestBalanceFromStakeProvaider(uint _amount) external onlyDev nonReentrant  {
        stakeProvaider.transferFrom(address(stakeProvaider), address(this), _amount);
        _updateTokenStored(address(stakeProvaider), tokenStored[address(stakeProvaider)] + _amount);
    }

    function withdraw() external onlyDev nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setDev(address _devAddress) external onlyDev {
        dev = _devAddress;
    }
}
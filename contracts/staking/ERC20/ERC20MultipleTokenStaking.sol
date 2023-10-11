// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SafeERC20.sol";
import "../../utils/library/SafeMath.sol";
import "../Interfaces.sol";
import "../../utils/contracts/Ownable.sol";
import "../../utils/contracts/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {
    // Library usage
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct TokenStake {
        address tokenStake;
        uint amount;
        uint startTime;
    }

    // Fee on stake
    uint public feeStake = 0;
    // Max stake
    uint public maxAmountStake = 0;
    // Duration of rewards to be paid out (in seconds)
    // 7 Days (7 * 24 * 60 * 60)
    uint public duration = 604800;
    // Reward rate token
    mapping(address => uint128) public rewardRate;
    // Token stake allowed
    mapping(address => bool) public tokenStakeAllowed;
    /**
     * @notice The stakes for each stakeholder.
     */
    mapping(address => TokenStake[]) internal stakes;
    /**
     * @notice token stored to distribute reward
     */
    mapping(address => uint) internal tokenStored;

    // swap to different token
    IROUTER private swapper;

    // staking provaider token
    IERC20 public stakeProvaider;

    constructor(address _tokenProvaider, uint _durationStake, uint16 _rewardRate, uint _maxAmountStake, address _swapperRouter) {
        tokenStakeAllowed[_tokenProvaider] = true;
        maxAmountStake = _maxAmountStake;
        rewardRate[_tokenProvaider] = _rewardRate;
        duration = _durationStake;

        stakeProvaider = IERC20(_tokenProvaider);
        swapper = IROUTER(_swapperRouter);
    }

    function stake(address _tokenStake, uint _amount)
        public
        nonReentrant
    {
        require(_amount > 0, "amount = 0");
        require(tokenStakeAllowed[_tokenStake] == true, "Token not allowed to stake!");
        require(maxAmountStake >= _amount, "Tokens exceed max stake!");
        // amount stake with fee
        uint amountStake = _amount + _amount * (feeStake / 1000);
        // check is the address already stakes
        if(!isStakeholder(_tokenStake, msg.sender)){
            // Add amount token stake holder
            stakes[msg.sender].push(TokenStake(
                _tokenStake,
                amountStake,
                block.timestamp
            ));
        }else {
            _addStake(_tokenStake, amountStake);
        }

        if(_tokenStake == address(stakeProvaider)){
            stakeProvaider.safeTransferFrom(msg.sender, address(this), _amount);
        }else {
            IERC20 tokenToStake = IERC20(_tokenStake);
            tokenToStake.safeTransferFrom(msg.sender, address(this), _amount);
        }
        
    }

    function claimReward(IERC20 _tokenStake)
        public
        nonReentrant
    {
        uint rewardToken = rewardOf(msg.sender, address(_tokenStake));
        require(rewardToken != 0, "Stake Time is not over yet");
        _transferReward(address(_tokenStake), msg.sender, rewardToken);
        _resetStartStakeUser(msg.sender, address(_tokenStake));
    }

    function isStakeholder(address _tokenStake, address _address)
        public
        view
        returns(bool)
    {
        if(stakes[_address].length != 0){
            for (uint256 s = 0; s < stakes[_address].length ; s += 1){
                if (_tokenStake == stakes[_address][s].tokenStake) {
                    return (true);
                }
            }

            return (false);
        }else {
            return (false);
        }
    }

    function rewardOf(address _account, address _tokenStake)
        public
        view
        returns (uint)
    {
        require(isStakeholder(_tokenStake, _account) == true, "Account not holder");
        uint timeNow = block.timestamp;
        uint userTimeStake;
        uint amountUserStake;

        for (uint256 s = 0; s < stakes[_account].length ; s += 1){
            if (_tokenStake == stakes[_account][s].tokenStake) {
                amountUserStake = stakes[_account][s].amount;
                userTimeStake = stakes[_account][s].startTime;
                break;
            }
        }

        uint longStake = userTimeStake + duration;
        if(longStake > timeNow){
            return 0;
        }else {
            uint rate = rewardRate[_tokenStake];
            uint reward =  amountUserStake * rate / 1000 ;

            return reward;
        }

    }

    /**
     * @dev set stake provaider to give rewards or any
     */
    function setStakeProvaider(address _stakeProvaider)
        external
        onlyOwner
    {
        stakeProvaider = IERC20(_stakeProvaider);
    }

    /**
     * @dev add or update token stake allowed
     */
    function addOrUpdateTokenStakeAllowed(address _tokenAddress, bool _isAllowed)
        external
        onlyOwner
    {
        tokenStakeAllowed[_tokenAddress] = _isAllowed;
    }

    /**
     * @dev set reward rate of token / 1000
     */
    function setRewardRate(address _token, uint128 _rate)
        external
        onlyOwner
    {
        require(tokenStakeAllowed[_token] == true, "Token not allowed to stake!.");
        rewardRate[_token] = _rate;
    }

    /**
     * @dev set fee on stake / 1000
     */
    function setFeeStake(uint _feeStake)
        external
        onlyOwner
    {
        feeStake = _feeStake;
    }

    /**
     * @dev set duration in seconds
     */
    function setDuration(uint _duration) external onlyOwner {
        duration = _duration;
    }

    function _swapToken(address _tokenToSwap, uint _amount) private {
        address[] memory path = new address[](2);
        path[0] = address(stakeProvaider);
        path[1] = _tokenToSwap;

        swapper.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, 35, path, address(this), block.timestamp + duration);
    }

    function _addStake(address _tokenStake, uint _amount)
        private
    {
        require(isStakeholder(_tokenStake, msg.sender) == true, "You are not stake holder");
        require(maxAmountStake >= _amount, "Tokens exceed max stake!");
        for (uint256 s = 0; s < stakes[msg.sender].length ; s += 1){
            if (_tokenStake == stakes[msg.sender][s].tokenStake){
                stakes[msg.sender][s].amount = stakes[msg.sender][s].amount.add(_amount);
                stakes[msg.sender][s].startTime = block.timestamp;
            }
        }
    }

    function _resetStartStakeUser(address _tokenStake, address _account) private {
        require(isStakeholder(_tokenStake, _account) == true, "You are not stake holder");
        for (uint256 s = 0; s < stakes[_account].length ; s += 1){
            if (_tokenStake == stakes[_account][s].tokenStake){
                stakes[_account][s].startTime = block.timestamp;
            }
        }
    }

    function _transferReward(address _tokenStake, address _to, uint _amountReward) private {
        uint amountTokenStored = tokenStored[_tokenStake];
        IERC20 tokenStoredStaking = IERC20(_tokenStake);

        if(amountTokenStored < _amountReward){
            if(_tokenStake == address(stakeProvaider)){
                stakeProvaider.safeTransferFrom(address(stakeProvaider), msg.sender, _amountReward);
            }else {
                // From token stake provaider convert to another token

            }
        }else {
            if(_tokenStake == address(stakeProvaider)){
                tokenStoredStaking.safeTransfer(_to, _amountReward);
                _updateTokenStored(address(tokenStoredStaking), tokenStored[address(tokenStoredStaking)] - _amountReward);
            }else {
                // From token stake provaider convert to another token
                _updateTokenStored(address(tokenStoredStaking), tokenStored[address(tokenStoredStaking)] - _amountReward);
            }
        }
    }

    function _updateTokenStored(address _tokenStored, uint _amount) private {
        tokenStored[_tokenStored] =  _amount;
    }

    function _calculatePriceToken(address _tokenAddress) private view returns(uint) {
        
    }

    function _tokenPriceProvaider()
        private
        view
        returns (uint)
    {

    }

    /**
     * @dev getBnbPrice in busd
     */
    function getBnbPrice()
        public
        view
        returns (uint)
    {
        address[] memory path = new address[](2);
        path[0] = swapper.WETH();
        path[1] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        uint ethGwei = 1000000000;

        uint[] memory amountsOut = swapper.getAmountsOut(ethGwei, path);

        return amountsOut[1] / ethGwei;
    }

    function _min(uint x, uint y)
        private
        pure
        returns (uint)
    {
        return x <= y ? x : y;
    }

    function addStoredToken(IERC20 _token, uint _amount) external onlyOwner {
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        tokenStored[address(_token)] = tokenStored[address(_token)].add(_amount);
    }

    function removeStoredToken(IERC20 _token) external onlyOwner {
        uint balanceStaking = _token.balanceOf(address(this));
        require(balanceStaking != 0, "Token is empty!");
        _token.safeTransfer(owner(), balanceStaking);
        tokenStored[address(_token)] = 0;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SafeERC20.sol";
import "../../utils/SafeMath.sol";
import "../Interfaces.sol";
import "../../utils/Ownable.sol";
import "../../utils/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {
    // Library usage
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct TokenStake {
        address tokenStake;
        uint amount;
        uint startTime;
    }

    struct Rewards {
        address tokenStake;
        uint amount;
    }

    struct RewardRate {
        address tokenStake;
        uint16 rate;
    }

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Reward to be paid out per second
    mapping(address => RewardRate[]) internal rewardRate;
    // User address => rewards to be claimed
    mapping(address => Rewards[]) internal rewards;
    // Token stake allowed
    address[] internal tokenStakeAllowed;
    /**
     * @notice The stakes for each stakeholder.
     */
    mapping(address => TokenStake[]) internal stakes;
    /**
     * @notice token stored to distribute reward
     */
    mapping(address => uint) internal tokenProvaiderStored;
     /**
     * @notice We usually require to know who are all the stakeholders.
     */
    address[] internal stakeholders;

    // swap to different token
    IROUTER internal swapper;

    // staking provaider token
    IERC20 public stakeProvaider;

    constructor(address _tokenProvaider, uint _durationStake, address _swapperRouter) {
        stakeProvaider = IERC20(_tokenProvaider);
        swapper = IROUTER(_swapperRouter);
        duration = _durationStake;
    }

    modifier updateReward(address _account) {

        if (_account != address(0)) {

        }

        _;
    }

    function stake(address _tokenStake, uint _amount) public nonReentrant {
        require(_amount > 0, "amount = 0");
        // check is the address already stakes
        if(isStakeholder(_tokenStake, msg.sender)){
            // Add amount token stake holder
            stakes[msg.sender].push(TokenStake(
                address(_tokenStake),
                _amount,
                block.timestamp
            ));
        }else {
            addStake(_tokenStake, _amount);
        }

        if(_tokenStake == address(stakeProvaider)){
            // _burn(msg.sender, _amount);
            // tokenProvaider.safeTransferFrom(msg.sender, address(this), _amount);
            
        }else {
            IERC20 tokenToStake = IERC20(_tokenStake);
            tokenToStake.safeTransferFrom(msg.sender, address(this), _amount);
        }
        
    }

    function addStake(address _tokenStake, uint _amount) private {
        
    }

    function feeStake() private {

    }

    function setFeeStake(uint _feeStake) external onlyOwner {

    }

    function withdraw(IERC20 _tokenStake, uint _amount) public nonReentrant updateReward(msg.sender) {
        // require(_amount > 0, "amount = 0");
        //  require(stakeInfos[_msgSender()].endTS < block.timestamp, "Stake Time is not over yet");
        // tokenProvaider.safeTransfer(msg.sender, _amount);
    }

    function isStakeholder(address _tokenStake, address _address)
        public
        view
        returns(bool)
    {
        if(stakes[_address].length != 0){
            for (uint256 s = 0; s < stakes[_address].length ; s += 1){
                if (_tokenStake == stakes[_address][s].tokenStake) return (true);
            }

            return (false);
        }else {
            return (false);
        }
    }

    /**
     * @dev set stake provaider to give rewards or any
     */
    function setStakeProvaider(address _stakeProvaider) external onlyOwner {
        stakeProvaider = IERC20(_stakeProvaider);
    }

    /**
     * @dev getBnbPrice in busd
     */
    function getBnbPrice() public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = swapper.WETH();
        path[1] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        uint ethGwei = 1000000000;

        uint[] memory amountsOut = swapper.getAmountsOut(ethGwei, path);

        return amountsOut[1] * ethGwei;
    }

    function tokenPriceProvaider() public view returns (uint){

    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}
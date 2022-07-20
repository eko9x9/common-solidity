// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./Interfaces.sol";

contract Staking is Ownable {
    // Library usage
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // boolean to prevent reentrancy
    bool internal locked;

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // User address => rewards to be claimed
    mapping(address => uint) internal rewards;

    /**
     * @notice token stored to distribute reward
     */
    mapping(address => uint) internal tokenProvaiderStored;
     /**
     * @notice We usually require to know who are all the stakeholders.
     */
    address[] internal stakeholders;

    struct TokenStake {
        address token;
        uint amount;
    }

    /**
     * @notice The stakes for each stakeholder.
     */
    mapping(address => TokenStake[]) internal stakes;
    // swap to different token
    IROUTER internal swapper;

    address[] public tokenProvaider;

    constructor(uint _durationStake, IROUTER _swapperRouter) {
        // Set the erc20 contract address which this timelock is deliberately paired to
        swapper = IROUTER(_swapperRouter);
        duration = _durationStake;
        // Initialize the reentrancy variable to not locked
        locked = false;
    }

    // Modifier
    /**
     * @dev Prevents reentrancy
     */
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier updateReward(address _account) {

        if (_account != address(0)) {

        }

        _;
    }

    function stake(uint _amount, address _tokenStake) external updateReward(msg.sender) noReentrant {
        require(_amount > 0, "amount = 0");
        // _burn(msg.sender, _amount);
        // if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender].push(TokenStake(_tokenStake, _amount));

        // tokenProvaider.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender) noReentrant {
        require(_amount > 0, "amount = 0");
        // tokenProvaider.safeTransfer(msg.sender, _amount);
    }

    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @dev add stake holder address
     */
    function addStakeholder(address _stakeholder)
        internal
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function setTokenProvaider() public onlyOwner {

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
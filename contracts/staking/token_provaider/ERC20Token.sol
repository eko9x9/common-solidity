// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../utils/interfaces/IERC20.sol";
import "../../utils/library/Ownable.sol";
import "../../utils/library/SafeMath.sol";
import "../../utils/library/Address.sol";
import "../../utils/interfaces/IPancakeFactory.sol";
import "../../utils/interfaces/IPancakeRouter.sol";

contract StakeProvaider is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    string private _name = "Simple Token";
    string private _symbol = "ST";
    uint8 private _decimals = 9;
    uint private _totalSupply = 1000000000 * 10**_decimals;
    address public _stakeService;

    modifier onlyStakeService() {
        require(msg.sender == _stakeService, "only stake service allowed");
        _;
    }

    constructor(){
        IPancakeRouterV2 pancakeRouter = IPancakeRouterV2(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 
        // create weth pair
        IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        _allowances[address(this)][address(pancakeRouter)] = _totalSupply;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function _approve(address owner, address spender, uint amount) private returns (bool) {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveStakeService(address _stakeServiceAddress) external onlyOwner returns (bool) {
        _stakeService = _stakeServiceAddress;
        _approve(address(this), _stakeServiceAddress, _totalSupply);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        
        return true;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }
    
     /**
    * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
    * the total supply.
    *
    * Requirements
    *
    * - `msg.sender` must be the token owner
    */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
    * @dev Burn `amount` tokens and decreasing the total supply.
    */
    function burn(uint256 amount) public onlyOwner returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
   * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
    * @dev See {BEP20-totalSupply}.
    */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev See {BEP20-balanceOf}.
    */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
    * @dev See {BEP20-allowance}.
    */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

}

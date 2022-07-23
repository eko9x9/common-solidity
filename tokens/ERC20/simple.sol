// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../utils/IERC20.sol";
import "../../utils/Ownable.sol";
import "../../utils/Safemath.sol";
import "../../utils/Address.sol";

contract SimpleToken is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint public _totalSupply = 100000;
    mapping(address => uint) public _balances;
    mapping(address => mapping(address => uint)) public _allowances;
    string public _name = "Simple Token";
    string public _symbol = "ST";
    uint8 public _decimals = 9;

    constructor(){

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

    function _approve(address owner, address spender, uint amount) private returns (bool) {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

        return true;
    }

    /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }


    function approveStakeService(address _stakeService) external onlyOwner returns (bool){
        _approve(address(this), _stakeService, _totalSupply);
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
    function burn(uint256 amount) public returns (bool) {
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

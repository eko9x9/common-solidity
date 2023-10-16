// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20_Token_Sample is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("ERC20 Token Sample1", "Sample 1") {
        _mint(msg.sender, 100_000_000_000 * 10**18 );
    }

    function mintTo(address user, uint amount) external onlyOwner {
        _mint(user, amount);
    }
}
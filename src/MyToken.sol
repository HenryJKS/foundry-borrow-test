// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable {
    constructor(
        address initialOwner
    ) ERC20("MyToken", "HJK") Ownable(initialOwner) {
        _mint(initialOwner, 1000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
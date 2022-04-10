pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Balloons is ERC20 {

    mapping(address => mapping (address => uint256)) allowed;

     /**
     * @notice Emitted when Approve() occurs.
     */
    //event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor() ERC20("WaterBalloons", "wBAL") {
        _mint(msg.sender, 1000 ether); // mints 1000 balloons!
    }

    //i attempted to bring the events in but I have no idea why the UI
    //is displaying columns for the liquidity - I have no idea where that 
    //is setup - I thought I changed everything I needed to in the app.jsx (now commented)
    //https://ethereum.org/en/developers/tutorials/erc20-annotated-code/
    //function approve(address spender, uint256 amount) public override returns (bool) {
    //    _approve(_msgSender(), spender, amount);
    //    emit Approval(_msgSender(), spender, amount);
    //    return true;
   /// }

}

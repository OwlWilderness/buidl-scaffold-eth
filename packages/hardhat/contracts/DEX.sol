// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this branch/repo. Also return variable names that may need to be specified exactly may be referenced (if you are confused, see solutions folder in this repo and/or cross reference with front-end code).
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */
    
    uint256 public totalLiquidity; //total liquidity of DEX
    mapping(address => uint256) public liquidity; //liquidity of an address

    using SafeMath for uint256; //outlines use of SafeMath for uint256 variables
    IERC20 token; //instantiates the imported contract

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap();

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap();

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided();

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved();

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) public {
        token = IERC20(token_addr); //specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). Loads contract up with both ETH and Balloons.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the number of LPTs minting as a result of deposits made to DEX contract
     * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) as equal to eth balance of contract.
     */
    function init(uint256 tokens) public payable returns (uint256) {
        //check total liquidiy of DEX
       
        require(totalLiquidity == 0, "DeX already initialized");   
        totalLiquidity = address(this).balance;

        //set liquidity of sender
        liquidity[msg.sender] = totalLiquidity;
        
        //transfer tokens 
        token.transferFrom(msg.sender, address(this), tokens);
        return totalLiquidity;
    }

    /**
     * @notice returns yOutput, or yDelta for xInput (or xDelta)
     * @dev Follow along with the [original tutorial](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90) Price section for an understanding of the DEX's pricing model and for a price function to add to your contract. You may need to update the Solidity syntax (e.g. use + instead of .add, * instead of .mul, etc). Deploy when you are done.
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public view returns (uint256 yOutput) {
        //this is what I had:
        //uint256 kInvariant = xReserves.mul(yReserves);
        //uint256 xOutput = xInput > 0 ? kInvariant.div(xInput) : 0;
        //return xOutput;
        
        //solution is something like this with fees
        //(xI * yR) / (xI + xR)
        //return xInput.mul(yReserves).div(xInput.add(xReserves));

        //solution from challenge
        uint256 xInputwithFee = xInput.mul(997);
        uint256 numerator = xInputwithFee.mul(yReserves);
        uint256 denominator = xReserves.mul(1000).add(xInputwithFee);
        return numerator.div(denominator);
   
        //should have read ahead (I wondered where those fees came from) and looked at this:
        //https://hackernoon.com/formulas-of-uniswap-a-deep-dive
        //
    }

    /**
     * @notice returns liquidity for a user. Note this is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
       //my solution:
        //uint256 xInput = msg.value;
        //uint256 xReserves = totalLiquidity;
        //uint256 yReserves = token.balanceOf(address(this));
        //return price(xInput, xReserves, yReserves);
        
        //solution from challenge:
        require(msg.value > 0, 'please submit some eth');
        uint256 xInput = msg.value;
        uint256 xReserves = address(this).balance.sub(msg.value);
        uint256 yReserves = token.balanceOf(address(this));
        
        tokenOutput = price(xInput, xReserves, yReserves);
        require(token.transfer(msg.sender, tokenOutput),"could not complete swap"); 
        emit EthToTokenSwap() ;
        return tokenOutput;
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        //uint256 xInput = tokenInput;
        //uint256 xReserves = token.balanceOf(address(this));
        //uint256 yReserves = totalLiquidity;
        //return price(xInput, xReserves, yReserves);

        //solution after looking
        require(tokenInput > 0, "no tokens to swap");
        uint256 xInput = tokenInput;
        uint256 xReserves = token.balanceOf(address(this)); //.sub(tokenInput); why isnt it subtracted here?
        uint256 yReserves = address(this).balance;
        require(token.transfer(msg.sender, address(this), xInput), 'could not transfer tokens');

        ethOutput = price(xInput, xReserves, yReserves);
        (bool ok, ) = msg.sender.call{value: ethOutput}("");
        requre(ok, 'could not transfer ether');
        emit TokenToEthSwap();
        return ethOutput;

    }

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount of $BAL needed as well and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
     */
    function deposit() public payable returns (uint256 tokensDeposited) {}

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     * NOTE: with this current code, the msg caller could end up getting very little back if the liquidity is super low in the pool. I guess they could see that with the UI.
     */
    function withdraw(uint256 amount) public returns (uint256 eth_amount, uint256 token_amount) {}
}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: MIT

// Borrowed from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

contract SimpleAMMPool {
    // Tokens comprising AMM pool, set once at construction
    IERC20 public immutable TOKEN0;
    IERC20 public immutable TOKEN1;

    // Balance of tokens in pool
    uint reserve0;
    uint reserve1;

    uint totalSupplyLP;

    // Amount of token each address has as a representation
    // of their LP stake via mint/burn
    mapping(address => uint) public balanceLP;

    constructor(address _token0, address _token1) {
        TOKEN0 = IERC20(_token0);
        TOKEN1 = IERC20(_token1);

        reserve0 = 0;
        reserve1 = 0;
    }

    //////////////////////////////
    // Public / external functions

    function swap(address _tokenIn, uint _amountIn) external
        returns (uint amountOut)
    {
        require(
            _tokenIn == address(TOKEN0) || _tokenIn == address(TOKEN1),
            "wrong token supplied for swap"
        );
        require(_amountIn > 0, "invalid swap amount proposed");

        // Determine which is the input and output token
        bool isToken0 = _tokenIn == address(TOKEN0);
        (IERC20 tokenIn, IERC20 tokenOut, uint reserveIn, uint reserveOut) = isToken0
            ? (TOKEN0, TOKEN1, reserve0, reserve1)
            : (TOKEN1, TOKEN0, reserve1, reserve0);

        // Calculate expected swap amount
        // Assume fee of 0.3%
        uint amountInWithFee = (_amountIn * 997) / 1000;
        // Based on constant product formula [(x + dx)(y - dy) = k] => [ydx / (x + dx) = dy]
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);

        // Call the input contract to transfer in funds
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        // Credit output contract with swapped user funds
        tokenOut.transfer(msg.sender, amountOut);
        // Store new stored fund balances
        _update(TOKEN0.balanceOf(address(this)), TOKEN1.balanceOf(address(this)));
    }

    function addLiquidity(uint _amount0, uint _amount1) external 
        returns (uint shares)
    {
        // Ratio between token0 and token1 must be maintained when adding
        // liquidity to the pool.
        // Hence x/y = x'y' => xy' = y'x
        if (reserve0 > 0 || reserve1 > 0) {
            require(reserve0 * _amount1 == reserve1 * _amount0, "Invalid ratios attempted to add");
        }

        TOKEN0.transferFrom(msg.sender, address(this), _amount0);
        TOKEN1.transferFrom(msg.sender, address(this), _amount1);

        if (totalSupplyLP == 0) {
            // Special case on initialising pool with no collateral present
            // According to https://uniswap.org/whitepaper.pdf
            shares = _sqrt(_amount0 * _amount1);
        } else {
            // Handle imprecision due to integer limitations
            // According to https://github.com/runtimeverification/verified-smart-contracts/blob/uniswap/uniswap/x-y-k.pdf
            shares = _min(
                (_amount0 * totalSupplyLP) / reserve0,
                (_amount1 * totalSupplyLP) / reserve1
            );
        }
        require(shares > 0, "LP shares generated can't be 0");

        _mint(msg.sender, shares);
        _update(TOKEN0.balanceOf(address(this)), TOKEN1.balanceOf(address(this)));
    }

    function removeLiquidity(uint _shares) external
        returns (uint amount0, uint amount1)
    {
        // Calculate based on the number of shares being burned how
        // many tokens will be returned to the caller
        uint poolBalanceToken0 = TOKEN0.balanceOf(address(this));
        uint poolBalanceToken1 = TOKEN1.balanceOf(address(this));

        require(poolBalanceToken0 >= reserve0, "Token0 reserve balance mismatch");
        require(poolBalanceToken1 >= reserve1, "Token1 reserve balance mismatch");
        require(totalSupplyLP > 0, "Pool not initialised");

        amount0 = (_shares * poolBalanceToken0) / totalSupplyLP;
        amount1 = (_shares * poolBalanceToken1) / totalSupplyLP;
        require(amount0 > 0 && amount1 > 0, "Amount0/1 should be greater than 0");

        // Reduce LP tokens for sender and pool
        _burn(msg.sender, _shares);
        // Update pool balances
        _update(poolBalanceToken0 - amount0,
                poolBalanceToken1 - amount1);

        TOKEN0.transfer(msg.sender, amount0);
        TOKEN1.transfer(msg.sender, amount1);
    }

    //////////////////////////////
    // Private functions

    function _mint(address _to, uint _amount) private {
        balanceLP[_to] += _amount;
        totalSupplyLP += _amount;
    }

    function _burn(address _from, uint _amount) private {
        require(balanceLP[_from] >= _amount, "Attempt to burn more than address has");
        require(totalSupplyLP >= _amount, "Attempt to reduce more than supply");

        balanceLP[_from] -= _amount;
        totalSupplyLP -= _amount;
    }

    function _update(uint _reserve0, uint _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    // Sourced from https://ethereum.stackexchange.com/questions/2910/can-i-square-root-in-solidity
    // which was in turn taken from https://github.com/Uniswap/v2-core/blob/v1.0.1/contracts/libraries/Math.sol
    function _sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}
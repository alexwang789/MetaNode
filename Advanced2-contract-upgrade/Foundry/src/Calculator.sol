// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title Calculator
 * @dev 一个简单的计算器合约，包含加法和减法运算
 * 初始版本 - 未优化
 */
contract Calculator {
    uint256 public result;
    
    /**
     * @dev 执行加法运算
     * @param a 第一个操作数
     * @param b 第二个操作数
     * @return 计算结果
     */
    function add(uint256 a, uint256 b) public returns (uint256) {
        result = a + b;
        return result;
    }
    
    /**
     * @dev 执行减法运算
     * @param a 被减数
     * @param b 减数
     * @return 计算结果
     */
    function subtract(uint256 a, uint256 b) public returns (uint256) {
        require(a >= b, "Calculator: subtraction underflow");
        result = a - b;
        return result;
    }
    
    /**
     * @dev 获取当前结果
     * @return 当前存储的结果值
     */
    function getResult() public view returns (uint256) {
        return result;
    }
    
    /**
     * @dev 重置结果
     */
    function reset() public {
        result = 0;
    }
}


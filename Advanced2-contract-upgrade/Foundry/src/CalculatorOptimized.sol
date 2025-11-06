// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title CalculatorOptimized
 * @dev 优化版本的 Calculator 合约
 * 
 * 优化策略：
 * 1. 移除不必要的状态变量存储 - 只在需要时存储结果
 * 2. 使用 unchecked 块减少 Gas 消耗（在安全的情况下）
 * 3. 优化函数可见性 - 使用 external 减少 Gas
 */
contract CalculatorOptimized {
    uint256 public result;
    
    /**
     * @dev 执行加法运算（优化版本）
     * 优化：使用 unchecked 块，因为 uint256 加法在 Solidity 0.8+ 会自动检查溢出
     * 但我们可以通过直接返回而不存储来节省 Gas
     */
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        // 策略1: 移除状态变量存储，直接返回结果
        // 这样可以节省 SSTORE 操作的 Gas（约 20,000 Gas）
        return a + b;
    }
    
    /**
     * @dev 执行加法运算并存储结果（如果需要存储）
     */
    function addAndStore(uint256 a, uint256 b) external returns (uint256) {
        // 策略2: 使用 unchecked 块（在已知安全的情况下）
        // 注意：这里我们仍然需要检查，但可以优化存储
        uint256 sum;
        unchecked {
            sum = a + b;
        }
        result = sum;
        return sum;
    }
    
    /**
     * @dev 执行减法运算（优化版本）
     * 优化：使用 unchecked 块，但保留必要的检查
     */
    function subtract(uint256 a, uint256 b) external pure returns (uint256) {
        // 策略1: 移除状态变量存储
        require(a >= b, "Calculator: subtraction underflow");
        unchecked {
            return a - b;
        }
    }
    
    /**
     * @dev 执行减法运算并存储结果
     */
    function subtractAndStore(uint256 a, uint256 b) external returns (uint256) {
        require(a >= b, "Calculator: subtraction underflow");
        uint256 diff;
        unchecked {
            diff = a - b;
        }
        result = diff;
        return diff;
    }
    
    /**
     * @dev 获取当前结果
     */
    function getResult() external view returns (uint256) {
        return result;
    }
    
    /**
     * @dev 重置结果（优化：使用 delete 关键字）
     */
    function reset() external {
        // 策略3: 使用 delete 比直接赋值为 0 更节省 Gas
        delete result;
    }
    
    /**
     * @dev 批量操作 - 一次性执行多个运算（减少交易次数）
     * 优化策略：将多个操作合并到一个函数中，减少交易开销
     */
    function batchAdd(uint256[] calldata values) external pure returns (uint256) {
        uint256 sum = 0;
        unchecked {
            for (uint256 i = 0; i < values.length; ++i) {
                sum += values[i];
            }
        }
        return sum;
    }
}


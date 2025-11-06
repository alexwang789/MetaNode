// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {CalculatorOptimized} from "../src/CalculatorOptimized.sol";

/**
 * @title CalculatorOptimizedTest
 * @dev CalculatorOptimized 合约的单元测试和 Gas 对比
 */
contract CalculatorOptimizedTest is Test {
    CalculatorOptimized public calculator;
    
    event LogGas(string operation, uint256 gasUsed);
    
    function setUp() public {
        calculator = new CalculatorOptimized();
    }
    
    /**
     * @dev 测试优化后的加法运算（不存储）
     */
    function test_AddOptimized() public {
        uint256 gasBefore = gasleft();
        uint256 sum = calculator.add(10, 20);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        
        assertEq(sum, 30, "Addition should return 30");
        
        console.log("Gas used for optimized add(10, 20):", gasUsed);
        emit LogGas("add_optimized", gasUsed);
    }
    
    /**
     * @dev 测试优化后的加法运算（存储版本）
     */
    function test_AddAndStore() public {
        uint256 gasBefore = gasleft();
        uint256 sum = calculator.addAndStore(10, 20);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        
        assertEq(sum, 30, "Addition should return 30");
        assertEq(calculator.getResult(), 30, "Result should be stored as 30");
        
        console.log("Gas used for addAndStore(10, 20):", gasUsed);
        emit LogGas("add_and_store", gasUsed);
    }
    
    /**
     * @dev 测试优化后的减法运算
     */
    function test_SubtractOptimized() public {
        uint256 gasBefore = gasleft();
        uint256 diff = calculator.subtract(50, 20);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        
        assertEq(diff, 30, "Subtraction should return 30");
        
        console.log("Gas used for optimized subtract(50, 20):", gasUsed);
        emit LogGas("subtract_optimized", gasUsed);
    }
    
    /**
     * @dev 测试优化后的重置功能
     */
    function test_ResetOptimized() public {
        calculator.addAndStore(100, 200);
        assertEq(calculator.getResult(), 300, "Result should be 300 before reset");
        
        uint256 gasBefore = gasleft();
        calculator.reset();
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        
        assertEq(calculator.getResult(), 0, "Result should be 0 after reset");
        
        console.log("Gas used for optimized reset():", gasUsed);
        emit LogGas("reset_optimized", gasUsed);
    }
    
    /**
     * @dev 测试批量操作
     */
    function test_BatchAdd() public {
        uint256[] memory values = new uint256[](5);
        values[0] = 10;
        values[1] = 20;
        values[2] = 30;
        values[3] = 40;
        values[4] = 50;
        
        uint256 gasBefore = gasleft();
        uint256 sum = calculator.batchAdd(values);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        
        assertEq(sum, 150, "Batch add should return 150");
        
        console.log("Gas used for batchAdd([10,20,30,40,50]):", gasUsed);
        emit LogGas("batch_add", gasUsed);
    }
}


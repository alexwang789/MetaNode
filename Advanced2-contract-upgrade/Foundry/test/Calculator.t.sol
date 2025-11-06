// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Calculator} from "../src/Calculator.sol";

/**
 * @title CalculatorTest
 * @dev Calculator 合约的单元测试
 */
contract CalculatorTest is Test {
    Calculator public calculator;
    
    event LogGas(string operation, uint256 gasUsed);
    
    function setUp() public {
        calculator = new Calculator();
    }
    
    /**
     * @dev 测试加法运算
     */
    function test_Add() public {
        uint256 gasBefore = gasleft();
        uint256 sum = calculator.add(10, 20);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        
        assertEq(sum, 30, "Addition should return 30");
        assertEq(calculator.result(), 30, "Result should be 30");
        
        console.log("Gas used for add(10, 20):", gasUsed);
        emit LogGas("add", gasUsed);
    }
    
    /**
     * @dev 测试减法运算
     */
    function test_Subtract() public {
        uint256 gasBefore = gasleft();
        uint256 diff = calculator.subtract(50, 20);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        
        assertEq(diff, 30, "Subtraction should return 30");
        assertEq(calculator.result(), 30, "Result should be 30");
        
        console.log("Gas used for subtract(50, 20):", gasUsed);
        emit LogGas("subtract", gasUsed);
    }
    
    /**
     * @dev 测试减法下溢保护
     */
    function test_SubtractUnderflow() public {
        vm.expectRevert("Calculator: subtraction underflow");
        calculator.subtract(10, 20);
    }
    
    /**
     * @dev 测试重置功能
     */
    function test_Reset() public {
        calculator.add(100, 200);
        assertEq(calculator.result(), 300, "Result should be 300 before reset");
        
        uint256 gasBefore = gasleft();
        calculator.reset();
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        
        assertEq(calculator.result(), 0, "Result should be 0 after reset");
        
        console.log("Gas used for reset():", gasUsed);
        emit LogGas("reset", gasUsed);
    }
    
    /**
     * @dev 测试连续操作
     */
    function test_MultipleOperations() public {
        uint256 totalGasBefore = gasleft();
        
        calculator.add(5, 3);
        calculator.subtract(20, 10);
        calculator.add(100, 50);
        
        uint256 totalGasAfter = gasleft();
        uint256 totalGasUsed = totalGasBefore - totalGasAfter;
        
        assertEq(calculator.result(), 150, "Final result should be 150");
        
        console.log("Total gas used for multiple operations:", totalGasUsed);
        emit LogGas("multiple_operations", totalGasUsed);
    }
    
    /**
     * @dev 测试大数运算
     */
    function test_LargeNumbers() public {
        uint256 gasBefore = gasleft();
        calculator.add(type(uint256).max / 2, type(uint256).max / 2);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        
        console.log("Gas used for large number addition:", gasUsed);
        emit LogGas("large_add", gasUsed);
    }
}


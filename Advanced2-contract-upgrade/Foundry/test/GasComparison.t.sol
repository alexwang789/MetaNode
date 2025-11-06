// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Calculator} from "../src/Calculator.sol";
import {CalculatorOptimized} from "../src/CalculatorOptimized.sol";

/**
 * @title GasComparisonTest
 * @dev 对比原始版本和优化版本的 Gas 消耗
 */
contract GasComparisonTest is Test {
    Calculator public calculatorOriginal;
    CalculatorOptimized public calculatorOptimized;
    
    struct GasReport {
        string operation;
        uint256 original;
        uint256 optimized;
        uint256 savings;
        uint256 savingsPercent;
    }
    
    GasReport[] public gasReports;
    
    function setUp() public {
        calculatorOriginal = new Calculator();
        calculatorOptimized = new CalculatorOptimized();
    }
    
    /**
     * @dev 对比加法运算的 Gas 消耗
     */
    function test_CompareAdd() public {
        // 原始版本
        uint256 gasBefore1 = gasleft();
        calculatorOriginal.add(10, 20);
        uint256 gasAfter1 = gasleft();
        uint256 gasOriginal = gasBefore1 - gasAfter1;
        
        // 优化版本（不存储）
        uint256 gasBefore2 = gasleft();
        calculatorOptimized.add(10, 20);
        uint256 gasAfter2 = gasleft();
        uint256 gasOptimized = gasBefore2 - gasAfter2;
        
        uint256 savings = gasOriginal > gasOptimized ? gasOriginal - gasOptimized : 0;
        uint256 savingsPercent = gasOriginal > 0 ? (savings * 100) / gasOriginal : 0;
        
        console.log("=== Add Operation Comparison ===");
        console.log("Original Gas:", gasOriginal);
        console.log("Optimized Gas (no storage):", gasOptimized);
        console.log("Gas Savings:", savings);
        console.log("Savings Percentage:", savingsPercent);
        
        gasReports.push(GasReport({
            operation: "add",
            original: gasOriginal,
            optimized: gasOptimized,
            savings: savings,
            savingsPercent: savingsPercent
        }));
    }
    
    /**
     * @dev 对比带存储的加法运算
     */
    function test_CompareAddWithStorage() public {
        // 原始版本
        uint256 gasBefore1 = gasleft();
        calculatorOriginal.add(10, 20);
        uint256 gasAfter1 = gasleft();
        uint256 gasOriginal = gasBefore1 - gasAfter1;
        
        // 优化版本（带存储）
        uint256 gasBefore2 = gasleft();
        calculatorOptimized.addAndStore(10, 20);
        uint256 gasAfter2 = gasleft();
        uint256 gasOptimized = gasBefore2 - gasAfter2;
        
        uint256 savings = gasOriginal > gasOptimized ? gasOriginal - gasOptimized : 0;
        uint256 savingsPercent = gasOriginal > 0 ? (savings * 100) / gasOriginal : 0;
        
        console.log("=== Add with Storage Comparison ===");
        console.log("Original Gas:", gasOriginal);
        console.log("Optimized Gas (with storage):", gasOptimized);
        console.log("Gas Savings:", savings);
        console.log("Savings Percentage:", savingsPercent);
        
        gasReports.push(GasReport({
            operation: "add_with_storage",
            original: gasOriginal,
            optimized: gasOptimized,
            savings: savings,
            savingsPercent: savingsPercent
        }));
    }
    
    /**
     * @dev 对比减法运算的 Gas 消耗
     */
    function test_CompareSubtract() public {
        // 原始版本
        uint256 gasBefore1 = gasleft();
        calculatorOriginal.subtract(50, 20);
        uint256 gasAfter1 = gasleft();
        uint256 gasOriginal = gasBefore1 - gasAfter1;
        
        // 优化版本
        uint256 gasBefore2 = gasleft();
        calculatorOptimized.subtract(50, 20);
        uint256 gasAfter2 = gasleft();
        uint256 gasOptimized = gasBefore2 - gasAfter2;
        
        uint256 savings = gasOriginal > gasOptimized ? gasOriginal - gasOptimized : 0;
        uint256 savingsPercent = gasOriginal > 0 ? (savings * 100) / gasOriginal : 0;
        
        console.log("=== Subtract Operation Comparison ===");
        console.log("Original Gas:", gasOriginal);
        console.log("Optimized Gas:", gasOptimized);
        console.log("Gas Savings:", savings);
        console.log("Savings Percentage:", savingsPercent);
        
        gasReports.push(GasReport({
            operation: "subtract",
            original: gasOriginal,
            optimized: gasOptimized,
            savings: savings,
            savingsPercent: savingsPercent
        }));
    }
    
    /**
     * @dev 对比重置操作的 Gas 消耗
     */
    function test_CompareReset() public {
        // 准备：先设置一个值
        calculatorOriginal.add(100, 200);
        calculatorOptimized.addAndStore(100, 200);
        
        // 原始版本
        uint256 gasBefore1 = gasleft();
        calculatorOriginal.reset();
        uint256 gasAfter1 = gasleft();
        uint256 gasOriginal = gasBefore1 - gasAfter1;
        
        // 优化版本
        uint256 gasBefore2 = gasleft();
        calculatorOptimized.reset();
        uint256 gasAfter2 = gasleft();
        uint256 gasOptimized = gasBefore2 - gasAfter2;
        
        uint256 savings = gasOriginal > gasOptimized ? gasOriginal - gasOptimized : 0;
        uint256 savingsPercent = gasOriginal > 0 ? (savings * 100) / gasOriginal : 0;
        
        console.log("=== Reset Operation Comparison ===");
        console.log("Original Gas:", gasOriginal);
        console.log("Optimized Gas:", gasOptimized);
        console.log("Gas Savings:", savings);
        console.log("Savings Percentage:", savingsPercent);
        
        gasReports.push(GasReport({
            operation: "reset",
            original: gasOriginal,
            optimized: gasOptimized,
            savings: savings,
            savingsPercent: savingsPercent
        }));
    }
    
    /**
     * @dev 生成完整的 Gas 对比报告
     */
    function test_GenerateFullReport() public {
        // 运行所有对比测试
        test_CompareAdd();
        test_CompareAddWithStorage();
        test_CompareSubtract();
        test_CompareReset();
        
        console.log("\n=== Full Gas Comparison Report ===");
        for (uint256 i = 0; i < gasReports.length; i++) {
            console.log("\nOperation:", gasReports[i].operation);
            console.log("  Original:", gasReports[i].original);
            console.log("  Optimized:", gasReports[i].optimized);
            console.log("  Savings:", gasReports[i].savings);
            console.log("  Savings %:", gasReports[i].savingsPercent);
        }
    }
}


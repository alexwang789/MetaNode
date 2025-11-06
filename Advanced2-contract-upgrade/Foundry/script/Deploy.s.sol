// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {Calculator} from "../src/Calculator.sol";
import {CalculatorOptimized} from "../src/CalculatorOptimized.sol";

/**
 * @title DeployScript
 * @dev 部署脚本示例
 */
contract DeployScript is Script {
    function run() external returns (Calculator, CalculatorOptimized) {
        vm.startBroadcast();
        
        // 部署原始版本
        Calculator calculator = new Calculator();
        
        // 部署优化版本
        CalculatorOptimized calculatorOptimized = new CalculatorOptimized();
        
        vm.stopBroadcast();
        
        return (calculator, calculatorOptimized);
    }
}


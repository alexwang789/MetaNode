# 快速开始指南

## 项目简介

这是一个使用 Foundry 框架开发的智能合约 Gas 优化示例项目。项目包含：

1. **原始版本合约** (`Calculator.sol`) - 未优化的基础实现
2. **优化版本合约** (`CalculatorOptimized.sol`) - 应用了多种 Gas 优化策略
3. **完整的测试套件** - 包括单元测试和 Gas 对比测试
4. **详细的分析报告** - Gas 优化策略说明和效果分析

## 快速开始

### 1. 安装 Foundry（如果尚未安装）

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. 安装依赖（如果需要）

```bash
forge install
```

### 3. 运行测试

```bash
# 运行所有测试
forge test

# 运行原始版本测试
forge test --match-contract CalculatorTest -vvv

# 运行优化版本测试
forge test --match-contract CalculatorOptimizedTest -vvv

# 运行 Gas 对比测试
forge test --match-contract GasComparisonTest -vvv

# 生成 Gas 报告
forge test --gas-report
```

### 4. 查看测试输出

使用 `-vvv` 或 `-vvvv` 标志查看详细的测试输出和 Gas 消耗信息：

```bash
forge test -vvvv
```

## 主要功能

### Calculator.sol（原始版本）

- `add(uint256 a, uint256 b)`: 加法运算
- `subtract(uint256 a, uint256 b)`: 减法运算
- `getResult()`: 获取结果
- `reset()`: 重置结果

### CalculatorOptimized.sol（优化版本）

实现了以下优化：

1. **移除状态存储** - 提供 `pure` 函数版本
2. **unchecked 块** - 在安全情况下跳过溢出检查
3. **函数可见性优化** - 使用 `external` 替代 `public`
4. **delete 关键字** - 优化重置操作
5. **批量操作** - 减少交易次数

## 测试说明

### 测试文件

- `test/Calculator.t.sol`: 原始版本的单元测试
- `test/CalculatorOptimized.t.sol`: 优化版本的单元测试
- `test/GasComparison.t.sol`: Gas 消耗对比测试

### 运行特定测试

```bash
# 测试加法
forge test --match-test test_Add -vvv

# 测试减法
forge test --match-test test_Subtract -vvv

# 测试 Gas 对比
forge test --match-test test_CompareAdd -vvv
```

## Gas 优化策略

详细说明请参考 `Gas优化分析报告.md`。

### 主要优化策略

1. **移除不必要的状态存储** - 节省 20,000+ Gas
2. **使用 unchecked 块** - 每次运算节省 20-30 Gas
3. **优化函数可见性** - 每次调用节省 100-200 Gas
4. **使用 delete 关键字** - 节省约 500 Gas

## 项目结构

```
Foundry/
├── foundry.toml              # Foundry 配置
├── src/                      # 合约源码
│   ├── Calculator.sol
│   └── CalculatorOptimized.sol
├── test/                     # 测试文件
│   ├── Calculator.t.sol
│   ├── CalculatorOptimized.t.sol
│   └── GasComparison.t.sol
├── script/                   # 部署脚本
│   └── Deploy.s.sol
├── README.md                 # 项目说明
├── QUICKSTART.md            # 快速开始指南
└── Gas优化分析报告.md        # Gas 优化分析报告
```

## 下一步

1. 运行测试查看实际的 Gas 消耗数据
2. 阅读 `Gas优化分析报告.md` 了解优化细节
3. 尝试修改合约代码，测试不同的优化策略
4. 部署到测试网进行实际测试

## 常见问题

### Q: 如何查看详细的 Gas 消耗？

A: 使用 `forge test -vvvv` 或 `forge test --gas-report`

### Q: 为什么优化版本的 Gas 消耗更少？

A: 主要原因是移除了不必要的状态存储操作（SSTORE），这是最昂贵的操作之一。

### Q: 如何部署合约？

A: 使用部署脚本：`forge script script/Deploy.s.sol --rpc-url <RPC_URL> --broadcast`

## 参考资料

- [Foundry 官方文档](https://book.getfoundry.sh/)
- [Solidity 文档](https://docs.soliditylang.org/)
- [Ethereum Gas 优化指南](https://ethereum.org/en/developers/docs/gas/)


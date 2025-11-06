# Foundry 智能合约 Gas 优化项目

本项目演示了如何使用 Foundry 框架进行智能合约开发、测试和 Gas 优化分析。

## 项目结构

```
Foundry/
├── foundry.toml          # Foundry 配置文件
├── src/                  # 智能合约源码
│   ├── Calculator.sol           # 原始版本（未优化）
│   └── CalculatorOptimized.sol  # 优化版本
├── test/                 # 测试文件
│   ├── Calculator.t.sol         # 原始版本测试
│   ├── CalculatorOptimized.t.sol # 优化版本测试
│   └── GasComparison.t.sol      # Gas 对比测试
└── README.md            # 项目说明文档
```

## 安装 Foundry

如果尚未安装 Foundry，请运行：

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## 运行测试

### 1. 运行原始版本测试

```bash
forge test --match-contract CalculatorTest -vvv
```

### 2. 运行优化版本测试

```bash
forge test --match-contract CalculatorOptimizedTest -vvv
```

### 3. 运行 Gas 对比测试

```bash
forge test --match-contract GasComparisonTest -vvv
```

### 4. 生成 Gas 报告

```bash
forge test --gas-report
```

### 5. 运行所有测试并查看详细输出

```bash
forge test -vvvv
```

## 合约说明

### Calculator.sol（原始版本）

包含基本的加法和减法运算功能：
- `add(uint256 a, uint256 b)`: 执行加法并存储结果
- `subtract(uint256 a, uint256 b)`: 执行减法并存储结果
- `getResult()`: 获取当前结果
- `reset()`: 重置结果

### CalculatorOptimized.sol（优化版本）

实现了以下优化策略：

1. **移除不必要的状态存储**
   - 提供 `pure` 函数版本，直接返回结果而不存储
   - 节省 SSTORE 操作的 Gas（约 20,000 Gas）

2. **使用 unchecked 块**
   - 在已知安全的情况下使用 `unchecked` 块
   - 减少溢出检查的 Gas 消耗

3. **优化函数可见性**
   - 使用 `external` 替代 `public`（当不需要内部调用时）
   - 减少函数调用的 Gas 开销

4. **使用 delete 关键字**
   - 使用 `delete` 替代直接赋值为 0
   - 更节省 Gas

5. **批量操作**
   - 提供批量操作函数，减少交易次数
   - 降低总体 Gas 消耗

## Gas 优化分析

详细的 Gas 优化分析报告请参考 `Gas优化分析报告.md`。

## 测试覆盖

- ✅ 基本算术运算测试
- ✅ 边界条件测试（下溢保护）
- ✅ Gas 消耗测量
- ✅ 优化前后对比
- ✅ 批量操作测试


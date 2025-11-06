# MemeToken 合约操作指南

本文档详细说明如何部署和使用 MemeToken 智能合约。

## 📚 目录

1. [部署前准备](#部署前准备)
2. [合约部署](#合约部署)
3. [初始化设置](#初始化设置)
4. [代币交易](#代币交易)
5. [流动性管理](#流动性管理)
6. [管理员操作](#管理员操作)
7. [故障排除](#故障排除)

---

## 部署前准备

### 1. 环境配置

确保已安装 Node.js 和 npm：

```bash
node --version  # 应该 >= 16.0.0
npm --version
```

### 2. 安装依赖

```bash
npm install
```

### 3. 配置环境变量（可选但推荐）

创建 `.env` 文件：

```env
PRIVATE_KEY=your_private_key_here
TAX_WALLET=0xYourTaxWalletAddress
UNISWAP_ROUTER=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
```

### 4. 选择网络和 Router

根据目标网络选择正确的 Uniswap Router 地址：

| 网络 | Router 地址 |
|------|-----------|
| 以太坊主网 | 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D |
| 以太坊 Sepolia | 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008 |
| BSC 主网 | 0x10ED43C718714eb63d5aA57B78B54704E256024E |
| BSC 测试网 | 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 |
| Polygon | 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff |
| Arbitrum | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |

---

## 合约部署

### 步骤 1: 修改部署参数

编辑 `scripts/deploy.js`，修改以下参数：

```javascript
// 代币信息
const TOKEN_NAME = "MyMemeToken";      // 代币名称
const TOKEN_SYMBOL = "MMT";            // 代币符号
const TOTAL_SUPPLY = ethers.parseEther("1000000000"); // 总供应量（10亿）

// 税费设置（基点，100 = 1%）
const BUY_TAX_RATE = 500;   // 买入税 5%
const SELL_TAX_RATE = 500;  // 卖出税 5%

// 交易限制
const MAX_TRANSACTION_AMOUNT = ethers.parseEther("10000000");  // 单笔最大 1000万
const MAX_WALLET_AMOUNT = ethers.parseEther("50000000");        // 单个地址最大 5000万
const DAILY_TRADING_LIMIT = ethers.parseEther("50000000");     // 每日限额 5000万
```

### 步骤 2: 编译合约

```bash
npm run compile
```

### 步骤 3: 部署到测试网（推荐先测试）

```bash
# 设置环境变量
export PRIVATE_KEY=your_private_key
export TAX_WALLET=0xYourTaxWalletAddress
export SEPOLIA_RPC_URL=your_sepolia_rpc_url

# 部署
npm run deploy:testnet
```

### 步骤 4: 部署到主网

⚠️ **警告**: 主网部署会消耗真实资金！

```bash
# 确保所有参数正确
npm run deploy:mainnet
```

部署成功后，记录合约地址。

---

## 初始化设置

### 1. 添加初始流动性

部署后，合约默认禁用交易。需要先添加流动性。

#### 方法 A: 通过 Uniswap 前端（推荐）

1. 访问 [Uniswap](https://app.uniswap.org/)
2. 进入 "Pool" → "Add Liquidity"
3. 选择你的代币和 ETH
4. 输入数量（例如：1000 万代币 + 1 ETH）
5. 确认并添加流动性

#### 方法 B: 通过合约函数

```javascript
// 使用交互脚本或直接调用
const tokenAmount = ethers.parseEther("10000000"); // 1000万代币
const ethAmount = ethers.parseEther("1");           // 1 ETH
const deadline = Math.floor(Date.now() / 1000) + 300;

await memeToken.addLiquidity(tokenAmount, ethAmount, deadline, {
  value: ethAmount
});
```

### 2. 启用交易

添加流动性后，启用交易：

```javascript
await memeToken.enableTrading();
```

### 3. 验证交易对

在 Uniswap 上搜索你的代币，确认交易对已创建。

---

## 代币交易

### 通过 DEX 交易

1. **访问 Uniswap/PancakeSwap**
   - 以太坊: https://app.uniswap.org/
   - BSC: https://pancakeswap.finance/

2. **连接钱包**
   - 点击 "Connect Wallet"
   - 选择你的钱包（MetaMask、WalletConnect 等）

3. **选择代币**
   - 点击 "Select a token"
   - 输入你的代币合约地址或搜索代币符号

4. **输入交易数量**
   - 输入要买入/卖出的代币或 ETH 数量
   - 系统会自动显示税费和实际收到的数量

5. **确认交易**
   - 检查交易详情（包括税费）
   - 点击 "Swap" 确认
   - 在钱包中批准交易

### 直接转账

```javascript
// 转账代币（会自动扣除税费）
const amount = ethers.parseEther("1000");
await memeToken.transfer(recipientAddress, amount);
```

**注意**: 转账给普通地址不收取税费，只有与交易对的交易才会收取税费。

---

## 流动性管理

### 添加流动性

#### 使用 Uniswap 前端（推荐）

1. 访问 Uniswap "Pool" 页面
2. 点击 "Add Liquidity"
3. 选择代币和 ETH
4. 输入数量并确认

#### 使用合约函数

```javascript
// 准备参数
const tokenAmount = ethers.parseEther("1000000");
const ethAmount = ethers.parseEther("0.1");
const deadline = Math.floor(Date.now() / 1000) + 300;

// 先批准代币
await memeToken.approve(contractAddress, tokenAmount);

// 添加流动性
await memeToken.addLiquidity(tokenAmount, ethAmount, deadline, {
  value: ethAmount
});
```

### 移除流动性

#### 使用 Uniswap 前端（推荐）

1. 访问 Uniswap "Pool" 页面
2. 找到你的流动性池
3. 点击 "Remove"
4. 选择要移除的比例
5. 确认移除

#### 使用合约函数

```javascript
// 获取 LP Token 余额
const lpToken = await ethers.getContractAt("IERC20", pairAddress);
const liquidity = await lpToken.balanceOf(yourAddress);

// 批准 LP Token
await lpToken.approve(contractAddress, liquidity);

// 移除流动性
const deadline = Math.floor(Date.now() / 1000) + 300;
await memeToken.removeLiquidity(liquidity, deadline);
```

---

## 管理员操作

### 设置税费

```javascript
// 设置买入税 3%，卖出税 5%
await memeToken.setTaxRates(300, 500);
```

**注意**: 税率以基点表示（100 = 1%），最高 15%（1500 基点）。

### 更改税费钱包

```javascript
await memeToken.setTaxWallet(newTaxWalletAddress);
```

### 设置交易限制

```javascript
await memeToken.setLimits(
  ethers.parseEther("5000000"),  // 单笔最大
  ethers.parseEther("20000000"), // 单个地址最大
  ethers.parseEther("10000000")  // 每日限额
);
```

### 启用/禁用限制

```javascript
// 禁用所有限制
await memeToken.setLimitsEnabled(false);

// 重新启用
await memeToken.setLimitsEnabled(true);
```

### 排除地址

```javascript
// 排除税费
await memeToken.setTaxExclusion(address, true);

// 排除限制
await memeToken.setLimitsExclusion(address, true);
```

### 启用/禁用交易

```javascript
// 禁用交易（紧急情况）
await memeToken.disableTrading();

// 重新启用
await memeToken.enableTrading();
```

### 紧急提取

```javascript
// 提取 ETH
await memeToken.emergencyWithdrawETH();

// 提取 ERC20 代币
await memeToken.emergencyWithdrawToken(tokenAddress);
```

---

## 故障排除

### 问题 1: 交易失败 "Trading is not enabled yet"

**原因**: 交易尚未启用。

**解决**: 
```javascript
await memeToken.enableTrading();
```

### 问题 2: 交易失败 "Transaction amount exceeds maximum"

**原因**: 交易金额超过单笔限额。

**解决**:
- 减少交易金额
- 或增加限额：`await memeToken.setLimits(newMaxTransaction, ...)`
- 或禁用限制：`await memeToken.setLimitsEnabled(false)`

### 问题 3: 交易失败 "Daily trading limit exceeded"

**原因**: 超过每日交易限额。

**解决**:
- 等待第二天（UTC 0:00 自动重置）
- 或增加每日限额
- 或禁用限制

### 问题 4: 交易失败 "Wallet balance exceeds maximum"

**原因**: 持仓超过最大限额。

**解决**:
- 减少买入数量
- 或增加限额：`await memeToken.setLimits(..., newMaxWallet, ...)`
- 或禁用限制

### 问题 5: 无法添加流动性

**可能原因**:
- 代币未授权
- ETH 余额不足
- 滑点设置过小

**解决**:
```javascript
// 1. 授权代币
await memeToken.approve(contractAddress, tokenAmount);

// 2. 确保有足够的 ETH
// 3. 检查滑点设置（合约中设置为 0，实际使用应设置合理值）
```

### 问题 6: 税费计算不正确

**检查**:
```javascript
const buyTax = await memeToken.buyTaxRate();
const sellTax = await memeToken.sellTaxRate();
console.log("买入税:", Number(buyTax) / 100, "%");
console.log("卖出税:", Number(sellTax) / 100, "%");
```

**调整**:
```javascript
await memeToken.setTaxRates(newBuyTax, newSellTax);
```

---

## 最佳实践

1. **测试网验证**: 在主网部署前，先在测试网完整测试所有功能
2. **参数设置**: 谨慎设置税率和限制，过高可能影响用户体验
3. **安全性**: 
   - 保护私钥和合约所有者地址
   - 定期审查合约状态
   - 设置合理的税费钱包（最好是多签钱包）
4. **流动性**: 
   - 确保有足够的初始流动性
   - 考虑使用锁仓机制锁定流动性
5. **监控**: 定期监控合约状态和交易情况

---

## 技术支持

如遇到问题，请：
1. 检查合约代码和参数
2. 查看区块浏览器上的交易详情
3. 参考本文档的故障排除部分
4. 在 GitHub 上提交 Issue

---

**最后更新**: 2024年


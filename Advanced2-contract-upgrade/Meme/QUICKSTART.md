# MemeToken 快速开始指南

## 🚀 5 分钟快速部署

### 1. 安装依赖

```bash
npm install
```

### 2. 配置参数

编辑 `scripts/deploy.js`，修改以下关键参数：

```javascript
const TOKEN_NAME = "YourTokenName";
const TOKEN_SYMBOL = "YOUR";
const TOTAL_SUPPLY = ethers.parseEther("1000000000"); // 总供应量
const TAX_WALLET = "0xYourTaxWalletAddress"; // 税费钱包
const BUY_TAX_RATE = 500;   // 买入税 5%
const SELL_TAX_RATE = 500; // 卖出税 5%
```

### 3. 编译合约

```bash
npm run compile
```

### 4. 部署到测试网

```bash
# 设置环境变量
export PRIVATE_KEY=your_private_key
export TAX_WALLET=0xYourTaxWalletAddress
export SEPOLIA_RPC_URL=your_rpc_url

# 部署
npm run deploy:testnet
```

### 5. 添加流动性并启用交易

部署后，在 Uniswap 上添加流动性，然后调用：

```javascript
await memeToken.enableTrading();
```

## 📁 项目结构

```
meme/
├── contracts/
│   └── MemeToken.sol          # 主合约文件
├── scripts/
│   ├── deploy.js               # 部署脚本
│   └── interact.js            # 交互脚本示例
├── test/
│   └── MemeToken.test.js      # 测试文件
├── hardhat.config.js          # Hardhat 配置
├── package.json               # 依赖配置
├── README.md                  # 完整文档
├── CONTRACT_GUIDE.md          # 详细操作指南
└── QUICKSTART.md              # 本文件
```

## 🎯 核心功能

✅ **代币税功能** - 买入/卖出自动收税  
✅ **流动性池集成** - 自动与 Uniswap 集成  
✅ **交易限制** - 单笔限额、持仓限额、每日限额  
✅ **安全防护** - 重入保护、权限控制  

## 📖 详细文档

- **完整文档**: 查看 `README.md`
- **操作指南**: 查看 `CONTRACT_GUIDE.md`
- **合约代码**: 查看 `contracts/MemeToken.sol`（有详细注释）

## ⚠️ 重要提示

1. **测试优先**: 在主网部署前，务必在测试网完整测试
2. **私钥安全**: 永远不要将私钥提交到代码仓库
3. **参数检查**: 部署前仔细检查所有参数
4. **安全审计**: 主网部署前建议进行专业安全审计

## 🆘 需要帮助？

- 查看 `CONTRACT_GUIDE.md` 的故障排除部分
- 检查合约代码中的注释
- 在 GitHub 上提交 Issue

---

**祝部署顺利！** 🎉


/**
 * @title MemeToken 部署脚本
 * @notice 此脚本用于部署 MemeToken 合约到指定的区块链网络
 * @dev 部署前请确保：
 *       1. 已配置正确的网络参数（hardhat.config.js）
 *       2. 已设置 PRIVATE_KEY 环境变量
 *       3. 已准备好足够的 ETH/BNB 用于支付 gas 费用
 */

const hre = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("开始部署 MemeToken 合约...\n");

  // ============ 部署参数配置 ============
  // 请根据你的需求修改以下参数
  
  // 代币基本信息
  const TOKEN_NAME = "MemeToken";
  const TOKEN_SYMBOL = "MEME";
  const TOTAL_SUPPLY = ethers.parseEther("1000000000"); // 10 亿代币（18 位小数）
  
  // 税费钱包地址（请替换为你的地址）
  const TAX_WALLET = process.env.TAX_WALLET || "0x0000000000000000000000000000000000000000";
  
  // Uniswap Router 地址（根据网络选择）
  // 以太坊主网: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  // 以太坊 Sepolia 测试网: 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
  // BSC 主网: 0x10ED43C718714eb63d5aA57B78B54704E256024E
  // BSC 测试网: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
  const UNISWAP_ROUTER = process.env.UNISWAP_ROUTER || "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  
  // 税费设置（以基点表示，100 = 1%）
  const BUY_TAX_RATE = 500;   // 5%
  const SELL_TAX_RATE = 500;  // 5%
  
  // 交易限制设置
  const MAX_TRANSACTION_AMOUNT = ethers.parseEther("10000000");    // 单笔最大 1000 万代币
  const MAX_WALLET_AMOUNT = ethers.parseEther("50000000");         // 单个地址最大 5000 万代币
  const DAILY_TRADING_LIMIT = ethers.parseEther("50000000");       // 每日交易限额 5000 万代币

  // ============ 验证参数 ============
  if (TAX_WALLET === "0x0000000000000000000000000000000000000000") {
    throw new Error("请设置 TAX_WALLET 环境变量或修改脚本中的 TAX_WALLET 地址");
  }

  // ============ 获取部署者账户 ============
  const [deployer] = await ethers.getSigners();
  console.log("部署账户:", deployer.address);
  console.log("账户余额:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

  // ============ 部署合约 ============
  console.log("正在部署合约...");
  const MemeToken = await hre.ethers.getContractFactory("MemeToken");
  
  const memeToken = await MemeToken.deploy(
    TOKEN_NAME,
    TOKEN_SYMBOL,
    TOTAL_SUPPLY,
    TAX_WALLET,
    UNISWAP_ROUTER,
    BUY_TAX_RATE,
    SELL_TAX_RATE,
    MAX_TRANSACTION_AMOUNT,
    MAX_WALLET_AMOUNT,
    DAILY_TRADING_LIMIT
  );

  await memeToken.waitForDeployment();
  const contractAddress = await memeToken.getAddress();

  console.log("\n✅ 合约部署成功！");
  console.log("合约地址:", contractAddress);
  console.log("网络:", hre.network.name);
  console.log("\n合约参数:");
  console.log("  代币名称:", TOKEN_NAME);
  console.log("  代币符号:", TOKEN_SYMBOL);
  console.log("  总供应量:", ethers.formatEther(TOTAL_SUPPLY), TOKEN_SYMBOL);
  console.log("  税费钱包:", TAX_WALLET);
  console.log("  买入税率:", BUY_TAX_RATE / 100, "%");
  console.log("  卖出税率:", SELL_TAX_RATE / 100, "%");
  console.log("  单笔最大交易量:", ethers.formatEther(MAX_TRANSACTION_AMOUNT), TOKEN_SYMBOL);
  console.log("  单个地址最大持仓:", ethers.formatEther(MAX_WALLET_AMOUNT), TOKEN_SYMBOL);
  console.log("  每日交易限额:", ethers.formatEther(DAILY_TRADING_LIMIT), TOKEN_SYMBOL);

  // ============ 验证合约（如果在支持的网络上）============
  if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
    console.log("\n等待区块确认...");
    await new Promise(resolve => setTimeout(resolve, 30000)); // 等待 30 秒
    
    try {
      console.log("正在验证合约...");
      await hre.run("verify:verify", {
        address: contractAddress,
        constructorArguments: [
          TOKEN_NAME,
          TOKEN_SYMBOL,
          TOTAL_SUPPLY,
          TAX_WALLET,
          UNISWAP_ROUTER,
          BUY_TAX_RATE,
          SELL_TAX_RATE,
          MAX_TRANSACTION_AMOUNT,
          MAX_WALLET_AMOUNT,
          DAILY_TRADING_LIMIT
        ],
      });
      console.log("✅ 合约验证成功！");
    } catch (error) {
      console.log("⚠️  合约验证失败:", error.message);
    }
  }

  // ============ 保存部署信息 ============
  const deploymentInfo = {
    network: hre.network.name,
    contractAddress: contractAddress,
    deployer: deployer.address,
    deploymentTime: new Date().toISOString(),
    parameters: {
      tokenName: TOKEN_NAME,
      tokenSymbol: TOKEN_SYMBOL,
      totalSupply: TOTAL_SUPPLY.toString(),
      taxWallet: TAX_WALLET,
      uniswapRouter: UNISWAP_ROUTER,
      buyTaxRate: BUY_TAX_RATE,
      sellTaxRate: SELL_TAX_RATE,
      maxTransactionAmount: MAX_TRANSACTION_AMOUNT.toString(),
      maxWalletAmount: MAX_WALLET_AMOUNT.toString(),
      dailyTradingLimit: DAILY_TRADING_LIMIT.toString(),
    }
  };

  console.log("\n部署信息已保存到 deployment-info.json");
  const fs = require("fs");
  fs.writeFileSync(
    "deployment-info.json",
    JSON.stringify(deploymentInfo, null, 2)
  );

  console.log("\n📝 下一步操作:");
  console.log("1. 向合约添加流动性（使用 addLiquidity 函数）");
  console.log("2. 调用 enableTrading() 启用交易");
  console.log("3. 在 DEX 上创建交易对");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


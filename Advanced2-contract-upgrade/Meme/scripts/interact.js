/**
 * @title MemeToken 交互脚本示例
 * @notice 此脚本展示了如何与已部署的 MemeToken 合约进行交互
 * @dev 使用前请确保：
 *       1. 合约已部署
 *       2. 已设置正确的合约地址
 *       3. 账户有足够的 ETH 和代币余额
 */

const hre = require("hardhat");

async function main() {
  console.log("MemeToken 交互脚本示例\n");

  // ============ 配置 ============
  // 请替换为你的合约地址
  const CONTRACT_ADDRESS = "0xYourContractAddressHere";
  
  // 获取签名者
  const [owner, user1] = await ethers.getSigners();
  console.log("合约所有者:", owner.address);
  console.log("示例用户:", user1.address);
  console.log("");

  // 获取合约实例
  const MemeToken = await hre.ethers.getContractFactory("MemeToken");
  const memeToken = MemeToken.attach(CONTRACT_ADDRESS);

  // ============ 查询合约信息 ============
  console.log("=== 查询合约信息 ===");
  const name = await memeToken.name();
  const symbol = await memeToken.symbol();
  const totalSupply = await memeToken.totalSupply();
  const taxWallet = await memeToken.taxWallet();
  const buyTaxRate = await memeToken.buyTaxRate();
  const sellTaxRate = await memeToken.sellTaxRate();
  const tradingEnabled = await memeToken.tradingEnabled();

  console.log("代币名称:", name);
  console.log("代币符号:", symbol);
  console.log("总供应量:", ethers.formatEther(totalSupply), symbol);
  console.log("税费钱包:", taxWallet);
  console.log("买入税率:", Number(buyTaxRate) / 100, "%");
  console.log("卖出税率:", Number(sellTaxRate) / 100, "%");
  console.log("交易状态:", tradingEnabled ? "已启用" : "未启用");
  console.log("");

  // ============ 查询余额 ============
  console.log("=== 查询余额 ===");
  const ownerBalance = await memeToken.balanceOf(owner.address);
  const user1Balance = await memeToken.balanceOf(user1.address);
  
  console.log("所有者余额:", ethers.formatEther(ownerBalance), symbol);
  console.log("用户1余额:", ethers.formatEther(user1Balance), symbol);
  console.log("");

  // ============ 示例操作 ============
  
  // 1. 转账代币（示例）
  if (false) { // 设置为 true 来执行
    console.log("=== 转账代币 ===");
    const transferAmount = ethers.parseEther("1000");
    const tx = await memeToken.transfer(user1.address, transferAmount);
    console.log("转账交易哈希:", tx.hash);
    await tx.wait();
    console.log("转账成功！");
    console.log("");
  }

  // 2. 设置税率（仅所有者）
  if (false) { // 设置为 true 来执行
    console.log("=== 设置税率 ===");
    const newBuyTax = 300;  // 3%
    const newSellTax = 400; // 4%
    const tx = await memeToken.setTaxRates(newBuyTax, newSellTax);
    await tx.wait();
    console.log("税率已更新：买入", newBuyTax / 100, "%，卖出", newSellTax / 100, "%");
    console.log("");
  }

  // 3. 添加流动性（仅所有者）
  if (false) { // 设置为 true 来执行
    console.log("=== 添加流动性 ===");
    const tokenAmount = ethers.parseEther("1000000"); // 100 万代币
    const ethAmount = ethers.parseEther("0.1");       // 0.1 ETH
    const deadline = Math.floor(Date.now() / 1000) + 300; // 5分钟后

    // 先批准代币
    console.log("批准代币...");
    await memeToken.approve(CONTRACT_ADDRESS, tokenAmount);
    
    // 添加流动性
    console.log("添加流动性...");
    const tx = await memeToken.addLiquidity(tokenAmount, ethAmount, deadline, {
      value: ethAmount
    });
    await tx.wait();
    console.log("流动性添加成功！");
    console.log("");
  }

  // 4. 启用交易（仅所有者）
  if (false) { // 设置为 true 来执行
    console.log("=== 启用交易 ===");
    const tx = await memeToken.enableTrading();
    await tx.wait();
    console.log("交易已启用！");
    console.log("");
  }

  // 5. 查询交易限制
  console.log("=== 查询交易限制 ===");
  const maxTransaction = await memeToken.maxTransactionAmount();
  const maxWallet = await memeToken.maxWalletAmount();
  const dailyLimit = await memeToken.dailyTradingLimit();
  const limitsEnabled = await memeToken.limitsEnabled();

  console.log("单笔最大交易量:", ethers.formatEther(maxTransaction), symbol);
  console.log("单个地址最大持仓:", ethers.formatEther(maxWallet), symbol);
  console.log("每日交易限额:", ethers.formatEther(dailyLimit), symbol);
  console.log("限制状态:", limitsEnabled ? "已启用" : "已禁用");
  console.log("");

  // 6. 查询地址排除状态
  console.log("=== 查询排除状态 ===");
  const isOwnerExcludedFromTax = await memeToken.isExcludedFromTax(owner.address);
  const isOwnerExcludedFromLimits = await memeToken.isExcludedFromLimits(owner.address);
  
  console.log("所有者税费排除:", isOwnerExcludedFromTax ? "是" : "否");
  console.log("所有者限制排除:", isOwnerExcludedFromLimits ? "是" : "否");
  console.log("");

  console.log("✅ 交互脚本执行完成！");
  console.log("\n提示: 要执行实际操作，请将相应的 if(false) 改为 if(true)");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


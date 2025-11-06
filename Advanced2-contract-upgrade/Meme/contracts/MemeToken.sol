// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MemeToken
 * @dev 一个类似 SHIB 风格的 Meme 代币合约，包含交易税、流动性池集成和交易限制功能
 * @notice 本合约实现了完整的 ERC20 代币功能，并添加了以下特性：
 *         - 交易税机制（买入税和卖出税）
 *         - 与 Uniswap V2 兼容的 DEX 流动性池集成
 *         - 交易限制（单笔最大额度、每日交易限额）
 */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MemeToken is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ 状态变量 ============
    
    /// @notice Uniswap V2 Router 合约地址
    IUniswapV2Router02 public immutable uniswapV2Router;
    
    /// @notice Uniswap V2 Pair 合约地址
    address public uniswapV2Pair;
    
    /// @notice 税费接收地址（用于接收交易税）
    address public taxWallet;
    
    /// @notice 买入税率（以基点表示，100 = 1%）
    uint256 public buyTaxRate;
    
    /// @notice 卖出税率（以基点表示，100 = 1%）
    uint256 public sellTaxRate;
    
    /// @notice 最大税率（基点），防止设置过高的税率
    uint256 public constant MAX_TAX_RATE = 1500; // 15%
    
    /// @notice 单笔交易最大额度（以代币数量计算）
    uint256 public maxTransactionAmount;
    
    /// @notice 单个地址的最大持仓量（以代币数量计算）
    uint256 public maxWalletAmount;
    
    /// @notice 每日交易限额（以代币数量计算）
    uint256 public dailyTradingLimit;
    
    /// @notice 交易启用标志
    bool public tradingEnabled;
    
    /// @notice 是否启用交易限制
    bool public limitsEnabled;
    
    /// @notice 记录每个地址的最后交易时间（用于每日限额检查）
    mapping(address => uint256) public lastTradingDay;
    
    /// @notice 记录每个地址每日的交易量
    mapping(address => uint256) public dailyTradingVolume;
    
    /// @notice 排除税费的地址列表（如 DEX 路由、流动性池等）
    mapping(address => bool) public isExcludedFromTax;
    
    /// @notice 排除交易限制的地址列表（如合约地址、税费钱包等）
    mapping(address => bool) public isExcludedFromLimits;
    
    /// @notice 是否为交易对地址
    mapping(address => bool) public isPair;
    
    /// @notice 记录每日限额重置的时间戳
    uint256 public constant DAY_IN_SECONDS = 86400;

    // ============ 事件 ============
    
    /// @notice 当税费钱包地址更新时触发
    event TaxWalletUpdated(address indexed newWallet, address indexed oldWallet);
    
    /// @notice 当税率更新时触发
    event TaxRateUpdated(uint256 buyTax, uint256 sellTax);
    
    /// @notice 当交易限制更新时触发
    event LimitsUpdated(uint256 maxTransaction, uint256 maxWallet, uint256 dailyLimit);
    
    /// @notice 当地址的税费排除状态更新时触发
    event TaxExclusionUpdated(address indexed account, bool excluded);
    
    /// @notice 当地址的限制排除状态更新时触发
    event LimitsExclusionUpdated(address indexed account, bool excluded);
    
    /// @notice 当交易状态改变时触发
    event TradingStatusUpdated(bool enabled);
    
    /// @notice 当向流动性池添加流动性时触发
    event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount);
    
    /// @notice 当从流动性池移除流动性时触发
    event LiquidityRemoved(uint256 tokenAmount, uint256 ethAmount);

    // ============ 修饰符 ============
    
    /// @dev 检查交易是否已启用
    modifier tradingCheck(address from, address to) {
        require(tradingEnabled || from == owner() || to == owner(), 
                "MemeToken: Trading is not enabled yet");
        _;
    }

    // ============ 构造函数 ============
    
    /**
     * @dev 初始化代币合约
     * @param _name 代币名称
     * @param _symbol 代币符号
     * @param _totalSupply 代币总供应量（以最小单位计算）
     * @param _taxWallet 税费接收地址
     * @param _routerAddress Uniswap V2 Router 地址（主网或测试网）
     * @param _buyTaxRate 买入税率（基点）
     * @param _sellTaxRate 卖出税率（基点）
     * @param _maxTransactionAmount 单笔最大交易量
     * @param _maxWalletAmount 单个地址最大持仓量
     * @param _dailyTradingLimit 每日交易限额
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _taxWallet,
        address _routerAddress,
        uint256 _buyTaxRate,
        uint256 _sellTaxRate,
        uint256 _maxTransactionAmount,
        uint256 _maxWalletAmount,
        uint256 _dailyTradingLimit
    ) ERC20(_name, _symbol) {
        require(_taxWallet != address(0), "MemeToken: Tax wallet cannot be zero address");
        require(_routerAddress != address(0), "MemeToken: Router cannot be zero address");
        require(_buyTaxRate <= MAX_TAX_RATE, "MemeToken: Buy tax rate too high");
        require(_sellTaxRate <= MAX_TAX_RATE, "MemeToken: Sell tax rate too high");
        
        // 初始化 Uniswap Router
        uniswapV2Router = IUniswapV2Router02(_routerAddress);
        
        // 创建或获取交易对地址
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2Router.factory());
        uniswapV2Pair = factory.getPair(address(this), uniswapV2Router.WETH());
        
        if (uniswapV2Pair == address(0)) {
            uniswapV2Pair = factory.createPair(address(this), uniswapV2Router.WETH());
        }
        
        isPair[uniswapV2Pair] = true;
        
        // 设置税费相关参数
        taxWallet = _taxWallet;
        buyTaxRate = _buyTaxRate;
        sellTaxRate = _sellTaxRate;
        
        // 设置交易限制参数
        maxTransactionAmount = _maxTransactionAmount;
        maxWalletAmount = _maxWalletAmount;
        dailyTradingLimit = _dailyTradingLimit;
        limitsEnabled = true;
        
        // 排除税费和限制的地址
        isExcludedFromTax[address(this)] = true;
        isExcludedFromTax[owner()] = true;
        isExcludedFromTax[_taxWallet] = true;
        isExcludedFromTax[address(uniswapV2Router)] = true;
        isExcludedFromTax[uniswapV2Pair] = true;
        
        isExcludedFromLimits[address(this)] = true;
        isExcludedFromLimits[owner()] = true;
        isExcludedFromLimits[_taxWallet] = true;
        isExcludedFromLimits[address(uniswapV2Router)] = true;
        isExcludedFromLimits[uniswapV2Pair] = true;
        
        // 铸造初始供应量给合约所有者
        _mint(owner(), _totalSupply);
    }

    // ============ 核心功能：转账逻辑 ============
    
    /**
     * @dev 重写 _transfer 函数，实现税费和交易限制逻辑
     * @param from 发送地址
     * @param to 接收地址
     * @param amount 转账数量
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override tradingCheck(from, to) nonReentrant {
        require(from != address(0), "MemeToken: Transfer from zero address");
        require(to != address(0), "MemeToken: Transfer to zero address");
        
        // 检查交易限制
        if (limitsEnabled && !isExcludedFromLimits[from] && !isExcludedFromLimits[to]) {
            // 检查单笔交易最大额度
            if (isPair[from] || isPair[to]) {
                require(amount <= maxTransactionAmount, 
                       "MemeToken: Transaction amount exceeds maximum");
            }
            
            // 检查接收地址的最大持仓量（仅当不是卖出时）
            if (!isPair[to]) {
                require(balanceOf(to) + amount <= maxWalletAmount, 
                       "MemeToken: Wallet balance exceeds maximum");
            }
            
            // 检查每日交易限额
            _checkDailyLimit(from, to, amount);
        }
        
        // 计算税费
        uint256 taxAmount = 0;
        if (!isExcludedFromTax[from] && !isExcludedFromTax[to]) {
            if (isPair[from]) {
                // 买入：从交易对买入代币
                taxAmount = (amount * buyTaxRate) / 10000;
            } else if (isPair[to]) {
                // 卖出：向交易对卖出代币
                taxAmount = (amount * sellTaxRate) / 10000;
            }
        }
        
        // 执行转账
        if (taxAmount > 0) {
            uint256 transferAmount = amount - taxAmount;
            super._transfer(from, taxWallet, taxAmount);
            super._transfer(from, to, transferAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }
    
    /**
     * @dev 检查每日交易限额
     * @param from 发送地址
     * @param to 接收地址
     * @param amount 交易数量
     */
    function _checkDailyLimit(address from, address to, uint256 amount) internal {
        uint256 currentDay = block.timestamp / DAY_IN_SECONDS;
        
        // 检查发送地址的每日限额
        if (lastTradingDay[from] != currentDay) {
            lastTradingDay[from] = currentDay;
            dailyTradingVolume[from] = 0;
        }
        
        // 如果是与交易对的交易，计入每日交易量
        if (isPair[from] || isPair[to]) {
            address trader = isPair[from] ? to : from;
            dailyTradingVolume[trader] += amount;
            require(dailyTradingVolume[trader] <= dailyTradingLimit, 
                   "MemeToken: Daily trading limit exceeded");
        }
    }

    // ============ 管理员功能：税费管理 ============
    
    /**
     * @dev 设置税费钱包地址
     * @param _taxWallet 新的税费钱包地址
     */
    function setTaxWallet(address _taxWallet) external onlyOwner {
        require(_taxWallet != address(0), "MemeToken: Tax wallet cannot be zero address");
        address oldWallet = taxWallet;
        taxWallet = _taxWallet;
        
        // 更新排除列表
        isExcludedFromTax[oldWallet] = false;
        isExcludedFromTax[_taxWallet] = true;
        isExcludedFromLimits[oldWallet] = false;
        isExcludedFromLimits[_taxWallet] = true;
        
        emit TaxWalletUpdated(_taxWallet, oldWallet);
    }
    
    /**
     * @dev 设置买入和卖出税率
     * @param _buyTaxRate 买入税率（基点）
     * @param _sellTaxRate 卖出税率（基点）
     */
    function setTaxRates(uint256 _buyTaxRate, uint256 _sellTaxRate) external onlyOwner {
        require(_buyTaxRate <= MAX_TAX_RATE, "MemeToken: Buy tax rate too high");
        require(_sellTaxRate <= MAX_TAX_RATE, "MemeToken: Sell tax rate too high");
        
        buyTaxRate = _buyTaxRate;
        sellTaxRate = _sellTaxRate;
        
        emit TaxRateUpdated(_buyTaxRate, _sellTaxRate);
    }
    
    /**
     * @dev 设置地址的税费排除状态
     * @param account 要设置的地址
     * @param excluded 是否排除税费
     */
    function setTaxExclusion(address account, bool excluded) external onlyOwner {
        require(account != address(0), "MemeToken: Account cannot be zero address");
        isExcludedFromTax[account] = excluded;
        emit TaxExclusionUpdated(account, excluded);
    }

    // ============ 管理员功能：交易限制管理 ============
    
    /**
     * @dev 设置交易限制参数
     * @param _maxTransactionAmount 单笔最大交易量
     * @param _maxWalletAmount 单个地址最大持仓量
     * @param _dailyTradingLimit 每日交易限额
     */
    function setLimits(
        uint256 _maxTransactionAmount,
        uint256 _maxWalletAmount,
        uint256 _dailyTradingLimit
    ) external onlyOwner {
        maxTransactionAmount = _maxTransactionAmount;
        maxWalletAmount = _maxWalletAmount;
        dailyTradingLimit = _dailyTradingLimit;
        
        emit LimitsUpdated(_maxTransactionAmount, _maxWalletAmount, _dailyTradingLimit);
    }
    
    /**
     * @dev 启用或禁用交易限制
     * @param _limitsEnabled 是否启用限制
     */
    function setLimitsEnabled(bool _limitsEnabled) external onlyOwner {
        limitsEnabled = _limitsEnabled;
    }
    
    /**
     * @dev 设置地址的限制排除状态
     * @param account 要设置的地址
     * @param excluded 是否排除限制
     */
    function setLimitsExclusion(address account, bool excluded) external onlyOwner {
        require(account != address(0), "MemeToken: Account cannot be zero address");
        isExcludedFromLimits[account] = excluded;
        emit LimitsExclusionUpdated(account, excluded);
    }
    
    /**
     * @dev 设置交易对地址
     * @param pair 交易对地址
     * @param isPairAddress 是否为交易对
     */
    function setPair(address pair, bool isPairAddress) external onlyOwner {
        require(pair != address(0), "MemeToken: Pair cannot be zero address");
        isPair[pair] = isPairAddress;
    }

    // ============ 管理员功能：交易控制 ============
    
    /**
     * @dev 启用交易（通常在添加流动性后调用）
     */
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "MemeToken: Trading is already enabled");
        tradingEnabled = true;
        emit TradingStatusUpdated(true);
    }
    
    /**
     * @dev 禁用交易（紧急情况使用）
     */
    function disableTrading() external onlyOwner {
        require(tradingEnabled, "MemeToken: Trading is already disabled");
        tradingEnabled = false;
        emit TradingStatusUpdated(false);
    }

    // ============ 流动性池功能 ============
    
    /**
     * @dev 向 Uniswap 流动性池添加流动性
     * @param tokenAmount 要添加的代币数量
     * @param ethAmount 要添加的 ETH 数量（以 Wei 为单位）
     * @param deadline 交易截止时间（Unix 时间戳）
     * @return amountToken 实际添加的代币数量
     * @return amountETH 实际添加的 ETH 数量
     * @return liquidity 获得的流动性代币数量
     */
    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 deadline
    ) external payable onlyOwner nonReentrant returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    ) {
        require(msg.value >= ethAmount, "MemeToken: Insufficient ETH sent");
        require(deadline >= block.timestamp, "MemeToken: Deadline has passed");
        
        // 将代币转移到合约
        _transfer(msg.sender, address(this), tokenAmount);
        
        // 批准 Router 使用代币
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // 添加流动性
        (amountToken, amountETH, liquidity) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // 允许滑点（实际项目中应设置合理的滑点容忍度）
            0, // 允许滑点
            owner(), // 流动性代币发送给所有者
            deadline
        );
        
        // 退还多余的 ETH
        if (msg.value > amountETH) {
            payable(msg.sender).transfer(msg.value - amountETH);
        }
        
        // 退还多余的代币
        if (tokenAmount > amountToken) {
            _transfer(address(this), msg.sender, tokenAmount - amountToken);
        }
        
        emit LiquidityAdded(amountToken, amountETH);
    }
    
    /**
     * @dev 从 Uniswap 流动性池移除流动性
     * @param liquidity 要移除的流动性代币数量
     * @param deadline 交易截止时间（Unix 时间戳）
     * @return amountToken 获得的代币数量
     * @return amountETH 获得的 ETH 数量
     */
    function removeLiquidity(
        uint256 liquidity,
        uint256 deadline
    ) external onlyOwner nonReentrant returns (
        uint256 amountToken,
        uint256 amountETH
    ) {
        require(deadline >= block.timestamp, "MemeToken: Deadline has passed");
        
        // 获取流动性代币（LP Token）
        IERC20 lpToken = IERC20(uniswapV2Pair);
        require(lpToken.balanceOf(msg.sender) >= liquidity, 
               "MemeToken: Insufficient liquidity tokens");
        
        // 转移 LP Token 到合约
        lpToken.safeTransferFrom(msg.sender, address(this), liquidity);
        
        // 批准 Router 使用 LP Token
        lpToken.safeApprove(address(uniswapV2Router), liquidity);
        
        // 移除流动性
        (amountToken, amountETH) = uniswapV2Router.removeLiquidityETH(
            address(this),
            liquidity,
            0, // 允许滑点
            0, // 允许滑点
            msg.sender, // 代币和 ETH 发送给调用者
            deadline
        );
        
        emit LiquidityRemoved(amountToken, amountETH);
    }
    
    /**
     * @dev 手动添加 ETH 到流动性池（通过 Router）
     * @notice 这是一个便利函数，允许直接通过 Router 添加流动性
     */
    function addLiquidityETH() external payable onlyOwner {
        require(msg.value > 0, "MemeToken: Must send ETH");
        require(balanceOf(msg.sender) > 0, "MemeToken: Insufficient token balance");
        
        uint256 tokenAmount = balanceOf(msg.sender);
        _transfer(msg.sender, address(this), tokenAmount);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp + 300 // 5分钟截止时间
        );
    }

    // ============ 紧急功能 ============
    
    /**
     * @dev 紧急提取 ETH（仅所有者）
     */
    function emergencyWithdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev 紧急提取 ERC20 代币（仅所有者）
     * @param token 代币合约地址
     */
    function emergencyWithdrawToken(address token) external onlyOwner {
        require(token != address(0), "MemeToken: Token cannot be zero address");
        IERC20(token).safeTransfer(owner(), IERC20(token).balanceOf(address(this)));
    }
    
    /**
     * @dev 接收 ETH（用于添加流动性）
     */
    receive() external payable {}
}


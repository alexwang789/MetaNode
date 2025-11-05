


## 目录
1. [摘要](#一摘要)
2. [理论分析（40%）](#二理论分析40)
    - [2.1 Geth 在以太坊生态中的定位](#21-geth-在以太坊生态中的定位)
    - [2.2 核心模块与交互关系](#22-核心模块与交互关系)
3. [架构设计（30%）](#三架构设计30)
    - [3.1 分层架构图](#31-分层架构图)
    - [3.2 各层关键模块说明](#32-各层关键模块说明)
4. [实践验证（30%）](#四实践验证30)
    - [4.1 编译并运行 Geth 节点](#41-编译并运行-geth-节点)
    - [4.2 私有链搭建过程](#42-私有链搭建过程)
    - [4.3 智能合约部署与交互](#43-智能合约部署与交互)
    - [4.4 区块浏览器查询结果](#44-区块浏览器查询结果)
5. [交易生命周期流程图](#五交易生命周期流程图)
6. [账户状态存储模型](#六账户状态存储模型)
7. [关键模块分析：les、trie、core/types](#七关键模块分析lestrecoretypes)
8. [评分标准映射](#八评分标准映射)
9. [附录：参考资料与引用](#九附录参考资料与引用)
10. [附录：提交截图清单](#十附录提交截图清单)

---

## 一、摘要

本报告以 Go-Ethereum（Geth）为研究对象，从源码和官方文档出发，分析其在以太坊生态中的定位与作用，详细解读其核心模块设计与交互机制，构建分层架构模型，并通过私链搭建与智能合约部署实验验证理论结果。

研究目标包括：
- 深入理解以太坊执行层客户端的核心架构；
- 掌握区块链状态存储（MPT）、P2P 网络通信、EVM 执行流程；
- 熟悉 Geth 源码目录结构与模块职责；
- 实践运行节点、验证挖矿与部署合约。

---

## 二、理论分析（40%）

### 2.1 Geth 在以太坊生态中的定位

自 **The Merge（合并）** 后，以太坊被拆分为：
- **执行层（Execution Layer, EL）**：负责交易执行、状态维护、EVM；
- **共识层（Consensus Layer, CL）**：负责区块提议、验证与最终性（信标链）。

Geth 是主流 **执行层客户端**，负责：
- EVM 执行环境；
- 状态树（MPT）维护；
- P2P 协议（eth/62, eth/63, les）；
- 交易池、RPC 接口、矿工逻辑。

常见执行客户端还有 Nethermind、Erigon、Besu 等，但 Geth 仍为参考实现。

---

### 2.2 核心模块与交互关系

#### 概览（模块交互图）
[外部输入] → [P2P层/eth协议] → [同步器SyncManager] → [Core Blockchain]
↘ ↓
[TxPool] ←→ [Miner] ←→ [EVM执行] → [Trie状态树/LevelDB]

---

#### (1) 区块链同步协议（eth/62, eth/63）

- 实现于 `eth/protocols/eth`；
- 运行于 DevP2P 的 RLPx 会话层；
- 主要消息类型：
    - `GetBlockHeaders / BlockHeaders`
    - `GetBlockBodies / BlockBodies`
    - `NewBlock / NewBlockHashes`
    - `GetNodeData / NodeData`
- 用于区块、状态、头部的下载与验证。

协议版本：
| 协议版本 | 特征 | 使用范围 |
|-----------|-------|----------|
| eth/62 | 初始同步协议 | 旧版节点 |
| eth/63 | 增加状态数据请求（GetNodeData） | 主流同步协议 |

---

#### (2) 交易池管理与 Gas 机制

- 模块路径：`core/tx_pool.go`
- 功能：
    - 校验交易签名、nonce、gas；
    - 按 gas 价格排序；
    - pending / queued 两级队列；
    - EIP-1559 baseFee + priorityFee 机制。

**Gas 模型**：
- 每条指令消耗 gas；
- baseFee 动态调整；
- 用户可设置 `maxFeePerGas` 与 `maxPriorityFeePerGas`。

---

#### (3) EVM 执行环境构建

- 模块路径：`core/vm/`
- EVM 实现包括 opcode 解释器、gas 计算、异常回退（revert）、日志系统；
- 交易执行由 `core/state/statedb` 管理状态读写；
- 执行结束后生成：
    - 新状态根（stateRoot）
    - receiptsRoot
    - logsBloom（日志布隆过滤）

---

#### (4) 共识算法实现（Ethash / PoS）

| 阶段 | 共识算法 | 实现位置 |
|------|------------|------------|
| PoW 阶段 | Ethash（矿工计算 nonce） | `consensus/ethash` |
| PoS 阶段 | Beacon Chain 驱动，Geth 提供 Engine API | `eth/catalyst` |

当前（2025 年）以太坊主网运行 **PoS**，Geth 仅作为执行客户端，不再承担出块职能。

---

## 三、架构设计（30%）

### 3.1 分层架构图

+---------------------------------------------------------------+
| 应用层 (DApp / RPC) |
+---------------------------------------------------------------+
| JSON-RPC / WebSocket API |
+---------------------------------------------------------------+
| 区块链协议层：eth/les、txpool、miner、sync |
+---------------------------------------------------------------+
| 状态存储层：Trie + LevelDB + Core/Types |
+---------------------------------------------------------------+
| 执行层：EVM + StateDB + GasManager |
+---------------------------------------------------------------+
| 网络层：devp2p、RLPx、discv4/discv5 |
+---------------------------------------------------------------+
| 操作系统 / 网络接口 |
+---------------------------------------------------------------+


---

### 3.2 各层关键模块说明

| 层级 | 模块 | 主要功能 |
|------|------|-----------|
| **P2P 网络层** | `p2p`, `discovery` | 节点发现、加密通信、Kademlia DHT |
| **区块链协议层** | `eth`, `les`, `txpool`, `miner` | 区块同步、轻节点协议、交易池管理、打包交易 |
| **状态存储层** | `trie`, `core/types` | MPT 实现、账户状态存储、区块数据结构定义 |
| **EVM 执行层** | `core/vm`, `state` | 智能合约执行、状态变更、gas 结算 |

---

## 四、实践验证（30%）

### 4.1 编译并运行 Geth 节点

git clone https://github.com/ethereum/go-ethereum.git
cd go-ethereum
make geth
./build/bin/geth version


#启动开发节点：
./build/bin/geth --dev --http --http.api eth,net,web3,miner console

#验证：
> eth.blockNumber
> miner.start()
> eth.blockNumber

截图要求：
make geth 成功日志；
启动控制台输出；
区块号递增截图。

4.2 私有链搭建过程
Genesis 文件（genesis.json）:
{
  "config": {
    "chainId": 1337,
    "homesteadBlock": 0,
    "byzantiumBlock": 0,
    "londonBlock": 0
  },
  "difficulty": "0x20000",
  "gasLimit": "0x1fffffffffffff",
  "alloc": {}
}

#初始化：
./build/bin/geth --datadir ~/private-geth init genesis.json

#启动节点：
./build/bin/geth --datadir ~/private-geth --networkid 1337 --http --http.api "eth,net,web3,personal,miner" console

#操作：
> personal.newAccount("pass")
> miner.start(1)
> eth.blockNumber

截图要求：
节点启动日志；
挖矿中区块号变化。

4.3 智能合约部署与交互
SimpleStorage.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract SimpleStorage {
    uint public x;
    function set(uint _x) public { x = _x; }
}

#编译：
solcjs --bin --abi SimpleStorage.sol -o build

#部署（在 console）：
var abi = /* paste ABI */;
var bin = "0x" + "<paste bytecode>";
var acct = eth.accounts[0];
personal.unlockAccount(acct, "pass", 300);
var gas = eth.estimateGas({data: bin});
var tx = eth.sendTransaction({from: acct, data: bin, gas: gas + 100000});
eth.getTransactionReceipt(tx);

#交互：
var c = eth.contract(abi).at("<contractAddress>");
c.set(99, {from: acct});
c.x(); // 返回 99

截图要求：
合约部署 TX hash 与合约地址；
c.x() 调用返回值。

4.4 区块浏览器查询结果
可选：
使用 Blockscout 连接私链；
或在 console 查看：
eth.getTransactionReceipt(txhash)
eth.getBlock("latest")
eth.getTransactionReceipt(txhash)
eth.getBlock("latest")

截图要求：
交易回执（status, gasUsed）
最新区块信息（包含交易）

## 四、实践验证（30%）
1. 用户构造并签名交易（Wallet / Web3）
    ↓
2. 通过 RPC 提交至 Geth 或 P2P 网络传播
    ↓
3. TxPool 校验签名、nonce、gas、余额
    ↓
4. 交易被广播到邻居节点
    ↓
5. 矿工/打包器挑选高费率交易组成区块
    ↓
6. EVM 执行交易，StateDB 更新状态
    ↓
7. 生成状态根（stateRoot）、收据根（receiptsRoot）
    ↓
8. 区块广播、共识确认（PoS 最终性）

## 六、账户状态存储模型
以太坊使用 账户模型（Account-based），每个账户包含：
{
"nonce": 1,
"balance": "1000000000000000000",
"storageRoot": "0x...",
"codeHash": "0x..."
}

全局状态通过 Merkle-Patricia Trie (MPT) 组织；
每个合约账户有独立的存储 trie；
状态树根哈希（stateRoot）写入区块头；
Geth 使用 trie 包 + LevelDB 维护状态。

## 七、关键模块分析（les、trie、core/types）
| 模块             | 源码路径                | 功能描述                                  |
| -------------- | ------------------- | ------------------------------------- |
| **les**        | `eth/protocols/les` | 轻节点协议，实现按需状态请求，节省资源                   |
| **trie**       | `trie/`             | Merkle-Patricia Trie 实现，用于状态验证与轻客户端证明 |
| **core/types** | `core/types`        | 定义区块头、交易、收据等基础数据结构                    |

## 八、评分标准映射
| 项目    | 权重  | 本报告覆盖                            |
| ----- | --- | -------------------------------- |
| 架构完整性 | 40% | 分层架构图 + 模块交互流程 + 核心模块分析          |
| 实现深度  | 30% | 协议细节、源码路径、Gas / Trie / Txpool 解析 |
| 实践完成度 | 30% | 编译运行命令、私链搭建、合约部署与截图说明            |

## 九、附录：参考资料与引用
1.Ethereum Foundation: Geth Documentation
2.GitHub: go-ethereum Source Code
3.DevP2P / Ethereum Wire Protocol Specification
4.go-ethereum trie Package Documentation (pkg.go.dev)
5.go-ethereum core/types Package Documentation (pkg.go.dev)

## 附录：提交截图清单
| 编号 | 内容                                   | 文件名建议                  |
| -- | ------------------------------------ | ---------------------- |
| 1  | `make geth` 编译成功日志                   | build_success.png      |
| 2  | `--dev` 模式节点启动日志                     | dev_mode.png           |
| 3  | 控制台 `eth.blockNumber` 递增截图           | blocknumber_growth.png |
| 4  | 私链 `init genesis` 与启动日志              | private_chain_init.png |
| 5  | 合约部署交易与 contractAddress              | deploy_contract.png    |
| 6  | 调用合约函数返回值                            | call_contract.png      |
| 7  | 区块浏览器或 `eth.getBlock("latest")` 查询结果 | block_info.png         |

# Outstake -- 完全围绕 Blast 原生收益构建

_Not Only Blast L2 Native Yield Stake Protocol_  
_Outstake 是 Blast L2 上第一个完全围绕 Blast 原生收益构建 LSDFI 协议_  
_我们构建了第一个与 ETH 和 USDB 原生收益率的去中心化算法稳定币_  

## Blast 是一个什么样的 L2?

在 Blast 的[官方文档](https://docs.blast.io/about-blast "Blast 官方文档")中可以看到
> Blast 是唯一具有 ETH 和稳定币原生收益的以太坊 L2。Blast 收益来自 ETH 质押和 RWA 协议。这些去中心化协议的收益会自动传回给 Blast 用户。其他 L2 的默认利率为 0%。在 Blast 上，ETH 为 4%，稳定币为 5%。这种收益使得为 Dapp 创建新的商业模式成为可能，而这在其他 L2 上是不可能的。

通过上面的描述我们可以知道，只要用户将 ETH 跨链到 Blast，用户的 EOA 钱包中就会自动开始产生原生收益。而智能合约中同样可以产生原生收益，不过此时的收益是由智能合约控制的，合约开发者可以通过 Blast 的接口提取收益。
  
## 怎样利用原生收益

Blast 提供了一个接口来使合约可以控制合约内部资产所产生的原生收益。 详情：<https://docs.blast.io/building/guides/eth-yield>  

举个例子，开发一个 dex，用户建立交易资金池，将 ETH/TOKEN 流动性添加到流动性合约地址，那么在这个合约地址中的 ETH 也会开始 Yield，开发者可以选择将原生收益据为己有，可以全部返还给用户，可以用来给自己的产品引流，也可以分配给自身协议 Token 的持有者，或者构建一些更复杂的 DEFI 产品。这里的重点是开发者控制了这些 native yield。

## Why choose Outrun?

Native Yield 是一个很有意思的特性，它使构建许多新的商业模式成为了可能。

但是在这背后，对于用户来说，有一个很大的缺陷，或者说是未被重视的的地方 -- 那就是用户是否愿意将自己的原生收益让开发者控制，如果用户想要自己控制这些原生收益呢？

Outrun 的诞生就是用来解决这个问题的，Outrun 是领先的原生收益质押解决方案，通过使用 Outrun 进行质押，用户可以自己控制自己资产所产生的原生收益，并且用户的代币可以保持流动性，并且可以在一系列 DeFi 应用程序中使用，从而获得额外的奖励。

## Stake ETH

Outrun 生态系统中 ETH 有两种形式，orETH (Outrun ETH) 和 osETH (Outrun staked ETH)，此外还将引入 REY (Outrun ETH YieldToken) 代表对质押的 orETH 的收益权。

### orETH

orETH 是一种与 ETH 挂钩的稳定币，可以通过向 OutETHVault 质押 ETH 来 1 : 1 获得。  

因此 1 个orETH 始终代表 1 个 ETH，并且 orETH 在流通中的数量与 Outrun ETH 系统中的 ETH 数量相匹配，用户随时可以将 orETH 转换为 ETH。单独持有 orETH 并不会获得质押产生的原生收益的，应该将其视为持有 ETH 的类比。  

orETH 同时会作为在 Outswap 中的 Wrapped ETH.

### osETH

osETH 是向 ORETHStakeManager 质押 orETH 而铸造的质押本金代币，旨在积累 Blast 产生的原生收益并释放质押代币的流动性。

用户质押 orETH 时需要指定一个锁定时间从而铸造 osETH 与 YieldToken，osETH 数量并不是按质押的 orETH 来 1 : 1 铸造的，而是使用下面利息凭证比例算法来计算的。  

<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/f1553bab-9eac-47f9-a9f7-293fa787f513" width="750" height="30">  
</div>

随着时间的推移，OutETHVault 可以不断产生原生质押收益，相应数量的 orETH 被铸造并添加到 YieldPool 中，新质押的 orETH 所铸造的 osETH 会略微减少，但无论所铸造的 osETH 数量是多少，锁定时间到期后，用户都能销毁当时铸造的 osETH 将自己的质押的 orETH 完全赎回，这种设计是为了保证 osETH 的价格更好得和 ETH 的价格锚定并且增强用户的 ETH 质押收益。
注意：osETH 为质押本金代币，orETH 产生的质押收益由 YieldToken 所有。

### REY

orETH YieldToken (REY) 代表对质押的 orETH 的收益权，通过质押 orETH 并指定一个锁定时间获得。REY 将 orETH 的质押收益单独剥离出来，REY 可以在二级市场上交易以及用于构建其他 DEFI 乐高。  

#### 真正的通用同质化 YieldToken

与目前市场上其他协议的 YieldToken 不同，其他协议的 YieldToken 都是 NFT 或者特殊的 FT，他们都是非同质化的，这种特性导致了 YieldToken 流动性缺失，并且降低了协议的可组合性。  

Outrun 的 orETH YieldToken 是真正的同质化 Token (FT)，流动性非常好，可组合性极强。每将 1 orETH 锁定质押 1 天会铸造 1 个REY，将 _x_ orETH 锁定质押 _y_ 天就会铸造 _xy_ 个 REY，所以理论上 1 REY 锚定 1 orETH 质押 1 天所产生的原生收益。  

REY 可以自由交易，并且可以无限制地即时销毁并赎回 YieldPool 中积累的原生收益，销毁时按销毁的 REY 数量占 REY 总量的比例赎回已产生原生收益。  

#### 更高的原生收益

REY 的存在能帮助长期质押者获得更多的收入。由于销毁时按销毁的 REY 数量占 REY 总供应量的比例赎回已产生原生收益，这可能会产生无常损失 Impermanent Loss (IL)，然而这个 IL 所对应的无常收益 Impermanent Profit (IP) 会分配至长期质押者，从而提高长期质押者的收入。

### REY的数学模型

REY 虽然看起来很简洁，但是由于 REY 可以自由交易，并且任何持有 REY 的用户可以随时赎回原生收益，所以这其中会有一个非常复杂的博弈过程，从而引入一个极其复杂的数学模型。

下面我们构建一个最小的模型来计算无常损失。

假设 YieldPool 中此时的积累的原生收益为 0，我们将 1 REY 锚定 1 orETH 质押 1 天所产生的原生收益 _Y_。用户 _A_ 质押了 _a_ 个 orETH 并锁定 _m_ 天，这会铸造 _am_ 个 REY ，我们将此时其他用户看成一个整体，这个整体看作用户 _B_ 质押了 _b_ 个 orETH 并锁定 n 天，这会铸造 _bn_ 个 REY 。

在 t 天之后  

<div align="center">
    <img src="https://github.com/OutrunDao/Outrun-Stake/assets/32949831/a56994fd-b2d0-42df-9e29-65ae70e68da3" width="450" height="225">  
</div>

用实际收益除以预期收益再减 1 可以得出无常盈亏率 (IPnLR)

<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/6c3f034d-192f-4a4f-a840-17934032be42" width="290" height="135">  
</div>

再用 _IPnLR_ 乘以各自的实际收益 _aty_ 与 _bty_ 可得各自的无常盈亏 _IPnL_  
IPnLa = IPnLRa * Expected Profit_A
IPnLb = IPnLRb * Expected Profit_B

<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/de77277e-d386-4e59-b982-d38022f02028" width="350" height="160">  
</div>

从上图可以得出，用户 A 的与用户 B 的无常盈亏守恒，如果用户 A 与 B 锁定的时间相同，则双方都没有无常盈亏。也就是说一个用户的无常盈亏和质押池中其他用户的加权平均天数相关。

当然上面只是一个最小化模型，实际情况受到多方博弈的影响会更加复杂。所以我们会设定一个最长锁定时间限制 MaxLockInterval，用户锁定时间越靠近 MaxLockInterval，用户的 _IL_ 越小, _IP_ 越大，除此之外用户还可以通过在锁定时间到期时，立即赎回本金然后再质押铸造 REY 来减少 _IL_，获取更多 _IP_，当用户锁定时间为 MaxLockInterval 时一定不会有 _IL_ 。

通过上面的模型，Outrun 可以帮助长期质押者获得更多收益。我们认为 ETH 质押本身致力于使以太坊更去中心化与更安全，所以长期保护以太坊的用户更应该获得更多的奖励。

### 更广阔的前景

REY 不仅仅是帮助 ETH 长期质押这获得更多收益的工具，它是一个真正的通用同质化 Yield Token，同时也是 Web3 第一个锚定 ETH 质押收益率的去中心化算法稳定币，在市场的博弈下 REY 始终与 ETH 质押收益率挂钩，当 REY 被低估时，用户可以从市场上购买 REY 然后销毁并从 YieldPool 赎回对应的收益。在未来 Outrun 会依托 REY 的特性和社区一起构建更多有意思的产品。

### UML时序图

![outstake Sequence Diagram](https://github.com/OutrunDao/Outstake/assets/32949831/d96d83c7-cfc3-4505-8025-f42bebe3acf9)

## Stake USDB

USDB 原生收益质押解决方案与 ETH 大同小异，后续将会完善文档

## FlashLoan

FlashLoan闪电贷是一种在区块链上借入资产的新方式。与传统的担保贷款不同，闪电贷不需要任何抵押品、信用评分或管理来处理无担保贷款。FlashLoan经常被用于链上套利，清算等活动。  

FlashLoan利用原子性允许用户在不提供抵押品的情况下借款。有两个注意事项需要提及。首先，无论何时你在闪电贷中借入资产，你都必须支付使用手续费用。其次，必须在借款的同一笔交易中偿还贷款。  

Outrun提供闪电贷功能，套利者可以通过提供的接口使用该功能，借出用户质押的ETH或USDB，并在同一笔交易中归还。这样可以为质押者的提供更多的收益来源，提高资本利用率。

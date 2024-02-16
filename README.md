# Outrun -- 不仅仅是Blast原生收益质押协议
Not Only Blast L2 Native Yield Stake Protocol

## Blast是一个什么样的L 2?
在Blast的[官方文档](https://docs.blast.io/about-blast "Blast官方文档")中可以看到
> Blast 是唯一具有 ETH 和稳定币原生收益的以太坊L2。Blast 收益来自 ETH 质押和 RWA 协议。这些去中心化协议的收益会自动传回给 Blast 用户。其他 L2 的默认利率为 0%。在 Blast 上，ETH 为 4%，稳定币为 5%。这种收益使得为 Dapp 创建新的商业模式成为可能，而这在其他 L2 上是不可能的。

通过上面的描述我们可以知道，只要用户将ETH跨链到Blast，用户的EOA钱包中就会自动开始产生原生收益。而智能合约中同样可以产生原生收益，不过此时的收益是由智能合约控制的，合约开发者可以通过Blast的接口提取收益。
  
## 怎样利用原生收益
Blast提供了一个接口来使合约可以控制合约内部资产所产生的原生收益。 详情：https://docs.blast.io/building/guides/eth-yield  

举个例子，开发一个dex，用户建立交易资金池，将ETH-TOKEN流动性添加到流动性合约地址，那么在这个合约地址中的ETH也会开始Yield，开发者可以选择将原生收益据为己有，可以全部返还给用户，可以用来给自己的产品引流，也可以分配给自身协议Token的持有者，或者构建一些更复杂的DEFI产品。这里的重点时是开发者owned这些native yield。目前Blast上已经有很多类似的DEX，NFT等等项目

## Why choose Outrun?
Native Yield 是一个很有意思的特性，它使构建许多新的商业模式成为了可能。  
但是在这背后，对于用户来说，有一个很大的缺陷，或者说是未被重视的的地方 -- 那就是用户是否愿意将自己的原生收益让开发者控制，如果用户想要自己控制这些原生收益呢？  
Outrun 的诞生就是用来解决这个问题的，Outrun 是领先的原生收益质押解决方案，通过使用 Outrun 进行质押，用户可以自己控制自己资产所产生的原生收益，并且用户的代币可以保持流动性，并且可以在一系列 DeFi 应用程序中使用，从而获得额外的奖励。

## Stake ETH
Outrun 生态系统中 ETH 有两种形式，RETH ( Outrun Ethe r) 和 PETH ( Principal Ether )，此外还将引入 REY ( RETH YieldToken ) 代表对质押的 RETH 的收益权。

### RETH
RETH 是一种与 ETH 挂钩的稳定币，可以通过向 OutETHVault 质押 ETH 来 1 : 1 获得。  
因此 1 个RETH 始终代表 1 个 ETH，并且 RETH 在流通中的数量与 Outrun ETH 系统中的 ETH 数量相匹配，用户随时可以将 RETH 转换为 ETH。单独持有 RETH 并不会获得质押产生的原生收益的，应该将其视为持有 ETH 的类比。  
RETH 挂钩率定义为在 1.00 汇率的两侧各1％，这意味着保持 1 个 RETH 兑换 1.01-0.9900 ETH 的汇率。

### PETH
PETH 是向 RETHStakeManager 质押 RETH 而铸造的质押本金代币，旨在积累 Blast 产生的原生收益并释放质押代币的流动性。
用户质押 RETH 时需要指定一个锁定时间从而铸造 PETH 与 YieldToken，PETH 数量并不是按质押的 RETH 来 1 : 1 铸造的，而是使用下面利息凭证比例算法来计算的。  
<div align="center">
    <img src="https://github.com/OutrunDao/Outrun/assets/32949831/1da8d6fa-3d16-4f9e-9c39-e34736fa9dd5" width="800" height="50">  
</div>
随着时间的推移，OutETHVault 可以不断产生原生质押收益，相应数量的 RETH 被铸造并添加到 YieldPool 中，新质押的 RETH 所铸造的 PETH 会略微减少，但无论所铸造的 PETH 数量是多少，锁定时间到期后，用户都能销毁当时铸造的 PETH 将自己的质押的 RETH 完全赎回，这种设计是为了保证 PETH 的价格更好得和 ETH 的价格锚定并且增强用户的 ETH 质押收益。
 注意：PETH 为质押本金代币，RETH 产生的质押收益由 YieldToken 所有

### REY
RETH YieldToken (REY) 代表对质押的 RETH 的收益权，通过质押 RETH 并指定一个锁定时间获得。REY 将 RETH 的质押收益单独剥离出来，REY 可以在二级市场上交易以及用于构建其他 DEFI 乐高。

和目前市场上其他协议的 YieldToken 不同，其他协议的 YieldToken 都是 NFT 或者特殊的 FT，他们都是非同质化的，这种特性导致了 YieldToken 流动性缺失，并且降低了协议的可组合性。

Outrun 的 RETH YieldToken 是真正的同质化 Token (FT)，流动性非常好，可组合性极强。每将0.001 ETH 锁定质押 1 天会铸造 1 个REY，将 x ETH 锁定质押 y 天就会铸造 1000xy 个REY，所以理论上1个REY锚定 0.001 ETH 质押 1 天所产生的原生收益。

REY 可以自由交易，并且可以无限制地即时销毁并赎回 YieldPool 中积累的原生收益，销毁时按销毁的 REY 数量占 REY 总量的比例赎回已产生原生收益。

REY 的存在能帮助长期质押者获得更多的收入。由于销毁时按销毁的 REY 数量占 REY 总量的比例赎回已产生原生收益，这会引入一个无常损失 Impermanent Loss (IL)，而这个 Impermanent Loss 所产生的无常收益 Impermanent Profit (IP) 会分配至长期质押者。

### REY的数学模型
REY 虽然看起来很简洁，但是由于 REY 可以自由交易，并且任何持有 REY 的用户可以随时赎回原生收益，所以这其中会有一个非常复杂的博弈过程，从而引入一个极其复杂的非线性的数学模型。
下面我们假设一个最小的模型来计算无常损失。

假设 YieldPool 中此时的积累的原生收益为 0，我们将 1 REY 锚定 1 ETH 质押 1 天所产生的原生收益 Y。用户 A 质押了 a 个 ETH 并锁定 m 天，这会铸造 am 个 REY ，我们将此时其他用户看成一个整体，这个整体看作用户 B 质押了 b 个 ETH 并锁定 n 天，这会铸造 bn 个 REY.

在 t 天之后  
<div align="center">
    <img src="https://github.com/OutrunDao/Outrun/assets/32949831/67709b80-e5c4-4d25-be49-a4d0262c7cbf" width="400" height="200">  
</div>
用实际收益除以预期收益再减 1 可以得出 Impermanent profit and loss ratio无常盈亏率 (IPLR)

再用 IPLR 乘以各自的实际收益 aty 与 bty 可得各自的无常盈亏 IPL  
<div align="center">
    <img src="https://github.com/OutrunDao/Outrun/assets/32949831/1345b375-8d3a-467c-866e-53f3945e77fa" width="666" height="333">  
</div>
从上图公式可知，用户 A 的与用户 B 的无常盈亏守恒，如果用户 A 与 B 锁定的时间相同，则双方都没有无常盈亏。也就是说一个用户的无常盈亏和质押池中其他用户的加权平均天数相关。

当然上面只是一个最小化模型，实际情况受到多方博弈的影响会更加复杂。所以我们会设定一个最长锁定时间限制 MaxLockInterval，用户锁定时间越靠近 MaxLockInterval，用户的 IL 越小, IP 越大，除此之外用户还可以通过在锁定时间到期时，立即赎回本金然后再质押铸造 REY 来减少 IL，获取更多 IP，当用户锁定时间为 MaxLockInterval 时一定不会有 IL 。

通过上面的模型，Outrun 可以帮助长期质押者获得更多收益。我们认为 ETH 质押本身致力于使以太坊更去中心化与更安全，所以长期保护以太坊的用户更应该获得更多的奖励。

### Broader prospects
REY 不仅仅是帮助ETH长期质押这获得更多收益的工具，它是一个真正的同质化 Yield Token，同时也是 Web3 第一个锚定ETH质押收益率的去中心化算法稳定币，在市场的博弈下 REY 始终与 ETH 质押收益率挂钩，在未来 Outrun 会依托这个特性和社区一起构建更多有意思的产品。

## Stake USDB
USDB原生收益质押解决方案与ETH大同小异，后续将会完善文档

# OutSwap
我们将改进集中流动性自动做市商 Uniswap V3，将交易对产生的原生收益分配给被使用的流动性，从而提高做市商的收益。

# FF LaunchPad
还记得前段时间的铭文 Summer 吗？

试想一下将铭文的 FairLaunch 特性与 LaunchPad 结合会是什么样的呢？

像铭文一样发行 ERC20 Token, 用户通过付费 mint token, 在mint的过程中mint 的费用将会和合约中预留的一部分Token 组成 LP 在 DEX 上添加流动性，并设置自定义的交易手续费。LP将锁定一段时间，到期后用户可以取出自己的mint费与预留token组成的LP以及产生的原生收益，而项目团队募集的资金是就是交易手续费。

这种模式更加公平，更加对投资者友好，投资者相当于免费获得了项目方的代币，还以为防止项目团队像传统IDO一样募集大量资金后就不在继续用心开发产品，开发者想募集更多资金就需要在LP锁定期间不断迭代产品，让用户愿意交易自己的代币。

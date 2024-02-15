# Outrun -- 不仅仅是Blast原生收益质押协议（内部粗略产品说明）
Not Only Blast L2 Native Yield Stake Protocol

## Blast是一个什么样的L 2?
在Blast的[官方文档](https://docs.blast.io/about-blast "Blast官方文档")中可以看到
> Blast 是唯一具有 ETH 和稳定币原生收益的以太坊L2。Blast 收益来自 ETH 质押和 RWA 协议。这些去中心化协议的收益会自动传回给 Blast 用户。其他 L2 的默认利率为 0%。在 Blast 上，ETH 为 4%，稳定币为 5%。这种收益使得为 Dapp 创建新的商业模式成为可能，而这在其他 L2 上是不可能的。

也就是说只要用户将ETH跨链到Blast，用户的EOA钱包中就会自动开始Yield，用户可以提取收益。而智能合约中同样可以Yield，合约部署者可以通过Blast的接口提取收益，这些是通过合约代码控制的。因此催生出相关的[Idea](https://docs.blast.io/competition/ideas "Idea") 
  
## 怎样利用原生收益
Blast提供了一个接口来使合约可以控制合约内部资产所产生的原生收益。 详情：https://docs.blast.io/building/guides/eth-yield  

举个例子，开发一个dex，用户建立交易资金池，将ETH-TOKEN流动性添加到流动性合约地址，那么在这个合约地址中的ETH也会开始Yield，开发者可以选择将原生收益据为己有，可以全部返还给用户，可以用来给自己的产品引流，也可以分配给自身协议Token的持有者，或者构建一些更复杂的DEFI产品。这里的重点时是开发者owned这些native yield。目前Blast上已经有很多类似的DEX，NFT等等项目

## 被忽视的地方
在这个看起来很美好的特性中，有一个被忽视的地方，包括Blast官方也在鼓励开发者控制并利用这些原生收益，但是没人注意到用户本身是否愿意将自己的原生收益转让给开发者利用。如果用户想要自己控制这些原生收益呢？  

况且，由于Blast的新特性，目前Blast上正在开发的项目都是新项目，而那些成熟的协议如uniswap，aave，pancake等等如果简单的将原来的代码部署在Blast上，这是对原生收益的浪费，从而导致自身也没有竞争力。他们必须修改很多代码，再测试部署，这是一个很高的成本，对与其他已经成熟的协议来说，都需要重构。

## Outrun是什么？
Outrun是一个原生收益质押协议，类似于LSD协议，将原生收益锁定给用户自身。  
我们将ETH, WETH, USDB(Blast原生稳定币，如何发行目前未知)称为原生收益Token，其他ERC20都是非原生收益Token。  

Outrun生态系统中ETH有两种形式，RETH(Outrun Ether)和PETH(Principal Ether)，此外还将引入ETH YieldToken代表对质押的RETH的收益权。

RETH是一种与ETH松散挂钩的稳定币，因此1个RETH始终代表1个ETH，并且RETH在流通中的数量与Outrun ETH系统中的ETH数量相匹配。单独持有RETH并不符合获得抵押收益的条件，应该将其视为持有ETH的类比。RETH挂钩率定义为在1.00汇率的两侧各1％，这意味着为了保持1个RETH兑换1.01-0.9900 ETH的汇率。

PETH是RETH的质押本金代币，旨在积累Blast产生的原生收益并释放锁仓的流动性。用户随时可以将RETH质押锁定指定的时间并铸造PETH与YieldToken，随着时间的推移，用户可以不断获得原生质押收益。相应数量的RETH被铸造并添加到YieldPool中，使用户可以获得比存入时更多的RETH。在锁定时间到期后可以销毁PETH以赎回质押的RETH
注意：PETH为本金代币，产生的质押收益由YieldToken所有

ETH YieldToken代表对质押的RETH的收益权，通过锁仓质押RETH获得。YieldToken将PETH的质押收益剥离，YieldToken可以在二级市场上交易以及用于构建DEFI乐高。销毁YieldToken即可按销毁的YieldToken数量占YieldToken总量的比例赎回已产生原生收益，赎回操作是没有任何限制的，随时可以进行。  
需要注意的是：质押ETH所铸造YieldToken的数量与质押的ETH数量和质押天数成正比，1个YieldToken理论上锚定一定量的ETH一天所产生的原生收益。所以按照协议的算法，每个人即时赎回的收益会受到其他用户质押时间的影响，协力鼓励长期质押者，因为短期质押所铸造YieldToken的数量较少，即时到期后可赎回的收益也会不及预期，需要手动复投才能赶上长期质押者的收益，并且提前赎回者未领取的原生收益会分配给其他用户。ETH质押是致力于使以太坊平台更去中心化与更安全，所以长期保护以太坊的用户会得到更多的奖励

Outrun协议会统一管理Vault中所有的原生收益，在用户存入原生收益Token后自动持续计算每个用户的原生质押收益以及Outrun协议Token奖励，而RETH,PETH和YieldToken作为Outrun协议的原生收益质押Token，代表着质押的证明，将RETH,PETH和YieldToken销毁后，可以取出自己质押的原生收益Token以及原生yield收益，同时RETH,PETH也作为ETH的稳定币，在链上其他Defi协议比如uniswap中使用，并拥有相同的价值。

USDB相关质押信息与ETH相同

## Dex等同质化产品面临的问题
现在链上的DEFI产品都很模块化，在我看来Dex就该关注Dex该做的事，借贷协议就该关注借贷的事，而原生收益需要一个协议来专门管理。如果RETH和RUSD获得大量采用，Uniswap等老协议不需要修改代码，可以直接使用RETH和RUSD作为基础货币。这时候链上大部分的原生收益都会集中在Outrun协议管理，而用户自己也能收获自己的原生收益，而不是让其他项目方控制属于自己的权益。
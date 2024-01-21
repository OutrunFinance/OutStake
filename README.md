# Bang -- 不仅仅是Blast原生收益质押协议（内部粗略白皮书）
Not Only Blast L2 Native Yield Stake Protocol

## Blast是一个什么样的L 2?
在Blast的[官方文档](https://docs.blast.io/about-blast "Blast官方文档")中可以看到
> Blast 是唯一具有 ETH 和稳定币原生收益的以太坊L2。Blast 收益来自 ETH 质押和 RWA 协议。这些去中心化协议的收益会自动传回给 Blast 用户。其他 L2 的默认利率为 0%。在 Blast 上，ETH 为 4%，稳定币为 5%。这种收益使得为 Dapp 创建新的商业模式成为可能，而这在其他 L2 上是不可能的。

也就是说只要用户将ETH跨链到Blast，用户的EOA钱包中就会自动开始Yield，用户可以提取收益。而智能合约中同样可以Yield，合约部署者可以通过Blast的接口提取收益，这些是通过合约代码控制的。因此催生出相关的[Idea](https://docs.blast.io/competition/ideas "Idea") 
  
## 怎样利用原生收益
Blast提供了一个接口来使合约可以控制合约内部资产所产生的原生收益。 详情：https://docs.blast.io/building/guides/eth-yield  

举个例子，开发一个dex，用户建立交易资金池，将ETH-TOKEN流动性添加到流动性合约地址，那么在这个合约地址中的ETH也会开始Yield，开发者可以选择将原生收益据为己有，可以全部返还给用户，可以用来给自己的产品引流，也可以分配给自身协议Token的持有者，或者构建一些更复杂的DEFI产品。这里的重点时是开发者owned这些native yield。目前Blast上已经有很多类似的DEX，NFT等等项目
![1705585054922](https://github.com/jasonrale/Bang/assets/32949831/253ed035-ed23-4ff7-98dc-f845abae0081)  

## 被忽视的地方
在这个看起来很美好的特性中，有一个被忽视的地方，包括Blast官方也在鼓励开发者控制并利用这些原生收益，但是没人注意到用户本身是否愿意将自己的原生收益转让给开发者利用。如果用户想要自己控制这些原生收益呢？  

况且，由于Blast的新特性，目前Blast上正在开发的项目都是新项目，而那些成熟的协议如uniswap，aave，pancake等等如果简单的将原来的代码部署在Blast上，这是对原生收益的浪费，从而导致自身也没有竞争力。他们必须修改很多代码，再测试部署，这是一个很高的成本，对与其他已经成熟的协议来说，都需要重构。

## Bang是什么？
Bang是一个原生收益质押协议，类似于LSD协议，将原生收益锁定给用户自身。  
我们将ETH, WETH, USDB(Blast原生稳定币，如何发行目前未知)称为原生收益Token，其他ERC20都是非原生收益Token。  

Bang会提供一个Vault金库，用户将原生收益Token存入Vault，Vault会发行非原生收益Token "BETH"和"BUSD"，BETH和BUSD是Bang协议的原生收益质押Token，只有质押ETH, WETH, USDB才能铸造。

Bang协议会统一管理Vault中所有的原生收益，在用户存入原生收益Token后自动持续计算每个用户的原生质押收益以及Bang协议Token奖励，而BETH和BUSD作为Bang协议的原生收益质押Token，代表着收益权的证明，将BETH和BUSD返回Vault销毁后，可以从Vault取出自己质押的原生收益Token以及原生yield收益，同时BETH和BUSD也作为ETH和USDB的稳定币，在链上其他Defi协议比如uniswap中使用，并拥有相同的价值。

## Dex等同质化产品面临的问题
Uniswap作为最知名的AMM协议，占据了AMM市场的绝大部分份额，在我看来，目前的Blast上正在开发的DEX有很多，竞争激烈，他们无非是fork Uniswap后再引入Blast的新特性，但是这些协议绝大部分都会死，甚至全部都会死，被Uniswap取代，而Bang协议则会加快Uniswap的迁移速度。  

现在链上的DEFI产品都很模块化，在我看来Dex就该关注Dex该做的事，借贷协议就该关注借贷的事，而原生收益需要一个协议来专门管理。如果BETH和BUSD获得大量采用，Uniswap等老协议不需要修改代码，可以直接使用BETH和BUSD作为基础货币。这时候链上大部分的原生收益都会集中在Bang协议管理，而用户自己也能收获自己的原生收益，而不是让其他项目方控制属于自己的权益。

## 一个有意思的想法
将Staked与NFT结合，从而使原生收益代币化。例如用户向Vault存入10000 USDB并锁定1年, Vault将会铸造10000 BUSD和一个代表未来1年内10000 USDB产生的原生收益的NFT, 这个NFT享有对应的收益权，并可以在二级市场转卖交易，在这种情况下，一年后用户销毁10000 BUSD只能赎回锁定的10000 USDB，而NFT拥有者可以销毁该NFT来获取这10000 USDB一年内所产生的原生收益。

## 愿景
Bang将会作为Blast上最大的质押协议以及稳定币发行商，在后续将会成为MakerDao那样的存在，将BUSD作为我们协议的原生稳定币，Bang作为Blast的中央银行，我们将带领DEFI再次走向繁荣。  

事实上Bang可以不仅仅只是Native Yield Staked协议，他同样可以成长，后续可以开发DEX，稳定币交换以及借贷功能。  

## 可参考协议
### [Lido](https://lido.fi/)（最知名的ETH LSD协议）
#### stETH

> stETH是Lido版质押ETH的流动性代币。stETH代表Lido中质押的以太币，其价值包括了初始存款和质押奖励。当存入ETH时铸造stETH，当赎回ETH时销毁stETH。stETH数量与在Lido质押的以太币1比1挂钩。在预言机每天报告总质押量的变化时，stETH数量也会随之更新。每天更新stETH余额的机制称为“rebase”。每天UTC时间下午12点，你地址中的stETH余额将基于当前APR而增加。

> stETH可以像使用以太币一样使用，允许你获得ETH 2.0质押奖励，同时又能从去中心化金融产品受益，如额外的收益等。当你在钱包中持有Lido的stETH代币时，每一天都得到质押奖励。它们是具有较好的流动性的，因此你可以随时根据你的需求使用stETH - 交易，出售，交换，将代币投入到DeFi项目等。

Blast上的ETH底层也是通过Lido质押的，和stETH一样都属于变基Token

#### wstETH
> 某些 DeFi 协议本身不支持变基代币。为了防止 stETH 在 DeFi 协议中失去质押奖励，你可以将 stETH 封装成 wstETH。例如，Uniswap上有 stETH/ETH 池，但 Uniswap 合约与变基资产不兼容，因此流动性提供者将无法得到 stETH 的质押奖励。将你的 stETH 封装成 wstETH 可以让质押的 ETH 在更多的 DeFi 协议中使用（例如 Uniswap）而不会失去质押奖励。

Bang协议的质押代币BETH更像是wstETH, 基于Blast的ETH构建的，也就是stETH，而用户可以通过Bang协议控制自己的原生收益，将原生收益与链上DEFI活动分离。
### [SyncClub](https://www.synclub.io/en/liquid-staking/BNB)（BNB链上的LSD协议）
Doc: https://synclub.gitbook.io/synclub-docs/overview/whats-snbnb (文档很简单)  
snBNB不是变基Token, snBNB是利息凭证，具体算法在这个合约里 --> https://bscscan.com/address/0xd24f4bd59fd9c05520f58072a3d3dcf576aac382#code

### [Helio](https://helio.money/) (BNB链上的一个超额抵押稳定币协议)
Doc: https://docs.helio.money/

### [Thala](https://thala.fi/) (Aptos链上的一个LSD和超额抵押稳定币协议)
https://docs.thala.fi/thala-protocol-design/
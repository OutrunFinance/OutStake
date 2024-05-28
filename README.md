[Gitbook](https://outrundao.gitbook.io/outrun/ "OutrunDao Official Doc")  

**Read this in chinese: [中文](README.cn.md)**  

# Outstake -- Built entirely around native yield from Blast

_Not Only Blast L2 Native Yield Stake Protocol_  
_Outstake is the first LSDFi protocol live on Blast._  
_We built the first decentralized algorithmic stablecoin pegged to ETH and USDB yields._

## What's Blast?

In Blast [Official Doc](https://docs.blast.io/about-blast "Blast Official Doc"), we can see.
> Blast is the only Ethereum L2 with native yield for ETH and stablecoins.
Blast yield comes from ETH staking and RWA protocols. The yield from these decentralized protocols is passed back to Blast users automatically. The default interest rate on other L2s is 0%. On Blast, it’s 4% for ETH and 5% for stablecoins.This yield makes it possible to create new business models for Dapps that aren’t possible on other L2s.

Based on the description above, we can understand that as long as users cross-chain their ETH to Blast, their EOA wallets will automatically start generating native yield. Similarly, smart contracts can also generate native yield, but in this case, the yield is controlled by the smart contract, and developers can withdraw the yield through Blast's interface.

## How to use native yield ?

Blast provides an interface for contracts to control the native revenue generated by assets within the contract. Detail：https://docs.blast.io/building/guides/eth-yield

For example, when developing a decentralized exchange (DEX), users establish liquidity pools by adding ETH-TOKEN liquidity to the liquidity contract address. In this contract address, the ETH will also start yielding. Developers can choose to keep the native yield for themselves, return it all to the users, distribute it to holders of their protocol token, or build more complex DeFi products. The key point here is that developers control these native yields.

## Why choose Outrun?

Native Yield is an intriguing feature that enables the possibility of constructing many new business models. However, behind this lies an overlooked aspect – whether users are willing to let developers control their native yields. What if users want to control these native yields themselves?

The emergence of Outrun addresses this issue. Outrun is a leading native yield staking solution that allows users to control the native yields generated by their assets. By staking with Outrun, users can retain control over the native yields produced by their assets. Additionally, users' tokens can maintain liquidity and be utilized across a range of DeFi applications, thereby earning additional rewards.

## Stake ETH

In the Outrun ecosystem, ETH exists in two forms:  

- orETH (Outrun ETH)
- osETH (Outrun staked ETH)

Additionally  

- REY (Outrun ETH YieldToken) represents the yield rights of the staked orETH.

### orETH

orETH is a stablecoin pegged to ETH, which can be obtained at a 1:1 ratio by pledging ETH to the OutETHVault.

Therefore, 1 orETH always represents 1 ETH, and the circulating supply of orETH matches the amount of ETH in the Outrun ETH system. Users can convert orETH to ETH at any time.

Holding orETH alone does not yield native rewards generated by staking; it should be considered analogous to holding ETH.

orETH will also be available as a Wrapped Token on Outswap.

### osETH

osETH is the principal token minted by staking orETH to the ORETHStakeManager, aiming to accumulate native yields and release liquidity for the staked tokens.

When users stake orETH, they need to specify a lock-up period to mint osETH and YieldToken. The quantity of osETH is not minted at a 1:1 ratio with the staked orETH. Instead, it is calculated using the following interest voucher ratio algorithm.

<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/f1553bab-9eac-47f9-a9f7-293fa787f513" width="750" height="30">  
</div>

Over time, the OutETHVault can continuously generate native staking yields, and a corresponding amount of orETH is minted and added to the YieldPool. The newly staked orETH will result in a slight reduction in the minted osETH. However, regardless of the quantity of osETH minted, users can destroy the osETH minted at that time to fully redeem their staked orETH when the lock-up period expires. This design ensures that the price of osETH is better anchored to the price of ETH.

Note: osETH serves as the principal token for staking, while the staking yields generated by orETH are owned by holders of YieldToken. The design of using dual tokens aims to maximize the staking yields for orETH, as not all orETH tokens will be staked.

### REY

orETH YieldToken (REY) represents the yield rights of staked orETH, obtained by staking orETH and specifying a lock-up period. REY separates the staking yields of orETH and can be traded on secondary markets as well as used to construct other DeFi Lego pieces.

Unlike YieldTokens from other protocols currently on the market, which are typically NFTs or special FTs, they are non-fungible. This characteristic leads to a lack of liquidity for YieldTokens and reduces the protocol's composability.

Outrun's orETH YieldToken is a genuinely fungible token (FT), offering excellent liquidity and strong composability. For every 1 orETH staked for 1 day, 1 REY is minted. If _x_ orETH is staked for _y_ days, _xy_ REY will be minted. Therefore, theoretically, 1 REY is anchored to the native yield generated by staking 1 orETH for 1 day.

REY can be freely traded and can be instantly destroyed and redeemed for the accumulated native yield in the YieldPool without restrictions. When destroyed, the native yield generated is redeemed proportionally based on the number of REY destroyed compared to the total REY supply.

The existence of REY helps long-term stakers earn more income. While there might be impermanent loss (_IL_) incurred when destroying REY due to the proportional redemption of native yield based on the number of REY destroyed compared to the total REY supply, the corresponding impermanent profit (_IP_) is distributed to long-term stakers, thereby increasing their income.

### The mathematical model of REY

While REY may appear simple on the surface, the ability for REY to be freely traded and for any REY holder to redeem native yields at any time introduces a highly complex game-theoretic process and mathematical model.

The following, we construct a minimal model to calculate impermanent profit and losses.

Let's assume the current accumulated native yield in the YieldPool is 0. We denote the native yield generated by staking 1 REY for 1 day as _y_. 

User _A_ stakes _a_ amount of orETH and locks it up for _m_ days, resulting in the minting of _am_ REY tokens. We can consider the other users as a collective entity, represented by user _B_, who stakes _b_ amount of orETH and locks it up for _n_ days, resulting in the minting of _bn_ REY tokens.

After _t_ days:

<div align="center">
    <img src="https://github.com/OutrunDao/Outrun-Stake/assets/32949831/a56994fd-b2d0-42df-9e29-65ae70e68da3" width="450" height="225">  
</div>

The Impermanent Profit and Loss Ratio (_IPnLR_) can be obtained by dividing the actual earnings by the expected earnings and then subtracting 1.  
_IPnLR_ = (Actual Earnings / Expected Earnings) - 1

<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/6c3f034d-192f-4a4f-a840-17934032be42" width="290" height="135">  
</div>

The impermanent profit and loss (_IPnL_) can be obtained by multiplying each user's impermanent profit and loss ratio (_IPnLR_) by their respective expected earnings.  
_IPnLa_ = _IPnLRa_ * Expected Profit_A  
_IPnLb_ = _IPnLRb_ * Expected Profit_B  

<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/de77277e-d386-4e59-b982-d38022f02028" width="350" height="160">  
</div>

From the above figure, we can deduce that there is an impermanent profit and loss conservation between User _A_ and User _B_. If User _A_ and User _B_ lock up their assets for the same duration, both parties would experience no impermanent profit or loss. In other words, an individual user's impermanent profit and loss are correlated with the weighted average duration of other users in the staking pool.

Of course, the above is just a minimal model. The actual situation will be more complex due to the influence of multiple players in the game. Therefore, we will set a maximum lock-up time limit -- _MaxLockInterval_. The closer the user's lock-up time is to _MaxLockInterval_, the smaller the _IL_ and the larger the _IP_. Additionally, users can reduce _IL_ and obtain more _IP_ by redeeming their principal immediately upon the expiration of the lock-up period and then staking to mint REY again. When the user's lock-up time is _MaxLockInterval_, there will definitely be no _IL_.

Based on the model presented above, Outrun can help long-term stakers earn more income. We believe that ETH staking itself aims to make Ethereum more decentralized and secure. Therefore, users who contribute to the long-term protection of Ethereum should be rewarded more generously.

### Broader prospects

REY is not just a tool to help ETH long-term stakers earn more income, it is a truly fungible Yield Token and also the first decentralized algorithmic stablecoin anchored to the ETH staking yield rate in Web3. In the market dynamics, REY remains linked to the ETH staking yield rate, when REY is undervalued, users can purchase REY from the market and then destroy it, redeeming the corresponding yield from the YieldPool. In the future, Outrun will leverage the features of REY and collaborate with the community to build more interesting products.

### UML Sequence Diagram

![outstake Sequence Diagram](https://github.com/OutrunDao/Outstake/assets/32949831/d96d83c7-cfc3-4505-8025-f42bebe3acf9)

## Stake USDB

The native yield staking solution for USDB is similar to that of ETH, and documentation will be further improved in the future.

## FlashLoan

FlashLoan is a new way of borrowing assets on the blockchain. Unlike traditional collateralized loans, FlashLoan requires no collateral, credit scoring, or management to process unsecured loans. FlashLoan is often used for on-chain arbitrage, liquidation, and other activities.

FlashLoan leverages atomicity to allow users to borrow without providing collateral. There are two important considerations to mention. Firstly, whenever you borrow assets in a FlashLoan, you must pay a usage fee. Secondly, the loan must be repaid in the same transaction it was borrowed.

Outrun offers FlashLoan functionality, where arbitrageurs can borrow the user's pledged ETH or USDB through the provided interface and repay it in the same transaction. This can provide additional sources of income for stakers and improve capital efficiency.

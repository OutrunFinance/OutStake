# 前端功能需求

## Outstake

### RETH(RUSD)

#### mint

如图，用户在这个页面可以铸造RETH(RUSD)，用户连接钱包后会显示钱包ETH(USDB)余额，用户可以在输入框输入ETH(USDB)数量，也点击Max会直接输入(ETH余额会先扣除交易gas)的ETH(USDB)最大余额，ETH(USDB)与RETH(RUSD)的转换比例恒定为1:1，修改输入框的值也会实时更新可转换的数量。点击mint将会调用RETH(RUSD)的deposit方法，然后弹出过场等待动画，待交易确认后，结束过场等待动画并提示成功mint多少个RETH(RUSD).  
<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/fdd3a366-d525-482d-80f7-f92090ab4576" width="400" height="500">  
</div>

#### withdraw

如图，用户在这个页面可以赎回ETH(USDB)，用户连接钱包后会显示钱包RETH(RUSD)余额，用户可以在输入框输入RETH(RUSD)数量，也点击Max会直接输入RETH(RUSD)最大余额，ETH(USDB)与RETH(RUSD)的转换比例恒定为1:1，修改输入框的值也会实时更新可转换的数量。点击withdraw将会调用RETH(RUSD)的withdraw方法，然后弹出过场等待动画，待交易确认后，结束过场等待动画并提示成功withdraw多少个ETH(USDB).  
<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/63393b02-91f7-4601-9331-03b8b91b9b78" width="400" height="500">  
</div>

#### Info

在mint与withdraw页面需要显示RETH(RUSD)的totalSupply以及其对应的美元TVL，这块需要从Oracle获取ETH的价格
<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/dae43ad4-ac39-4673-b919-ae76f939980d" width="800" height="125">  
</div>

### Stake

如图，用户在这个页面可以质押RETH(RUSD)，用户需要输入的参数为待质押的RETH(RUSD)数量与质押天数。  
用户连接钱包后会显示钱包RETH(RUSD)余额，用户可以在输入框输入RETH(RUSD)数量，也点击Max会直接输入RETH(RUSD)最大余额，RETH(RUSD)与PETH(PUSD)的转换比例通过计算获得，调用RETHStakeManager(RUSDStakeManager)合约的CalcPETH(PUSD)Amount方法，即可获得实时转换比例，修改输入框的值也会实时更新可转换的数量，输入框的值不能低于MINSTAKE最小质押数量。输入框下方需要显示一个实时Exchange rate, 通过调用CalcPETH(PUSD)Amount(1 ether)获得。  
<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/58e5879b-7753-4320-9f7d-d3719130c631" width="400" height="500">  
</div>

除此之外，还需要一个滑动条控制质押天数，滑动条后面有一个输入框，滑动滑动条可以修改输入框里的值，输入框的值需在[minLockupDays, maxLockupDays]区间。  
修改RETH(RUSD)的质押数量与质押天数时会实时计算铸造的REY(RUY)数量，计算方式是质押数量乘以质押天数，需要显示可铸造的REY(RUY)数量。  
点击stake将会调用RETHStakeManager(RUSDStakeManager)的stake方法，然后弹出过场等待动画，待交易确认后，结束过场等待动画并提示成功stake多少个RETH(RUSD)，铸造多少个PETH(PUSD)与REY(RUY).  

### Position

如图类似，在这个页面一排一排地显示当前连接钱包的所有未关闭的Position以及详情信息.  
用户每次质押RETH(RUSD)都会开启一个仓位并发送Event，前端需要调用TheGraph查询当前连接钱包的所有未关闭的仓位。在每个仓位中显示下列信息  

``` solidity
    struct Position {
        uint256 RETHAmount; // 本仓位质押的RETH数量
        uint256 PETHAmount; // 本仓位铸造的PETH数量
        uint256 deadline;   // 锁定截止时间戳
        bool closed;        // 仓位状态
    }
```
<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/056ae990-66e1-4885-bb3d-8bac1438c82b" width="800" height="300">  
</div>

#### Unstake

在Position点击Unstake按钮时，先做两次前置检查：
- 查询用户的PETH余额，如果小于Position.PETHAmount，则弹窗提示用户PETH余额不足。
- 比较当前时间戳与Position.deadline，如果当前时间戳 >= deadline，直接调用StakeManager合约的unStake方法，如果当前时间戳 < deadline，弹窗提示用户是否强制关闭仓位，在用户确认后再去调用StakeManager合约的unStake方法，如果用户取消，则关闭弹窗。

在用户Unstake成功后，弹窗提示用户withdraw了多少个RETH.

#### ExtendLocktime

页面上每一个仓位都有一个延长质押天数的选项，提供一个滑动条给用户使用，延长后的时间距离当前时间的天数需在[minLockupDays, maxLockupDays]区间。  
点击Extend后会调用StakeManager合约的extendLockTime方法。  
在用户ExtendLocktime成功后弹窗提示用户获得了多少REY(Position.RETHAmount * lockupDays)
具体逻辑如下

```solidity
    uint256 newDeadLine = position.deadline + extendDays * DAY;
    uint256 intervalDaysFromNow = (newDeadLine - block.timestamp) / DAY;
    if (intervalDaysFromNow < minLockupDays || intervalDaysFromNow > maxLockupDays) {
        revert InvalidExtendDays();
    }
```

### YieldToken

YieldToken是收益代币，在此页面调用StakeManager的withdrawYield方法可以随时销毁YieldToken以withdraw已产生的原生收益。  
在页面中需要显示YieldPool中已产生的总原生收益，和每YieldToken当前可赎回的原生收益，通过调用StakeManager合约的totalYieldPool()方法获得，使用totalYieldPool除以REY(RUY)的totalSupply可以获得每YieldToken当前可赎回的原生收益。
页面上需要显示RETH(RUSD)平均质押天数，调用StakeManager合约的avgStakeDays()方法可以获得

## Outswap
Outswap前端页面功能参照Uniswap, Pancake之类的DEX即可，需要注意的是，在Outswap Router中新增了许多支持USDB的方法，具体看方法名称，涉及到USDB的需要调用对应的方法。  
如图，前端用户导入池子后，会在Factory合约中检索Pair,然后查询用户的是否持有Lp，有LP就显示池子LP详情信息，由于Outswap对uniswapV2进行修改，手续费是单独领取的，领取的是LP不是双币，所以在详情信息中可以查看可领取的手续费，并添加一个单独领取手续费的按钮。  
<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/ac8b75a4-d8b5-4acb-b886-145a4dd159a3" width="600" height="400">  
</div>

## Fair&Free LaunchPad!


# 可参考协议

Pancake, Uniswap, TraderJoe, Frax Finance, ThalaFi

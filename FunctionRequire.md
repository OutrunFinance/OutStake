# 前端功能需求

## Outstake

### orETH(orUSD)

#### mint

如图，用户在这个页面可以铸造 orETH(orUSD)，用户连接钱包后会显示钱包 ETH(USDB) 余额，用户可以在输入框输入ETH(USDB)数量，也点击Max会直接输入(ETH余额会先扣除交易的 gas)的 ETH(USDB) 最大余额，ETH(USDB) 与 orETH(orUSD) 的转换比例恒定为 1:1，修改输入框的值也会实时更新可转换的数量。点击 mint 将会调用 orETH(orUSD) 的 deposit 方法，然后弹出过场等待动画，待交易确认后，结束过场等待动画并提示成功 mint 多少个 orETH(orUSD).  
- 用户在输入 ETH 的数量时，如果用户余额不足，Mint 按钮上的文本应改为 Insufficient Balance，并且点击按钮没有任何调用（或者直接无法输入大于用户余额的数量）
- 用户输入 ETH 的数量后在 orETH 处应显示能 mint 到的 orETH 数量（1：1）
<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/fdd3a366-d525-482d-80f7-f92090ab4576" width="400" height="500">  
</div>

#### withdraw

点击双向箭头会切换到 withdra 页面，用户在这个页面可以赎回 ETH(USDB)，用户连接钱包后会显示钱包 orETH(orUSD) 余额，用户可以在输入框输入 orETH(orUSD) 数量，也点击 Max 会直接输入 orETH(orUSD) 最大余额，ETH(USDB) 与 orETH(orUSD) 的转换比例恒定为 1:1，修改输入框的值也会实时更新可转换的数量。点击 withdraw 将会调用 orETH(orUSD) 的 withdraw 方法，然后弹出过场等待动画，待交易确认后，结束过场等待动画并提示成功 withdraw 多少个 ETH(USDB).  
<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/63393b02-91f7-4601-9331-03b8b91b9b78" width="400" height="500">  
</div>

#### Info 这个最后做

在 mint 与 withdraw 页面需要显示 orETH(orUSD) 的 totalSupply 以及其对应的美元 TVL ，这块需要从 Oracle 获取 ETH 的价格
<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/dae43ad4-ac39-4673-b919-ae76f939980d" width="800" height="125">  
</div>

### Stake

如图，用户在这个页面可以质押 orETH(orUSD)，用户需要输入的参数为待质押的 orETH(orUSD) 数量与质押天数。  
用户连接钱包后会显示钱包 orETH(orUSD) 余额，用户可以在输入框输入 orETH(orUSD) 数量，也可以点击 Max 会直接输入 orETH(orUSD) 最大余额
- 用户在输入 orETH(orUSD) 数量数量后会计算并显示 osETH(osUSD) 的转换数量，调用 ORETHStakeManager(ORUSDStakeManager) 合约的 calcOSETH(OSUSD)Amount 方法，即可获得实时转换数量，修改输入框的值也会实时更新可转换的数量，输入框的值不能低于 MINSTAKE 最小质押数量。
- 输入框下方需要显示一个实时 Exchange rate, 通过调用 calcOSETH(OSUSD)Amount(1 ether) 获得。
- 需要滑动条控制质押天数，滑动条后面有一个输入框，滑动滑动条可以修改输入框里的值，输入框的值需在 [minLockupDays, maxLockupDays] 区间。  
- 需要显示可铸造的 REY(RUY) 数量，修改 orETH(orUSD) 的质押数量与质押天数时会实时计算铸造的 REY(RUY) 数量，计算方式是质押数量乘以质押天数。  
点击 stake 将会调用 ORETHStakeManager(ORUSDStakeManager) 的 stake 方法，然后弹出过场等待动画，待交易确认后，结束过场等待动画并提示成功stake多少个 orETH(orUSD)，铸造多少个 osETH(osUSD) 与 REY(RUY).

<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/58e5879b-7753-4320-9f7d-d3719130c631" width="400" height="500">  
</div>

### Position

如图类似，在这个页面一排一排地显示当前连接钱包的所有未关闭的 Position 以及详情信息.  
用户每次质押 orETH(orUSD) 都会开启一个仓位并发送 Event ，前端需要调用 TheGraph 查询当前连接钱包的所有未关闭的仓位。在每个仓位中显示下列信息  

``` solidity
    struct Position {
        uint256 orETHAmount; // 本仓位质押的orETH数量
        uint256 osETHAmount; // 本仓位铸造的osETH数量
        uint256 deadline;   // 锁定截止时间戳
        bool closed;        // 仓位状态
    }
```
<div align="center">
    <img src="https://github.com/OutrunDao/Outstake/assets/32949831/056ae990-66e1-4885-bb3d-8bac1438c82b" width="800" height="300">  
</div>

#### Unstake

在 Position 点击 Unstake 按钮时，先做两次前置检查：
- 查询用户的 osETH 余额，如果小于 Position.osETHAmount，则弹窗提示用户 osETH 余额不足。
- 比较当前时间戳与 Position.deadline，如果当前时间戳 >= deadline，直接调用 StakeManager 合约的 unStake 方法，如果当前时间戳 < deadline，弹窗提示用户是否强制关闭仓位，在用户确认后再去调用 StakeManager 合约的 unStake 方法，如果用户取消，则关闭弹窗。

在用户 Unstake 成功后，弹窗提示用户 withdraw 了多少个 orETH.

#### ExtendLocktime

每一个仓位 ExtendLocktime 下拉按钮，点击后会下滑延长这个仓位的视图从而弹出一个滑动条给用户使用，滑动条的 [min, max] 需要计算得出。  
具体计算方法如下  
```solidity
    // 下面是伪代码，需要改用JavaScript实现
    constant uint256 DAY = 24 * 3600;

    // min
    uint256 minLockSecond = minLockupDays * DAY; // 最小锁定秒数，minLockupDays从合约获得
    uint256 newDeadLine = minLockSecond + currentTimestampSecond; // 最小新DeadLine，currentTimestampSecond是系统当前时间戳，单位为秒
    uint256 min = (newDeadLine - position.deadLine) / DAY; // JavaScript实现时需要注意取整，而不是浮点数

    // max
    uint256 maxLockSecond = maxLockupDays * DAY; // 最大锁定秒数，maxLockupDays从合约获得
    uint256 newDeadLine = maxLockSecond + currentTimestampSecond; // 最大新DeadLine，currentTimestampSecond是系统当前时间戳，单位为秒
    uint256 max = (newDeadLine - position.deadLine) / DAY; // JavaScript实现时需要注意取整，而不是浮点数
```
点击 Extend 后会调用 StakeManager 合约的 extendLockTime 方法。  
在用户 ExtendLocktime 成功后弹窗提示用户获得了多少 REY(Position.orETHAmount * lockupDays)

### YieldPool

YieldToken(REY/RUY) 是收益代币，在 YieldPool 页面需要显示下列公共信息  

- orETH(orUSD) 平均质押天数，调用 StakeManager 合约的 avgStakeDays() 方法可以获得。
- YieldPool 当前积累的未领取的总原生收益，调用 StakeManager 合约的 totalYieldPool()方法获得。
- 每个 YieldToken 当前可赎回的原生收益，totalYieldPool 除以 REY(RUY) 的 totalSupply 可以获得每 YieldToken 当前可赎回的原生收益。

页面需要输入框，用户可以输入 REY/RUY 的数量，或者点击 MAX 输入自己的余额，在点击 Withdraw Yield 按钮前会检查用户的 REY/RUY 余额是否足够，余额足够则调用 StakeManager 合约的 withdrawYield 方法销毁 YieldToken 以 withdraw 已产生的原生收益。

# 可参考协议

Frax Finance, ThalaFi

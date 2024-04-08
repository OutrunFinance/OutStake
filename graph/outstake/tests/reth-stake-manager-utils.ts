import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  ClaimMaxGas,
  ExtendLockTime,
  GasManagerTransferred,
  OwnershipTransferred,
  SetForceUnstakeFee,
  SetMaxLockupDays,
  SetMinLockupDays,
  SetOutETHVault,
  StakeRETH,
  Unstake,
  WithdrawYield
} from "../generated/RETHStakeManager/RETHStakeManager"

export function createClaimMaxGasEvent(
  recipient: Address,
  gasAmount: BigInt
): ClaimMaxGas {
  let claimMaxGasEvent = changetype<ClaimMaxGas>(newMockEvent())

  claimMaxGasEvent.parameters = new Array()

  claimMaxGasEvent.parameters.push(
    new ethereum.EventParam("recipient", ethereum.Value.fromAddress(recipient))
  )
  claimMaxGasEvent.parameters.push(
    new ethereum.EventParam(
      "gasAmount",
      ethereum.Value.fromUnsignedBigInt(gasAmount)
    )
  )

  return claimMaxGasEvent
}

export function createExtendLockTimeEvent(
  positionId: BigInt,
  extendDays: BigInt,
  newDeadLine: BigInt,
  mintedREY: BigInt
): ExtendLockTime {
  let extendLockTimeEvent = changetype<ExtendLockTime>(newMockEvent())

  extendLockTimeEvent.parameters = new Array()

  extendLockTimeEvent.parameters.push(
    new ethereum.EventParam(
      "positionId",
      ethereum.Value.fromUnsignedBigInt(positionId)
    )
  )
  extendLockTimeEvent.parameters.push(
    new ethereum.EventParam(
      "extendDays",
      ethereum.Value.fromUnsignedBigInt(extendDays)
    )
  )
  extendLockTimeEvent.parameters.push(
    new ethereum.EventParam(
      "newDeadLine",
      ethereum.Value.fromUnsignedBigInt(newDeadLine)
    )
  )
  extendLockTimeEvent.parameters.push(
    new ethereum.EventParam(
      "mintedREY",
      ethereum.Value.fromUnsignedBigInt(mintedREY)
    )
  )

  return extendLockTimeEvent
}

export function createGasManagerTransferredEvent(
  previousGasManager: Address,
  newGasManager: Address
): GasManagerTransferred {
  let gasManagerTransferredEvent = changetype<GasManagerTransferred>(
    newMockEvent()
  )

  gasManagerTransferredEvent.parameters = new Array()

  gasManagerTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousGasManager",
      ethereum.Value.fromAddress(previousGasManager)
    )
  )
  gasManagerTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "newGasManager",
      ethereum.Value.fromAddress(newGasManager)
    )
  )

  return gasManagerTransferredEvent
}

export function createOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent = changetype<OwnershipTransferred>(
    newMockEvent()
  )

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createSetForceUnstakeFeeEvent(
  forceUnstakeFee: BigInt
): SetForceUnstakeFee {
  let setForceUnstakeFeeEvent = changetype<SetForceUnstakeFee>(newMockEvent())

  setForceUnstakeFeeEvent.parameters = new Array()

  setForceUnstakeFeeEvent.parameters.push(
    new ethereum.EventParam(
      "forceUnstakeFee",
      ethereum.Value.fromUnsignedBigInt(forceUnstakeFee)
    )
  )

  return setForceUnstakeFeeEvent
}

export function createSetMaxLockupDaysEvent(
  maxLockupDays: i32
): SetMaxLockupDays {
  let setMaxLockupDaysEvent = changetype<SetMaxLockupDays>(newMockEvent())

  setMaxLockupDaysEvent.parameters = new Array()

  setMaxLockupDaysEvent.parameters.push(
    new ethereum.EventParam(
      "maxLockupDays",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(maxLockupDays))
    )
  )

  return setMaxLockupDaysEvent
}

export function createSetMinLockupDaysEvent(
  minLockupDays: i32
): SetMinLockupDays {
  let setMinLockupDaysEvent = changetype<SetMinLockupDays>(newMockEvent())

  setMinLockupDaysEvent.parameters = new Array()

  setMinLockupDaysEvent.parameters.push(
    new ethereum.EventParam(
      "minLockupDays",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(minLockupDays))
    )
  )

  return setMinLockupDaysEvent
}

export function createSetOutETHVaultEvent(
  outETHVault: Address
): SetOutETHVault {
  let setOutEthVaultEvent = changetype<SetOutETHVault>(newMockEvent())

  setOutEthVaultEvent.parameters = new Array()

  setOutEthVaultEvent.parameters.push(
    new ethereum.EventParam(
      "outETHVault",
      ethereum.Value.fromAddress(outETHVault)
    )
  )

  return setOutEthVaultEvent
}

export function createStakeRETHEvent(
  positionId: BigInt,
  account: Address,
  amountInRETH: BigInt,
  amountInPETH: BigInt,
  amountInREY: BigInt,
  deadline: BigInt
): StakeRETH {
  let stakeRethEvent = changetype<StakeRETH>(newMockEvent())

  stakeRethEvent.parameters = new Array()

  stakeRethEvent.parameters.push(
    new ethereum.EventParam(
      "positionId",
      ethereum.Value.fromUnsignedBigInt(positionId)
    )
  )
  stakeRethEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  stakeRethEvent.parameters.push(
    new ethereum.EventParam(
      "amountInRETH",
      ethereum.Value.fromUnsignedBigInt(amountInRETH)
    )
  )
  stakeRethEvent.parameters.push(
    new ethereum.EventParam(
      "amountInPETH",
      ethereum.Value.fromUnsignedBigInt(amountInPETH)
    )
  )
  stakeRethEvent.parameters.push(
    new ethereum.EventParam(
      "amountInREY",
      ethereum.Value.fromUnsignedBigInt(amountInREY)
    )
  )
  stakeRethEvent.parameters.push(
    new ethereum.EventParam(
      "deadline",
      ethereum.Value.fromUnsignedBigInt(deadline)
    )
  )

  return stakeRethEvent
}

export function createUnstakeEvent(
  positionId: BigInt,
  amountInRETH: BigInt,
  burnedPETH: BigInt,
  burnedREY: BigInt
): Unstake {
  let unstakeEvent = changetype<Unstake>(newMockEvent())

  unstakeEvent.parameters = new Array()

  unstakeEvent.parameters.push(
    new ethereum.EventParam(
      "positionId",
      ethereum.Value.fromUnsignedBigInt(positionId)
    )
  )
  unstakeEvent.parameters.push(
    new ethereum.EventParam(
      "amountInRETH",
      ethereum.Value.fromUnsignedBigInt(amountInRETH)
    )
  )
  unstakeEvent.parameters.push(
    new ethereum.EventParam(
      "burnedPETH",
      ethereum.Value.fromUnsignedBigInt(burnedPETH)
    )
  )
  unstakeEvent.parameters.push(
    new ethereum.EventParam(
      "burnedREY",
      ethereum.Value.fromUnsignedBigInt(burnedREY)
    )
  )

  return unstakeEvent
}

export function createWithdrawYieldEvent(
  account: Address,
  burnedREY: BigInt,
  yieldAmount: BigInt
): WithdrawYield {
  let withdrawYieldEvent = changetype<WithdrawYield>(newMockEvent())

  withdrawYieldEvent.parameters = new Array()

  withdrawYieldEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  withdrawYieldEvent.parameters.push(
    new ethereum.EventParam(
      "burnedREY",
      ethereum.Value.fromUnsignedBigInt(burnedREY)
    )
  )
  withdrawYieldEvent.parameters.push(
    new ethereum.EventParam(
      "yieldAmount",
      ethereum.Value.fromUnsignedBigInt(yieldAmount)
    )
  )

  return withdrawYieldEvent
}

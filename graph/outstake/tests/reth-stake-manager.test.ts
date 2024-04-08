import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { ClaimMaxGas } from "../generated/schema"
import { ClaimMaxGas as ClaimMaxGasEvent } from "../generated/RETHStakeManager/RETHStakeManager"
import { handleClaimMaxGas } from "../src/reth-stake-manager"
import { createClaimMaxGasEvent } from "./reth-stake-manager-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let recipient = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let gasAmount = BigInt.fromI32(234)
    let newClaimMaxGasEvent = createClaimMaxGasEvent(recipient, gasAmount)
    handleClaimMaxGas(newClaimMaxGasEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("ClaimMaxGas created and stored", () => {
    assert.entityCount("ClaimMaxGas", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "ClaimMaxGas",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "recipient",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "ClaimMaxGas",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "gasAmount",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})

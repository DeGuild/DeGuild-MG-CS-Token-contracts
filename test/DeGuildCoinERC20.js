const { expect } = require("chai");

describe("Deguild Coin ERC20-contract", function () {
  
  before(async function () {
    this.SushiToken = await ethers.getContractFactory("DeGuildCoinERC20")
    this.signers = await ethers.getSigners()
  })

  beforeEach(async function () {
    this.sushi = await this.SushiToken.deploy()
    await this.sushi.deployed()
  })


  it("should have correct name and symbol and decimal", async function () {
    const name = await this.sushi.name()
    const symbol = await this.sushi.symbol()
    expect(name, "SushiToken")
    expect(symbol, "SUSHI")
  })
});
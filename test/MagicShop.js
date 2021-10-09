const { expect } = require("chai");

describe("Magic Shop Contract", function () {
  
  before(async function () {
    this.MagicShop = await ethers.getContractFactory("MagicShop")
    this.signers = await ethers.getSigners()
  })

  beforeEach(async function () {
    this.MagicShopManager = await this.MagicShop.deploy()
    await this.MagicShopManager.deployed()
  })


  it("should have correct name and symbol and decimal", async function () {
    const name = await this.MagicShopManager.name()
    const symbol = await this.MagicShopManager.symbol()
    // const uri = await this.MagicShopManager.
    const address = await this.MagicShopManager.addScroll()

    const address = await this.MagicShopManager.tokenURI(0)
    console.log(address)
    expect(name, "Introduction to Computer Programming")
    expect(symbol, "ICCS101")
  })

});
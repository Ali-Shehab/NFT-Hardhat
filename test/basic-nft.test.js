const { inputToConfig } = require("@ethereum-waffle/compiler")
const { assert } = require("chai")
const { network, deployments, ethers, getNamedAccounts } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Basic NFT Unit Tests", function (){
        let basicNFT
        beforeEach(async() => {
            const {deployer} = await getNamedAccounts()
            await deployments.fixture(["basicNFT"])
            basicNFT = await ethers.getContract("BasicNFT")
        })

        it("Able to mint nft, and everything update properly", async function()
        {

            const tx = await basicNFT.mintNFT()
            await tx.wait(1)
            const tokenURI = await basicNFT.tokenURI(0)
            const tokenCounter = await basicNFT.getTokenCounter()

            assert.equal(tokenCounter.toString(),"1")
            assert.equal(tokenURI,await basicNFT.TOKEN_URI())

        })


    })
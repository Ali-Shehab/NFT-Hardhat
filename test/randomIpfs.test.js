// We are going to skimp a bit on these tests...

const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Random IPFS NFT Unit Tests", async function () {
          let randomIpfsNft, deployer, vrfCoordinatorV2Mock

          beforeEach(async () => {
              accounts = await ethers.getSigners()
              deployer = accounts[0]
              await deployments.fixture(["mocks", "randomipfs"])
              randomIpfsNft = await ethers.getContract("RandomIpfsNft")
              vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
          })

          describe("fulfillRandomWords", () => {
            it("mints NFT after random number is returned", async function () {
                await new Promise(async (resolve, reject) => {
                    randomIpfsNft.once("NftMinted", async () => {
                        try {
                            const tokenUri = await randomIpfsNft.tokenURI("0")
                            const tokenCounter = await randomIpfsNft.getTokenCounter()
                            assert.equal(tokenUri.toString().includes("ipfs://"), true)
                            assert.equal(tokenCounter.toString(), "1")
                            resolve()
                        } catch (e) {
                            console.log(e)
                            reject(e)
                        }
                    })
                    try {
                        const fee = await randomIpfsNft.getMintFee()
                        const requestNftResponse = await randomIpfsNft.requestNFT({
                            value: fee.toString(),
                        })
                        const requestNftReceipt = await requestNftResponse.wait(1)
                        await vrfCoordinatorV2Mock.fulfillRandomWords(
                            requestNftReceipt.events[1].args.requestId,
                            randomIpfsNft.address
                        )
                    } catch (e) {
                        console.log(e)
                        reject(e)
                    }
                })
            })
        })
    })
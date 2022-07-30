const { network, ethers } = require("hardhat")
const {getNamedAccounts,deployments} = hre
const { developmentChains ,networkConfig } = require("../helper-hardhat-config")


module.exports = async(hre) =>{
    const {deploy ,log} = deployments
    const {deployer } = await getNamedAccounts() //a way to get name account
    

    const basicNFT = await deploy("BasicNFT",{
        from: deployer,
        args:[],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(basicNft.address, args)
    }
}

module.exports.tags=["basicNFT"]
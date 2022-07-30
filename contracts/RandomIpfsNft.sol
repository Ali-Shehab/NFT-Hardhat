// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";



error RangeOutOfBounds();
error NeedMoreETHSent();

contract RandomIpfsNft is VRFConsumerBaseV2,ERC721URIStorage,Ownable{
    // when we mint nft, we will trigger a chainlink vrf call to get us a random number
    //using that number, we will get a random nft
    //Pug, shiba Inu , St.Bernard
    //Pug will be super rare
    // Shiba sort of rare
    // St.Bernard common

    // Types
    enum Breed {
        PUG,
        SHIBA_INU,
        ST_BERNARD
    }

    /*EVENTS */

    //events
    event NftRequested(uint256 indexed requestId, address requester);

    event NftMinted(Breed breed, address minter);

    /*EVENTS */

    //chainlink details
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;


    //vrf helper
    mapping(uint256 =>address) public s_requestedIdToSender;


    //NFT vars
    uint256 public s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_dogTokenUris;
    uint256 internal immutable i_mintFee;

    constructor (address vrfCoordinatorV2,uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 mintFee,
        uint32 callbackGasLimit,string[3] memory dogTokenUris) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("Random IPFS NFT", "RIN")
    {
        i_vrfCoordinator =  VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        i_mintFee = mintFee;
        s_dogTokenUris = dogTokenUris;
    }

    //user must pay to get an nft

    //request an NFT
    function requestNFT() public payable  returns(uint256 requestID)
    {
        if ( msg.value < i_mintFee) {
            revert NeedMoreETHSent();
        }
        requestID = i_vrfCoordinator.requestRandomWords( 
        i_gasLane,
        i_subscriptionId,
        REQUEST_CONFIRMATIONS,
        i_callbackGasLimit,
        NUM_WORDS);
        s_requestedIdToSender[requestID] = msg.sender;
        emit NftRequested(requestID, msg.sender);
    }

    //owner of the contract can withdraw

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // if we do directly mint the msg.sender will be the chainlink node that will call fullfillRandomWords
        // so by making a mapping we can know get the user who send the request
        address dogOwner = s_requestedIdToSender[requestId];
        uint256 newTokenID = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        Breed dogBreed = getBreedFromModdedRng(moddedRng);
        _safeMint(dogOwner, newTokenID);
        //we will set the token uri according to the nft the user get
        _setTokenURI(newTokenID, s_dogTokenUris[uint256(dogBreed)]);
        emit NftMinted(dogBreed, dogOwner);
    }   

    //return the nft from array that we want to give to the user
    function getBreedFromModdedRng(uint256 moddedRng) public pure returns (Breed) {
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
            if (moddedRng >= cumulativeSum && moddedRng < chanceArray[i]) {
                return Breed(i);
            }
            // cumulativeSum = cumulativeSum + chanceArray[i];
            cumulativeSum = chanceArray[i];
        }
        revert RangeOutOfBounds();
    }


    //get functions
    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 30, MAX_CHANCE_VALUE];
    }

    function getDogTokenUris(uint256 i) public view returns (string memory) {
        return s_dogTokenUris[i];
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    
}
# What is this?
This is the demo of the timed ownership NFT market place. The website is built on top of https://github.com/scaffold-eth/scaffold-eth/tree/simple-nft-example (Thank you Austin Griffith!) to speed up our development time. 

# Important components

## Keeper.sol
Keeper that's registered on Chainlink Keepers to keep the timed owner data and interact with NFT smart contract to trigger transfer action when the timed ownership is due.

## YourCollectible.sol
The NFT contract that support Timed ownership


# How to run
yarn start and yarn deploy

Note that the listing data is implemented and store in AWS.

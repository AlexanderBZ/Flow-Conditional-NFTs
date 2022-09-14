import RentNFT from 0x...
import ExampleNFT from 0xfe2d32e031469a6d
import NonFungibleToken from 0x631e88ae7f1d7c20
import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868

transaction(nftId: UInt64, price: UInt64, collateral: UInt64, deadLine: UInt64){
    let flowTokenNftCap: Capability<&{FungibleToken.Receiver}>
    let nftCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
        
    prepare(signer: AuthAccount){
        self.flowTokenNftCap = signer.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

            if !signer.getCapability<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(/private/RentNFTProvider)!.check() {
                signer.unlink(/private/RentNFTProvider)
                signer.link<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(/private/RentNFTProvider, target: ExampleNFT.CollectionStoragePath)
        }

        self.nftCap = signer.getCapability<&{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic}>(/private/RentNFTProvider)
    }
    execute{

        let nftRef = self.nftCap.borrow()!.borrowNFT(id: nftId)


        RentNFT.listNFT(
        _flowTokenNftOwnerPubCap: self.flowTokenNftCap, 
        _nftOwnerCap: self.nftCap, 
        _nftType: nftRef.getType(), 
        _nftId: nftId, 
        _nftUuid: nftRef.uuid, 
        _priceToRent: UFix64(price), 
        _collateralToRent: UFix64(collateral), 
        _deadlineOfRent: UFix64(deadLine)
        )

        log("NFT Listed")
    }
}           
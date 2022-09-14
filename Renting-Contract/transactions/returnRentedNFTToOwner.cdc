import ExampleNFT from 0xfe2d32e031469a6d
import NonFungibleToken from 0x631e88ae7f1d7c20
import FungibleToken from 0x9a0766d93b6608b7
import RentNFT from 0x...

transaction(scrowId: UInt64){
    
    prepare(signer: AuthAccount, admin: AuthAccount){
        let scrowCollection = admin.borrow<&RentNFT.ScrowCollection>(from: /storage/RentNFTScrowCollection)!
        
        let nftId = scrowCollection.getScrowData(scrowId: scrowId)!.nftId
        
        let signerCap = signer.borrow<&{NonFungibleToken.Provider}>(from: ExampleNFT.CollectionStoragePath)!
        let _nftRented <- signerCap.withdraw(withdrawID: nftId)

        let nftRenterFlowTokenPubCap = signer.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        
        scrowCollection.returnNftToOwner(scrowId: scrowId, nftRented: <- _nftRented, nftRenterFlowTokenPubCap: nftRenterFlowTokenPubCap)
    }

    execute{}
}
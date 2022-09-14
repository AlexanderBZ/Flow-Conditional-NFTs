import ExampleNFT from 0xfe2d32e031469a6d
import NonFungibleToken from 0x631e88ae7f1d7c20
import FungibleToken from 0x9a0766d93b6608b7
import RentNFT from 0xae95963d3be2cd41
                
transaction(nftToRentUuid: UInt64){
    
    prepare(signer: AuthAccount, admin: AuthAccount){
        let rentNftAdmin = admin.borrow<&RentNFT.Admin>(from: /storage/RentNFTAdmin)
        let nftOwnerCap = signer.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(/private/RentNFTProvider)
        
        rentNftAdmin!.destroyListing(listUuid: nftToRentUuid, nftOwnerCap: nftOwnerCap)
    }

    execute{}
}
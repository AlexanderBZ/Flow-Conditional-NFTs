import ExampleNFT from 0xfe2d32e031469a6d
import NonFungibleToken from 0x631e88ae7f1d7c20
import FungibleToken from 0x9a0766d93b6608b7
import RentNFT from 0x...

transaction(nftToRentUuid: UInt64){
    
    prepare(signer: AuthAccount, admin: AuthAccount){
        let rentNftAdmin = admin.borrow<&RentNFT.Admin>(from: /storage/RentNFTAdmin)!

        let renterNftPubCap = signer.getCapability<&{NonFungibleToken.CollectionPublic}>(ExampleNFT.CollectionPublicPath)
        let renterFlowTokenPubCap = signer.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        let nftData = RentNFT.getListedNftData(id: nftToRentUuid)
        let collateral = nftData.collateral
        let rentPrice = nftData.price
        let paymentValue = collateral + rentPrice

        let vaultRef = signer.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow owner''s Vault reference")
        let paymentToRentAndCollateral <- vaultRef.withdraw(amount: paymentValue)
        
        rentNftAdmin.rentListedNFT(
        renterNftPubCap: renterNftPubCap, 
        renterFlowTokenPubCap: renterFlowTokenPubCap, 
        paymentToRentAndCollateral: <- paymentToRentAndCollateral, 
        nftToRentUuid: nftToRentUuid)
    }

    execute{}
}
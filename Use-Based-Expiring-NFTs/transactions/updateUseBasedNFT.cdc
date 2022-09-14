import UseBased from 0x...
import NonFungibleToken from 0x631e88ae7f1d7c20
import MetadataViews from 0x631e88ae7f1d7c20

transaction(id: UInt64) {
    let ownerCollection: &UseBased.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
    let adminRef: &UseBased.Admin
    prepare(signer: AuthAccount, admin: AuthAccount) {
        
        self.adminRef = admin.borrow<&UseBased.Admin>(from: UseBased.AdminStoragePath)!
        let adminAccount = getAccount(admin.address)

        self.ownerCollection = signer.getCapability(UseBased.CollectionPublicPath)
                                    .borrow<&UseBased.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>()!
    }
    
    execute {
        self.adminRef.expireNFT(owner: self.ownerCollection, id: id)
        log("expired")
    }
}
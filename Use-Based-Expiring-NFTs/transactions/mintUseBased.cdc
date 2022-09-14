import UseBased from 0x...
import NonFungibleToken from 0x631e88ae7f1d7c20
import MetadataViews from 0x631e88ae7f1d7c20

transaction(id: UInt64, name: String, description: String, thumbnail: String, expired: Bool) {
    let recipientCollection: &UseBased.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
    let admin: &UseBased.Admin
    prepare(signer: AuthAccount, admin: AuthAccount) {
    self.admin = admin.borrow<&UseBased.Admin>(from: UseBased.AdminStoragePath)!
    let paymentReceiverAcct = getAccount(admin.address)

    //SETUP EXAMPLE NFT COLLECTION
    if signer.borrow<&UseBased.Collection>(from: UseBased.CollectionStoragePath) == nil {
        signer.save(<- UseBased.createEmptyCollection(), to: UseBased.CollectionStoragePath)
        signer.link<&UseBased.Collection{NonFungibleToken.Provider ,NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(UseBased.CollectionPublicPath, target: UseBased.CollectionStoragePath)
    }

    self.recipientCollection = signer.getCapability(UseBased.CollectionPublicPath)
                                .borrow<&UseBased.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>()!
    }
    
    execute {
    self.admin.mintNFT(recipient: self.recipientCollection,id: id, name: name, description: description, thumbnail: thumbnail, expired: expired)
    log("minted")
    }
}
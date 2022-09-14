import TimeBasedExpirationNft from 0x...
import NonFungibleToken from 0x9b19adaf4947d5b5
import MetadataViews from 0x9b19adaf4947d5b5

transaction(name: String, description: String, thumbnail: String, type: String, hour: UInt64) {
    let RecipientCollection: &TimeBasedExpirationNft.Collection{NonFungibleToken.CollectionPublic}
    let timestamp: UFix64
    let expirationTime: UFix64

    prepare(signer: AuthAccount) {
    self.timestamp = getCurrentBlock().timestamp
    self.expirationTime = self.timestamp + UFix64(hour)
    
  
    //SETUP EXAMPLE NFT COLLECTION
    if signer.borrow<&TimeBasedExpirationNft.Collection>(from: TimeBasedExpirationNft.CollectionStoragePath) == nil {
      signer.save(<- TimeBasedExpirationNft.createEmptyCollection(), to: TimeBasedExpirationNft.CollectionStoragePath)
      signer.link<&TimeBasedExpirationNft.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(TimeBasedExpirationNft.CollectionPublicPath, target: TimeBasedExpirationNft.CollectionStoragePath)
    }
    
    self.RecipientCollection = signer.getCapability(TimeBasedExpirationNft.CollectionPublicPath)
                                .borrow<&TimeBasedExpirationNft.Collection{NonFungibleToken.CollectionPublic}>()!
    }

    execute {
      TimeBasedExpirationNft.mintNFT(recipient: self.RecipientCollection, name: name, description: description, thumbnail: thumbnail, type: type,  timestamp: self.timestamp, expirationTime: self.expirationTime)
    }
  }
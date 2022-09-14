import UseBased from 0x...
import MetadataViews from 0x631e88ae7f1d7c20

pub fun main(address: Address): [UseBased.NFTMetaData] {
    let collection = getAccount(address).getCapability(UseBased.CollectionPublicPath)
                    .borrow<&{MetadataViews.ResolverCollection}>()
                    ?? panic("Could not borrow a reference to the nft collection")
    let ids = collection.getIDs()
    let answer: [UseBased.NFTMetaData] = []
    for id in ids {
    
    let nft = collection.borrowViewResolver(id: id)
    let view = nft.resolveView(Type<UseBased.NFTMetaData>())!
    let display = view as! UseBased.NFTMetaData
    answer.append(display)
    }
    
    return answer
}
//TESTNET ADDRESSES
import NonFungibleToken from 0x9b19adaf4947d5b5
import MetadataViews from 0x9b19adaf4947d5b5

pub contract TimeBasedExpirationNft: NonFungibleToken {

        pub event ContractInitialized()
        pub event Withdraw(id: UInt64, from: Address?)
        pub event Deposit(id: UInt64, to: Address?)
        pub event NFTMovedToExpired(id: UInt64)
        
        //Collection Paths
        pub let CollectionStoragePath: StoragePath
        pub let CollectionPublicPath: PublicPath
        
        //Total supply of minted TimeNFTs
        pub var totalSupply: UInt64

        // List of all notExpired NFTs
        pub var notExpiredNFTs: {UInt64: UFix64}

        //List of IDs that have been expired
        pub var expiredNFTs: [UInt64]

        //Add NFT id to the expiredNFTs array
        pub fun addExpiredNFT(id: UInt64) {
            if(getCurrentBlock().timestamp > TimeBasedExpirationNft.notExpiredNFTs[id]!) {
                self.notExpiredNFTs.remove(key: id)
                self.expiredNFTs.append(id)
                emit NFTMovedToExpired(id: id)
            }
        }

        //Get the Expiration Timestamp of a especific the NFT
        pub fun getNftExpiredTimestamp(id: UInt64): String? {
            return self.notExpiredNFTs[id]!.toString()
        }

        //Get all NFTs IDs that have been expired
        pub fun getExpiredNftIDs(): [UInt64] {
                return self.expiredNFTs
        }

        pub struct NFTMetaData {
            pub let id: UInt64
            pub let name: String
            pub let description: String
            pub let thumbnail: String
            pub let type: String
            pub let timestamp: UFix64
            pub let expirationTime: UFix64

            init(_id: UInt64, _name: String, _description: String, _thumbnail: String, _type: String, _timestamp: UFix64, _expirationTime: UFix64) {
                self.id = _id
                self.name = _name
                self.description = _description
                self.thumbnail = _thumbnail
                self.type = _type
                self.timestamp = _timestamp
                self.expirationTime = _expirationTime
            }
        }

        pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
            pub let id: UInt64
            pub let name: String
            pub let description: String
            pub let thumbnail: String
            pub let type: String
            pub let timestamp: UFix64
            pub let expirationTime: UFix64
            access(self) let royalties: [MetadataViews.Royalty]
            access(self) let metadata: {String: AnyStruct}

            init(name: String, description: String, thumbnail: String, type: String, timestamp: UFix64, expirationTime: UFix64, royalties: [MetadataViews.Royalty], metadata: {String: AnyStruct}) {
                self.id = self.uuid
                self.name = name
                self.description = description
                self.thumbnail = thumbnail
                self.type = type
                self.timestamp = timestamp
                self.expirationTime = expirationTime
                self.royalties = royalties
                self.metadata = metadata

                TimeBasedExpirationNft.notExpiredNFTs[self.id] = self.expirationTime
                TimeBasedExpirationNft.totalSupply = TimeBasedExpirationNft.totalSupply + 1
            }
        
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>(),
                Type<NFTMetaData>()
            ]
        }

        pub fun getMetadata(): Metadata {
            let metadata = TimeBasedExpirationNft.metadata[self.episodeID]!
            metadata.setEdition(self.edition)
            return metadata
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "Time Based NFT Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://open.kickback.fm/nft/".concat(self.episodeID))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: TimeBasedExpirationNft.CollectionStoragePath,
                        publicPath: TimeBasedExpirationNft.CollectionPublicPath,
                        providerPath: /private/TimeBasedExpirationNftCollection,
                        publicCollection: Type<&TimeBasedExpirationNft.Collection{TimeBasedExpirationNft.TimeBasedExpirationNftCollectionPublic}>(),
                        publicLinkedType: Type<&TimeBasedExpirationNft.Collection{TimeBasedExpirationNft.TimeBasedExpirationNftCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&TimeBasedExpirationNft.Collection{TimeBasedExpirationNft.TimeBasedExpirationNftCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-TimeBasedExpirationNft.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://kickback-photos.s3.amazonaws.com/logo.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Time Based NFT Collection",
                        description: "Welcome to the Time Based NFT Collection!",
                        externalURL: MetadataViews.ExternalURL("https://open.kickback.fm"),
                        squareImage: MetadataViews.Media(
                                        file: MetadataViews.HTTPFile(
                                            url: "https://kickback-photos.s3.amazonaws.com/logo.png"
                                        ),
                                        mediaType: "image/png"
                                    ),
                        bannerImage: MetadataViews.Media(
                                        file: MetadataViews.HTTPFile(
                                            url: "https://kickback-photos.s3.amazonaws.com/banner.png"
                                        ),
                                         mediaType: "image/png"
                                    ),
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/viaKickback"),
                            "discord": MetadataViews.ExternalURL("https://discord.com/invite/5BrvrMxaJ2")
                        }
                    )
                case Type<NFTMetaData>():
                    return NFTMetaData(
                        _id: self.id,
                        _name: self.name,
                        _description: self.description,
                        _thumbnail: self.thumbnail,
                        _type: self.type,
                        _timestamp: self.timestamp,
                        _expirationTime: self.expirationTime
                    )
            }

            return nil
                
        }

    }

        
        pub resource Collection:  NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
            // dictionary of NFT conforming tokens
            // NFT is a resource type with an \`UInt64\` ID field
            pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

            init () {
                self.ownedNFTs <- {}
            }

            // withdraw removes an NFT from the collection and moves it to the caller
            pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
                let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
                emit Withdraw(id: token.id, from: self.owner?.address)
                return <-token
            }
            
            // deposit takes a NFT and adds it to the collections dictionary
            // and adds the ID to the id array
            pub fun deposit(token: @NonFungibleToken.NFT) {
                let token <- token as! @TimeBasedExpirationNft.NFT
                let id: UInt64 = token.uuid
                // add the new token to the dictionary which removes the old one
                self.ownedNFTs[id] <-! token
                emit Deposit(id: id, to: self.owner?.address)
            }
            // getIDs returns an array of the IDs that are in the collection
            pub fun getIDs(): [UInt64] { return self.ownedNFTs.keys }

            // borrowNFT gets a reference to an NFT in the collection
            // so that the caller can read its metadata and call its methods
            pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT { 
                return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)! 
            }
            pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
                let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                let TimeBasedExpirationNft = nft as! &TimeBasedExpirationNft.NFT
                return TimeBasedExpirationNft as &AnyResource{MetadataViews.Resolver}
            }
            destroy() {
                destroy self.ownedNFTs
            }
    }

   

        // public function that anyone can call to create a new empty collection
        pub fun createEmptyCollection(): @NonFungibleToken.Collection {
            return <- create Collection()
        }

        pub fun mintNFT(
                recipient: &TimeBasedExpirationNft.Collection{NonFungibleToken.CollectionPublic},
                name: String, description: String, thumbnail: String, type: String, timestamp: UFix64,
                expirationTime: UFix64,) {
                var newNFT <- create NFT( name: name, description: description, thumbnail: thumbnail, type: type, timestamp: timestamp,
                expirationTime: expirationTime,
                )

                //Add the ID and Expiration Time to the Not expired NFTs Dictionary
                TimeBasedExpirationNft.notExpiredNFTs[newNFT.id] = newNFT.expirationTime
                // deposit it in the recipient's account using their reference
                recipient.deposit(token: <-newNFT)
            }

    init() {
        // Initialize the total supply
        self.totalSupply = 0
        self.expiredNFTs = []
        self.notExpiredNFTs = {}

        // Set the named paths
        self.CollectionStoragePath = /storage/TimeBasedExpirationNftCollection
        self.CollectionPublicPath = /public/TimeBasedExpirationNftCollection
        emit ContractInitialized()
    }
}
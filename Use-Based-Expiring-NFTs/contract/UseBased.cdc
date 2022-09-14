//TESTNET ADDRESSES
import NonFungibleToken from 0x631e88ae7f1d7c20
import MetadataViews from 0x631e88ae7f1d7c20

pub contract UseBased: NonFungibleToken {
    pub var totalSupply: UInt64
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    pub struct NFTMetaData {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub var expired: Bool

        init(_id: UInt64, _name: String, _description: String, _thumbnail: String, _expired: Bool) {
            self.id = _id
            self.name = _name
            self.description = _description
            self.thumbnail = _thumbnail
            self.expired = _expired
        }
    }


    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub let expired: Bool
        init(id: UInt64, name: String, description: String, thumbnail: String, expired: Bool) {
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.expired = expired
            UseBased.totalSupply = UseBased.totalSupply + 1
        }
    
        pub fun getViews(): [Type] {
            return [ Type<MetadataViews.Display>(), Type<NFTMetaData>()]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile( url: self.thumbnail )
                    )
                case Type<NFTMetaData>():
                return NFTMetaData(
                    _id: self.id,
                    _name: self.name,
                    _description: self.description,
                    _thumbnail: self.thumbnail,
                    _expired: self.expired
                )
            }
            return nil
        }
    }



    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an \`UInt64\` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        init () { self.ownedNFTs <- {} }
        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @UseBased.NFT
            let id: UInt64 = token.id
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
            let UseBased = nft as! &UseBased.NFT
            return UseBased as &AnyResource{MetadataViews.Resolver}
        }
        destroy() {
            destroy self.ownedNFTs
        }
    }
    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }


    pub resource Admin {
    
        pub fun mintNFT(
            recipient: &UseBased.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic},
            id:UInt64, name: String, description: String, thumbnail: String, expired: Bool) {
            
            var newNFT <- create NFT(id:id, name: name, description: description, thumbnail: thumbnail, expired: expired )
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)

            }

        pub fun expireNFT(
            owner: &UseBased.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic},
            id: UInt64,
            ) {
             
            let oldNFT <- owner.withdraw(withdrawID: id)
            destroy oldNFT 


            var newNFT <- create NFT(id:id, name: "", description: "", thumbnail: "", expired: true )
            owner.deposit(token: <-newNFT)

            }
    }



    init() {
        // Initialize the total supply
        self.totalSupply = 0
        // Set the named paths
        self.CollectionStoragePath = /storage/UseBasedCollection
        self.CollectionPublicPath = /public/UseBasedCollection
        self.AdminStoragePath = /storage/nftAdmin
        let admin <- create Admin()
        self.account.save(<-admin, to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}
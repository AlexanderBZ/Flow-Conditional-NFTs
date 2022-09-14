// OWNER -> WHO IT'S LENDING THE NFT
// RENTER -> WHO IT'S PAYING TO RENT THE NFT

//TESTNET ADDRESSES
import NonFungibleToken from 0x631e88ae7f1d7c20
import FungibleToken from 0x9a0766d93b6608b7

pub contract RentNFT{

    pub event RentNFTDeployed()
    pub event NFTListed(listId: UInt64)
    pub event NFTRemovedFromList(listId: UInt64)
    pub event NFTRented(scrowId: UInt64)
    pub event NFTReturnedToOwner(scrowId: UInt64, nftUuid: UInt64)
    pub event ScrowFinished(scrowId: UInt64)

    access(contract) var nftRentList: @{UInt64 : RentList}
    pub var rentedNftList: {UInt64: NftListedData}

    pub fun getListedNfts(): [UInt64]{
        return self.nftRentList.keys
    }

    pub struct NftListedData{
        pub let listId: UInt64
        pub let id: UInt64
        pub let uuid: UInt64
        pub let price: UFix64
        pub let collateral: UFix64
        pub let deadline: UFix64
        pub let alreadyRented: Bool

        init(_listId: UInt64, _id: UInt64, _uuid: UInt64, _price: UFix64, _collateral: UFix64, _deadline: UFix64, _alreadyRented: Bool){
            self.listId = _listId
            self.id = _id
            self.uuid = _uuid
            self.price = _price
            self.collateral = _collateral
            self.deadline = _deadline
            self.alreadyRented = _alreadyRented
        }
    }

    pub fun getListedNft(id: UInt64): &RentNFT.RentList?{
        return (&self.nftRentList[id] as &RentNFT.RentList?) ?? panic("List does not exist!")
    }

    pub fun getListedNftData(id: UInt64): NftListedData{
        return NftListedData(
            _listId: id,
            _id: self.getListedNft(id: id)!.nftId,
            _uuid: self.getListedNft(id: id)!.uuid,
            _price: self.getListedNft(id: id)!.priceToRent,
            _collateral: self.getListedNft(id: id)!.collateralToRent,
            _deadline: self.getListedNft(id: id)!.deadlineOfRent,
            _alreadyRented: self.getListedNft(id: id)!.alreadyRented
        )
    }

    // LIST A NFT TO BE RENTED AND STORE IT INSIDE OF THE CONTRACT
    pub fun listNFT(
        _flowTokenNftOwnerPubCap: Capability<&{FungibleToken.Receiver}>,
        _nftOwnerCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
        _nftType: Type,
        _nftId: UInt64,
        _nftUuid: UInt64,
        _priceToRent: UFix64,
        _collateralToRent: UFix64,
        _deadlineOfRent: UFix64
    ){
        pre{
            _nftOwnerCap.borrow()!.getIDs().length != 0 : "User does not have and NFT inside his Collection"
            _nftOwnerCap.borrow()!.borrowNFT(id: _nftId) != nil: "User does not have this NFT!"
            //_nftOwnerCap.borrow()!.borrowNFT(id: _nftId).uuid == _nftUuid: "Incorrect ID!"
        }

        let empty <- RentNFT.nftRentList[_nftUuid] <- create RentList(
            _flowTokenNftOwnerPubCap: _flowTokenNftOwnerPubCap,
            _nftOwnerCap: _nftOwnerCap,
            _nftId: _nftId,
            _priceToRent: _priceToRent,
            _collateralToRent: _collateralToRent,
            _deadlineOfRent: _deadlineOfRent,
            _nftUuid: _nftUuid
        )

        destroy empty
        emit NFTListed(listId: _nftUuid)
    }
    

    pub resource RentList{

        // NFT Owner Flow Token Public Capability to deposit the rent payment value
        access(contract) let flowTokenNftOwnerPubCap: Capability<&{FungibleToken.Receiver}>  
        // NFT Owner nft capability to withdraw the NFT once someone rent it
        access(contract) let nftOwnerCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
        
        //Type of NFT listed
        pub let nftType: Type 
        //Id of NFT listed
        pub let nftId: UInt64
        //Uuid of NFT listed
        pub let nftUuid: UInt64
        //Price to rent the NFT listed
        pub let priceToRent: UFix64
        //Collateral value to deposit to rent the NFT listed
        pub let collateralToRent: UFix64
        //Deadline in timestamp of the rent
        pub let deadlineOfRent: UFix64
        //If a NFT was already rented
        pub var alreadyRented: Bool

        // Function to be called to Rent a NFT that it's listed
        pub fun rentListedNFT(
            renterNftPubCap: Capability<&{NonFungibleToken.CollectionPublic}>,
            renterFlowTokenPubCap: Capability<&{FungibleToken.Receiver}>,
            paymentToRentAndCollateral: @FungibleToken.Vault,
        ){
            pre{
                paymentToRentAndCollateral.balance == (self.priceToRent + self.collateralToRent): "Incorrect payment value"
                self.alreadyRented == false: "NFT already rented"
                self.nftOwnerCap.borrow()!.borrowNFT(id: self.nftId) != nil: "NFT does not exist in the collection!"
            }
            
            //DEPOSIT IN THE NFT OWNER WALLET THE RENT VALUE PAYMENT
            let paymentRent <- paymentToRentAndCollateral.withdraw(amount: self.priceToRent)
            self.flowTokenNftOwnerPubCap.borrow()!.deposit(from: <- paymentRent)

            //COLLATERAL
            let collateralValue <- paymentToRentAndCollateral

            //SEND NFT TO RENTER WALLET
            let nft <- self.nftOwnerCap.borrow()!.withdraw(withdrawID: self.nftId)
            let nftUuid = nft.uuid
            renterNftPubCap.borrow()!.deposit(token: <- nft)

            self.alreadyRented = true

            //ADD COLLATERAL VALUE TO SCROW
            // CREATE SCROW RESOURCE
            let scrow <- create Scrow(
            _collateral: <- collateralValue,
            _collateralValue: self.collateralToRent, 
            _deadlineOfRent: self.deadlineOfRent, 
            _nftOwnerFlowTokenPubCap: self.flowTokenNftOwnerPubCap, 
            _nftRenterFlowTokenPubCap: renterFlowTokenPubCap,
            _nftOwnerNftPubCap: self.nftOwnerCap,
            _nftUuid: nftUuid,
            _nftId: self.nftId
            )

            emit NFTRented(scrowId: scrow.uuid)
        
            RentNFT.account.getCapability<&{RentNFT.ScrowPublicCollection}>(/public/RentNFTScrowCollection)!.borrow()!.deposit(token: <- scrow)

            RentNFT.rentedNftList[nftUuid] =  NftListedData(
                _listId: 0,
                _id: self.nftId,
                _uuid: self.nftUuid,
                _price: self.priceToRent,
                _collateral: self.collateralToRent,
                _deadline: self.deadlineOfRent,
                _alreadyRented: true
            )

            let rentList <- RentNFT.nftRentList.remove(key: nftUuid)
            destroy rentList
        }

        // Check if the user has the nftId nft Capability, 
        pub fun removeOfListingAndDestroy(
            _nftOwnerCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
        ){
            pre{
                _nftOwnerCap.borrow()!.borrowNFT(id: self.nftId) != nil: "User does not have this NFT"
            }

            let nftUuid = _nftOwnerCap.borrow()!.borrowNFT(id: self.nftId).uuid

            let rentList <- RentNFT.nftRentList.remove(key: nftUuid)
            
            destroy rentList
            emit NFTRemovedFromList(listId: nftUuid)
        }   

        init(
        _flowTokenNftOwnerPubCap: Capability<&{FungibleToken.Receiver}>,
        _nftOwnerCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
        _nftId: UInt64,
        _priceToRent: UFix64,
        _collateralToRent: UFix64,
        _deadlineOfRent: UFix64,
        _nftUuid: UInt64
        ){
            self.flowTokenNftOwnerPubCap = _flowTokenNftOwnerPubCap
            self.nftOwnerCap = _nftOwnerCap
            self.nftType = _nftOwnerCap.borrow()!.borrowNFT(id: _nftId).getType()
            self.nftId = _nftId
            self.priceToRent = _priceToRent
            self.collateralToRent = _collateralToRent
            self.deadlineOfRent = _deadlineOfRent
            self.alreadyRented = false
            self.nftUuid = _nftUuid
        }
    }

    pub resource interface ScrowPublicCollection{
        pub fun deposit(token: @RentNFT.Scrow)
        pub fun getOpenScrowsIDs(): [UInt64]
        pub fun getEndedScrowIDs(): [UInt64]
        pub fun getEndedScrowData(scrowId: UInt64): ScrowData
        pub fun getScrowData(scrowId: UInt64): ScrowData?
    }

    pub resource ScrowCollection: ScrowPublicCollection{
        pub var scrowsList: @{UInt64: Scrow}
        pub var finishedScrows: {UInt64: ScrowData}

        //Deposit a scrow in the scrow list
        pub fun deposit(token: @RentNFT.Scrow){
            let scrow <- token as! @Scrow 

            let id = scrow.uuid
            let old <- self.scrowsList[id] <- scrow

            destroy  old
        }

        //Function that return the IDs of all Open scrows
        pub fun getOpenScrowsIDs(): [UInt64]{
            return self.scrowsList.keys
        }

        //Function that return the IDs of all Ended scrows
        pub fun getEndedScrowIDs(): [UInt64]{
            return self.finishedScrows.keys
        }

        //Function that return the Ended Scrow Data
        pub fun getEndedScrowData(scrowId: UInt64): ScrowData{
            return self.finishedScrows[scrowId] ?? panic("Scrow ID does not exists or it's not finished yet")
        }

        //Function that return the Open Scrow Data
        pub fun getScrowData(scrowId: UInt64): ScrowData?{
            if(self.scrowsList[scrowId] != nil){
            let scrowRef = (&self.scrowsList[scrowId] as auth &RentNFT.Scrow?)!
                return ScrowData(
                    _nftId: scrowRef.nftId,
                    _nftUuid: scrowRef.nftUuid,
                    _collateralValue: scrowRef.collateralValue,
                    _deadlineOfRent: scrowRef.deadlineOfRent,
                    _endOfRent: scrowRef.endOfRent,
                    _finished: false,
                    _dateOfEnd: UFix64(0)
                )
            }
            return nil
        }

        //Function that return the NFT to the Owner and the Collateral to the renter
        pub fun returnNftToOwner(scrowId: UInt64, nftRented: @NonFungibleToken.NFT, nftRenterFlowTokenPubCap: Capability<&{FungibleToken.Receiver}>){
            pre{
                self.scrowsList[scrowId] != nil: "Scrow does not exists"
                self.getScrowData(scrowId: scrowId)!.nftUuid == nftRented.uuid: "Not same NFT"
            }

            let scrow <- self.scrowsList.remove(key: scrowId)!

            //Return Collateral to Renter
            scrow.returnCollateralToNftRender(_nftRenterFlowTokenPubCap: nftRenterFlowTokenPubCap)

            //Return NFT to owner
            scrow.returnNftToOwner(nft: <- nftRented)

            let scrowData = ScrowData(
                _nftId: scrow.nftId,
                _nftUuid: scrow.nftUuid,
                _collateralValue: scrow.collateralValue,
                _deadlineOfRent: scrow.deadlineOfRent,
                _endOfRent: scrow.endOfRent,
                _finished: true,
                _dateOfEnd: getCurrentBlock().timestamp
            )

            emit NFTReturnedToOwner(scrowId: scrowId, nftUuid: scrow.nftUuid)
            destroy scrow

            self.finishedScrows[scrowId] = scrowData
        }

        //Function that finish a Scrow without returning the NFT and sending the collateral to the NFT owner
        pub fun finishScrow(scrowId: UInt64){
             pre{
                self.scrowsList[scrowId] != nil: "Scrow does not exists"
                self.getScrowData(scrowId: scrowId)!.dateOfEnd > getCurrentBlock().timestamp: "Rent still on time!"
            }

            let scrow <- self.scrowsList.remove(key: scrowId)!
            scrow.sendCollateralToNftOwner()

            let scrowData = ScrowData(
                _nftId: scrow.nftId,
                _nftUuid: scrow.nftUuid,
                _collateralValue: scrow.collateralValue,
                _deadlineOfRent: scrow.deadlineOfRent,
                _endOfRent: scrow.endOfRent,
                _finished: true,
                _dateOfEnd: getCurrentBlock().timestamp
            )
            destroy scrow

            self.finishedScrows[scrowId] = scrowData
            emit ScrowFinished(scrowId: scrowId)
        }


        init(){
            self.scrowsList <- {}
            self.finishedScrows = {}
        }

        destroy (){
            destroy self.scrowsList
        }
    }

    // Struct with the Scrow Data
    pub struct ScrowData{
        pub let nftId: UInt64
        pub let nftUuid: UInt64
        pub let collateralValue: UFix64
        pub let deadlineOfRent: UFix64
        pub let endOfRent: UFix64
        pub let finished: Bool
        pub let dateOfEnd: UFix64

        init(
            _nftId: UInt64,
            _nftUuid: UInt64,
            _collateralValue: UFix64,
            _deadlineOfRent: UFix64,
            _endOfRent: UFix64,
            _finished: Bool,
            _dateOfEnd: UFix64
        ){
            self.nftId = _nftId
            self.nftUuid = _nftUuid
            self.collateralValue = _collateralValue
            self.deadlineOfRent = _deadlineOfRent
            self.endOfRent = _endOfRent
            self.finished = _finished
            self.dateOfEnd = _dateOfEnd
        }
    }

    // Scrow Resource! Here we will store the Rent information! 
    pub resource Scrow{
        pub let nftId: UInt64
        pub let nftUuid: UInt64
        pub let collateral: @FungibleToken.Vault
        pub let collateralValue: UFix64
        pub let deadlineOfRent: UFix64
        pub let endOfRent: UFix64
        pub let nftOwnerFlowTokenPubCap: Capability<&{FungibleToken.Receiver}>
        pub let nftRenterFlowTokenPubCap: Capability<&{FungibleToken.Receiver}>
        pub let nftOwnerNftPubCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>

        pub fun getCollateral(): @FungibleToken.Vault{
            return <- self.collateral.withdraw(amount: self.collateralValue)
        }

        pub fun returnCollateralToNftRender(_nftRenterFlowTokenPubCap: Capability<&{FungibleToken.Receiver}>){
            _nftRenterFlowTokenPubCap.borrow()!.deposit(from: <- self.getCollateral())
        }

        pub fun returnNftToOwner(nft: @NonFungibleToken.NFT){
            self.nftOwnerNftPubCap.borrow()!.deposit(token: <- nft)
        }

        pub fun sendCollateralToNftOwner(){
            self.nftOwnerFlowTokenPubCap.borrow()!.deposit(from: <- self.getCollateral())
        }

        init(
        _collateral: @FungibleToken.Vault, 
        _collateralValue: UFix64,
        _deadlineOfRent: UFix64,
        _nftOwnerFlowTokenPubCap: Capability<&{FungibleToken.Receiver}>,
        _nftRenterFlowTokenPubCap: Capability<&{FungibleToken.Receiver}>,
        _nftOwnerNftPubCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
        _nftUuid: UInt64,
        _nftId: UInt64
        ){
            self.nftUuid = _nftUuid
            self.collateral <- _collateral
            self.collateralValue = _collateralValue
            self.deadlineOfRent = _deadlineOfRent
            self.endOfRent = getCurrentBlock().timestamp + _deadlineOfRent
            self.nftOwnerFlowTokenPubCap = _nftOwnerFlowTokenPubCap
            self.nftRenterFlowTokenPubCap = _nftRenterFlowTokenPubCap
            self.nftOwnerNftPubCap = _nftOwnerNftPubCap
            self.nftId = _nftId
        }

        destroy() {
            destroy self.collateral
        }
    }

    pub resource Admin{
        // Function to be called to Rent a NFT that it's listed
        pub fun rentListedNFT(
            renterNftPubCap: Capability<&{NonFungibleToken.CollectionPublic}>,
            renterFlowTokenPubCap: Capability<&{FungibleToken.Receiver}>,
            paymentToRentAndCollateral: @FungibleToken.Vault,
            nftToRentUuid: UInt64
        ){
            let rentList <- RentNFT.nftRentList.remove(key: nftToRentUuid) ?? panic("List does not exists")

            rentList.rentListedNFT(
            renterNftPubCap: renterNftPubCap, 
            renterFlowTokenPubCap: renterFlowTokenPubCap, 
            paymentToRentAndCollateral: <- paymentToRentAndCollateral)

            RentNFT.nftRentList[nftToRentUuid] <-! rentList
        }

        pub fun destroyListing(
        listUuid: UInt64,
        nftOwnerCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
        ){
            let rentList <- RentNFT.nftRentList.remove(key: listUuid) ?? panic("List does not exists")

            rentList.removeOfListingAndDestroy(_nftOwnerCap: nftOwnerCap)

            destroy rentList
        }
    }

    init(){
     self.nftRentList <- {}
     self.rentedNftList = {}
     self.account.save(<- create ScrowCollection(), to: /storage/RentNFTScrowCollection)

     self.account.link<&{RentNFT.ScrowPublicCollection}>(/public/RentNFTScrowCollection, target: /storage/RentNFTScrowCollection)

     let admin <- create Admin()
        self.account.save(<- admin, to: /storage/RentNFTAdmin)

    emit RentNFTDeployed()
    }
}
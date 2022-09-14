import RentNFT from 0x...

transaction(scrowId: UInt64){   
    prepare(signer: AuthAccount, admin: AuthAccount){
        let scrowCollection = admin.borrow<&RentNFT.ScrowCollection>(from: /storage/RentNFTScrowCollection)!
        scrowCollection.finishScrow(scrowId: scrowId)
    }
    execute{}
}
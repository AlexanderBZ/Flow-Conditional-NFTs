import RentNFT from 0x...
                    
pub fun main(scrowId: UInt64): RentNFT.ScrowData {
    let account = getAccount(0x...)
    let pubCollec = account.getCapability<&{RentNFT.ScrowPublicCollection}>(/public/RentNFTScrowCollection).borrow()!
    return pubCollec.getEndedScrowData(scrowId: scrowId)
}
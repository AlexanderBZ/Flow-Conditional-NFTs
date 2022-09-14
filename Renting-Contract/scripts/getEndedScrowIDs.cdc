import RentNFT from 0x...
                    
pub fun main(): [UInt64] {
    let account = getAccount(0x...)
    let pubCollec = account.getCapability<&{RentNFT.ScrowPublicCollection}>(/public/RentNFTScrowCollection).borrow() ?? panic("Something went wrong!")
    return pubCollec.getEndedScrowIDs()
}
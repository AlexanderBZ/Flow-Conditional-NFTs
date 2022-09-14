import RentNFT from 0x...

pub fun main(id: UInt64): RentNFT.NftListedData {
    return RentNFT.rentedNftList[id]!
}
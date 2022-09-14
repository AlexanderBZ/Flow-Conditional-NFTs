import RentNFT from 0x...

pub fun main(listId: UInt64): RentNFT.NftListedData{
    return RentNFT.getListedNftData(id: listId)
}
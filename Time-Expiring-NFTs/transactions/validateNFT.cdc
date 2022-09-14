import TimeBasedExpirationNft  from 0x...

transaction(id: UInt64) {
    prepare(acct: AuthAccount){}
    execute {
        TimeBasedExpirationNft.addExpiredNFT(id: id)
    }
}
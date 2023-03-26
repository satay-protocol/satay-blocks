module satay_blocks::ditto_blocks {

    use aptos_framework::coin::Coin;
    use aptos_framework::aptos_coin::AptosCoin;

    use ditto_staking::staked_coin::StakedAptos;
    use ditto_staking::ditto_staking;

    /// stake `AptosCoin` through Ditto and mint `StakedAptos` coins
    /// * `aptos_coins` - the `AptosCoin` coins to stake
    /// * `addr` - the address of the account staking the coins
    public fun direct_stake(aptos_coins: Coin<AptosCoin>, addr: address): Coin<StakedAptos> {
        ditto_staking::exchange_aptos(aptos_coins, addr)
    }

    /// unstake `StakedAptos` through Ditto to redeem `AptosCoin` coins
    /// * `staked_aptos` - the `StakedAptos` coins to unstake
    /// * `addr` - the address of the account unstaking the coins
    public fun direct_unstake(staked_aptos: Coin<StakedAptos>, addr: address): Coin<AptosCoin> {
        ditto_staking::exchange_staptos(staked_aptos, addr)
    }
}

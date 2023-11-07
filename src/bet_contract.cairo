use starknet::ContractAddress;
use traits::{Into, TryInto};
use option::OptionTrait;


#[starknet::interface]
trait IBetContract<ContractState>{
    fn make_prediction(ref self: ContractState, _predictionID: felt252, _candidate: felt252, _amount: u256) -> ();
    fn redeem_reward(ref self: ContractState, predictionID: felt252) -> ();
    fn withdraw_tokens(ref self: ContractState, amount: u256) -> ();
}
#[starknet::contract]
mod BetContract{
   
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_block_timestamp;
    use integer::u256_from_felt252;
    use starknet::SyscallResult;
    use starknet::StorageBaseAddress;
    use starknet::storage_address_from_base_and_offset;
    use starknet::storage_write_syscall;
    use starknet::storage_read_syscall;



    #[storage]
    struct Storage{
        predictions: LegacyMap::<felt252, Prediction>,
        user_balances: LegacyMap::<ContractAddress, u256>,
        token: ContractAddress,
        oracle: ContractAddress,
        totalTokens: felt252,
        totalPayout: felt252,
        winnerIndex: u8,
        deadline: u64,
    }
    
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event{
        NewPredictionMarket: NewPredictionMarket,
    }
    #[derive(Drop, starknet::Event)]
    struct NewPredictionMarket{
        predictionID: felt252, 
        participant: ContractAddress,
        amount: u256, 
        candidate: felt252
    }
     #[derive(Drop, Serde)]
   struct Prediction {
       participant: ContractAddress,
       tokenAmount: u256,
       candidate: felt252,
       redeemed: felt252,
}
    #[constructor]
    fn constructor (ref self: ContractState, _tokenAddress: ContractAddress, _oracleAddress: ContractAddress, _totalTokens: felt252, _totalPayout: felt252, _winnerIndex: u8, deadline: u64){
        // assert(!self._tokenAddress.is_zero(), "Token address cannot be zero");
        // assert(!self._oracleAddress.is_zero(), "Oracle address cannot be zero");
        //Updating public variables of the contract
        self.token.write(_tokenAddress);
        self.oracle.write(_oracleAddress);
        self.totalTokens.write(_totalTokens);
        self.totalPayout.write(_totalPayout);
        self.winnerIndex.write(_winnerIndex);
        self.deadline.write(deadline);
    }
    
    #[external(v0)]
    impl BetContractImpl of super::IBetContract<ContractState>{
        fn make_prediction(ref self: ContractState, _predictionID: felt252, _candidate: felt252, _amount: u256) -> (){
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            let token_address = self.token.read();

            // check that the address of the prediction market has been approved by user beforehand to spend the prediction/betting amount of the token
            let allowance = IERC20Dispatcher {contract_address: token_address }.allowance(caller, this_contract);
            assert(allowance >= _amount, 'Contract not approved');
            //Check if user has enough balance to make the prediction
            let userTokenBal = IERC20Dispatcher {contract_address: token_address }.balance_of(caller);
            assert(userTokenBal >= _amount, 'User balance less than amount');

            // if everything checks out, transfer the token amount from user to contract
            IERC20Dispatcher {contract_address: token_address }.transfer_from(caller, this_contract, _amount);

            // once the transfer is successful write a mapping of the prediction for this user address
             let p = Prediction {
                 participant: caller,
                 tokenAmount: _amount,
                 candidate: _candidate,
                 redeemed: bool_to_felt252(false),
             };
             // Set user prediction in the mapping
                self.predictions.write(_predictionID, p);
             // Update user balance
             let user_bal = self.user_balances.read(caller);
             let new_user_bal = user_bal + _amount;
                self.user_balances.write(caller, new_user_bal);
              //Emit new prediction event
              self.emit(
                   NewPredictionMarket{
                       predictionID: _predictionID,
                       participant: caller,
                       amount: _amount,
                       candidate: _candidate,
                   }
               );
        }
        fn redeem_reward(ref self: ContractState, predictionID: felt252) -> (){
            // get the winner and see if the prediction was correct
            let p = self.predictions.read(predictionID);
            let winner = IOracleDispatcher{ contract_address: self.oracle.read()}.getPredictionWinner();
            //Make sure that deadline is passed before reward is processed
            assert(get_block_timestamp() > self.deadline.read(), "Deadline has not passed");
            //Ensure that the prediction has not been redeemed already
            assert(p.redeemed == bool_to_felt252(false), "Reward already redeemed");
            //Ensure that the candidate is the correct winner
            assert(p.candidate == winner, "Prediction was incorrect");
            //Calculate reward
            let reward = (p.tokenAmount * u256_from_felt252(self.totalPayout.read()));
            //update user balance with the reward
            let caller=get_caller_address();
            let user_bal = self.user_balances.read(caller);
            let new_user_bal = user_bal + reward;
            self.user_balances.write(caller, new_user_bal);
            //Finally update the prediction redeemed status
            let new_p = Prediction {
                participant: caller,
                tokenAmount: p.tokenAmount,
                candidate: p.candidate,
                redeemed: bool_to_felt252(true),
            };
            self.predictions.write(predictionID, new_p);
           
        }
        fn withdraw_tokens(ref self: ContractState, amount: u256){
            // get the user balance
            let caller = get_caller_address();
            let user_bal = self.user_balances.read(caller);
            //Make sure balance is not zero
            assert(user_bal > 0, "Balance is zero");
            //Transfer balances to user
            let token_address = self.token.read();
            IERC20Dispatcher {contract_address: token_address }.transfer(caller, user_bal);
            //Update user balance
            self.user_balances.write(caller, 0);
        }
    }    
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
      fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Prediction> {
           Result::Ok(
               Prediction {
                   participant: storage_read_syscall(
                       address_domain, storage_address_from_base_and_offset(base, 0_u8)
                   )?.try_into().unwrap(),
                   tokenAmount: storage_read_syscall(
                       address_domain, storage_address_from_base_and_offset(base, 1_u8)
                   )?.into(),
                   candidate: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 2_u8)
                )?,
                redeemed: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 3_u8)
                )?,
            }
        )
    }

      fn write(address_domain: u32, base: StorageBaseAddress, value: Prediction) -> SyscallResult::<()> {
          storage_write_syscall(
              address_domain, storage_address_from_base_and_offset(base, 0_u8), value.participant.into()
          );
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 1_u8), value.tokenAmount.try_into().unwrap()
        );
         storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 2_u8), value.candidate.into()
        );
         storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 3_u8), value.redeemed.into()
        )
    }
 }
    
}
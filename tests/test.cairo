// Importing necessary modules and traits
#[cfg(test)]
mod test {
    use core::array::ArrayTrait;
    use core::traits::Into;
    use core::debug::PrintTrait;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};
    use starknet::testing::{set_caller_address, set_block_timestamp};
    use starknet::{contract_address_const, ContractAddress};
    use stakbet::contract::IERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    // use stakbet::contract::IOracle::{IOracleDispatcher, IOracleDispatcherTrait};
    use stakbet::contract::bet_contract::{
        IBetContract, IBetContractDispatcher, IBetContractDispatcherTrait
    };
    // tests
    fn deploy() -> (IBetContractDispatcher, IERC20Dispatcher, ContractAddress) {
        // Deploy BetContract
        let contract = declare('BetContract');
        let contract_address = contract.deploy(@ArrayTrait::new()).unwrap();

        // Deploy main dispatcher for interactions with BetContract
        let bet_dispatcher = IBetContractDispatcher { contract_address };
        let ierc20_dispatcher = IERC20Dispatcher { contract_address };

        //Returning the dispatcher and contract address
        (bet_dispatcher, ierc20_dispatcher, contract_address)
    }

    // Constants for test values
    const PREDICTION_ID: felt252 = 1;
    const CANDIDATE: felt252 = 1;
    const AMOUNT: u256 = 100;
    const NEW_DEADLINE: u64 = 123456789;

    // Test for make_prediction functionality
    #[test]
    fn test_make_prediction() {
        // deploy contract
        let (bet_dispatcher, IERC20Dispatcher, contract_address) = deploy();
        let token_address = contract_address_const::<1>();
        let event_name = 'test_event';

        bet_dispatcher.make_prediction(PREDICTION_ID, CANDIDATE, AMOUNT);

        // Verify user's balance is updated
        let user_balance = IERC20Dispatcher { contract_address }.balanceOf(contract_address);
        assert(user_balance == AMOUNT, 'User balance not updated');
    }

    // Test for redeem_reward functionality
    #[test]
    fn test_redeem_reward() {
        // deploy contract
        let (bet_dispatcher, IERC20Dispatcher, contract_address) = deploy();
        let token_address = contract_address_const::<1>();
        let event_name = 'test_event';

        bet_dispatcher.make_prediction(PREDICTION_ID, CANDIDATE, AMOUNT);

        // Fast forward to after the deadline

        set_block_timestamp(bet_dispatcher.deadline() + 1);

        // Redeem reward
        bet_dispatcher.redeem_reward(PREDICTION_ID);

        // Verify user's balance is updated
        let user_balance = IERC20Dispatcher { contract_address }.balanceOf(contract_address);
        assert(user_balance > AMOUNT, 'User balance not updated after redemption');

        // Verify prediction status
        let prediction = bet_dispatcher.get_predictions(PREDICTION_ID);
        assert(prediction.redeemed == true, 'Prediction not marked as redeemed');
    }

    // Test for withdraw_tokens functionality
    #[test]
    fn test_withdraw_tokens() {
        // deploy contract
        let (bet_dispatcher, IERC20Dispatcher, contract_address) = deploy();
        let token_address = contract_address_const::<1>();
        let event_name = 'test_event';

        // Make a prediction
        bet_dispatcher.make_prediction(PREDICTION_ID, CANDIDATE, AMOUNT);

        // Withdraw tokens
        bet_dispatcher.withdraw_tokens(AMOUNT);

        // Verify user's balance is set to zero
        let user_balance = IERC20Dispatcher { contract_address }.balanceOf(contract_address);
        assert(user_balance == 0, 'Not set to zero after withdrawal');
    }

    // Test for extend_deadline functionality
    #[test]
    fn test_extend_deadline() {
        // deploy contract 
        let (bet_dispatcher, IERC20Dispatcher, contract_address) = deploy();
        let token_address = contract_address_const::<1>();
        let event_name = 'test_event';

        // Extend the deadline
        bet_dispatcher.extend_deadline(NEW_DEADLINE);

        // Verify the new deadline is correctly set
        let new_deadline = bet_dispatcher.deadline();
        assert(new_deadline == NEW_DEADLINE, 'New deadline not set correctly');
    }
}

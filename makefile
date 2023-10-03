-include .env

deployLocal:
@echo deploy all contracts
@forge script ./script/Counter.s.sol --fork-url ${LOCAL} --broadcast -vvvvv

deployFuji:
@echo deploying all contracts
@forge script ./script/Counter.s.sol --rpc-url ${FUJI} --broadcast 
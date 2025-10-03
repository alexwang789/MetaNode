package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"

	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// 查询区块
func getBlockByNumber(conn *ethclient.Client, blockNumber *big.Int) (*types.Block, error) {
	block, err := conn.BlockByNumber(context.Background(), blockNumber)
	if err != nil {
		return nil, err
	}
	return block, nil
}

// ETH转帐
func transferETH(nonce uint64, toAddress common.Address, amount *big.Int, gasLimit uint64, gasPrice *big.Int, data []byte) *types.Transaction {
	tx := types.NewTransaction(nonce, toAddress, amount, gasLimit, gasPrice, data)
	return tx
}

func main() {
	conn, err := ethclient.Dial("https://sepolia.infura.io/v3/a9fc774d89ac450fb27d2954e24966a0")
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()
	fmt.Println("Connected to Ethereum node")
	block, err := getBlockByNumber(conn, big.NewInt(5671788))
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(block.Number().Uint64())
	fmt.Println(block.Hash().Hex())
	fmt.Println(block.Time())
	fmt.Println(block.Difficulty().Uint64())
	fmt.Println(block.Extra())
	fmt.Println(len(block.Transactions()))

	privateKey, err := crypto.HexToECDSA("89bb191a4a4ee70f53539fb078e48eb2082d66131b82e48ae51b91f510f66c56")
	if err != nil {
		log.Fatal(err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}
	address := crypto.PubkeyToAddress(*publicKeyECDSA)
	fmt.Println(address.Hex())

	nonce, err := conn.PendingNonceAt(context.Background(), address)
	if err != nil {
		log.Fatal(err)
	}

	value := big.NewInt(1000000000000000000) // in wei (1 eth)

	gasPrice, err := conn.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	gasLimit := uint64(21000)

	toAddress := common.HexToAddress("0x4592d8f8d7b001e72cb26a73e4fa1806a51ac79d")

	tx := transferETH(nonce, toAddress, value, gasLimit, gasPrice, nil)

	chainID, err := conn.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Fatal(err)
	}

	err = conn.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(signedTx.Hash().Hex())
}



import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Verify that withdrawal_unsafe is unsafe",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get("wallet_1")!;
        const wallet2 = accounts.get("wallet_2")!;
        let block = chain.mineBlock([
            Tx.contractCall("bank", "deposit", ["u100"], wallet1.address),
            Tx.contractCall("bank", "withdrawal-unsafe", ["u100"], wallet2.address),
            Tx.contractCall("bank", "get-balance", [], wallet1.address),
            Tx.contractCall("bank", "get-balance", [], wallet2.address),
        ]);

        assertEquals(block.receipts.length, 4);
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectOk().expectBool(true);
        block.receipts[2].result.expectInt(100);
        block.receipts[3].result.expectInt(-100);
        assertEquals(block.height, 2);
    },
});

Clarinet.test({
    name: "Verify that withdrawal is safe",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get("wallet_1")!;
        const wallet2 = accounts.get("wallet_2")!;
        let block = chain.mineBlock([
            Tx.contractCall("bank", "deposit", ["u100"], wallet1.address),
            Tx.contractCall("bank", "withdrawal", ["u100"], wallet2.address),
            Tx.contractCall("bank", "get-balance", [], wallet1.address),
            Tx.contractCall("bank", "get-balance", [], wallet2.address),
        ]);

        assertEquals(block.receipts.length, 4);
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectErr().expectUint(1);
        block.receipts[2].result.expectInt(100);
        block.receipts[3].result.expectInt(0);
        assertEquals(block.height, 2);
    },
});

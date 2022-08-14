package pool

import (
	"std"

	"gno.land/p/grc/grc20"
	"gno.land/r/users"
)

// Pool for constant product market maker
type CPAMM struct {
	// LP tokens
	share *grc20.Token

	// pair information
	pairA      grc20.IGRC20
	pairB      grc20.IGRC20
	liquidityA uint64
	liquidityB uint64

	// fee amount per swap in permill
	feePermill uint64
}

func NewCPAMM(
	name,
	symbol string,
	pairA,
	pairB grc20.IGRC20,
	feePermill uint64,
) *CPAMM {
	if feePermill >= 1000 {
		panic("invalid fee parameter, permill must be lower than 1000")
	}

	return &CPAMM{
		pairA:      pairA,
		pairB:      pairB,
		share:      grc20.NewToken(name, symbol, 6),
		feePermill: feePermill,
	}
}

// Pool operations

func (c *CPAMM) ProvideLiquidity(from, pkgaddr std.Address, amountA uint64, amountB uint64) (newShares uint64) {
	// transfer tokens
	c.pairA.TransferFrom(from, pkgaddr, amountA)
	c.pairB.TransferFrom(from, pkgaddr, amountB)

	// cpamm invariant verification
	if c.liquidityA > 0 || c.liquidityB > 0 {
		if c.liquidityA*amountA != c.liquidityB*amountB {
			panic("invalid amount for provided liquidity")
		}
	}

	// mint shares
	totalSupply := c.share.TotalSupply()
	if totalSupply == 0 {
		newShares = sqrt(amountA * amountB)
	} else {
		newShares = min(
			(amountA*totalSupply)/c.liquidityA,
			(amountB*totalSupply)/c.liquidityB,
		)
	}
	if newShares == 0 {
		panic("no new shares")
	}
	c.share.Mint(from, newShares)

	// update liquidity
	c.liquidityA += amountA
	c.liquidityB += amountB

	return newShares
}

func (c *CPAMM) RemoveLiquidity(pkgaddr, to std.Address, shares uint64) (amountA uint64, amountB uint64) {
	// calculate liquidity to remove
	totalSupply := c.share.TotalSupply()
	amountA = (shares * c.liquidityA) / totalSupply
	amountB = (shares * c.liquidityB) / totalSupply
	if amountA == 0 || amountB == 0 {
		panic("no liquidity to remove")
	}

	// burn shares
	c.share.Burn(to, shares)

	// update liquidity
	c.liquidityA -= amountA
	c.liquidityB -= amountB

	// transfer removed liquidity
	c.pairA.Transfer(to, amountA)
	c.pairB.Transfer(to, amountB)

	return amountA, amountB
}

func (c *CPAMM) SwapA(from, pkgaddr std.Address, amount uint64) uint64 {
	// swap from pair A
	out := swap(from, pkgaddr, amount, c.pairA, c.pairB, c.liquidityA, c.liquidityB, c.feePermill)

	// update liquidity
	c.liquidityA += amount
	c.liquidityB -= out

	return out
}

func (c *CPAMM) SwapB(from, pkgaddr std.Address, amount uint64) (out uint64) {
	// swap from pair B
	out = swap(from, pkgaddr, amount, c.pairB, c.pairA, c.liquidityB, c.liquidityA, c.feePermill)

	// update liquidity
	c.liquidityB += amount
	c.liquidityA -= out

	return out
}

// swap swaps tokens from with the given liquidity
func swap(
	from,
	pkgaddr std.Address,
	amount uint64,
	pairIn,
	pairOut grc20.IGRC20,
	liquidityIn,
	liquidityOut,
	feePermill uint64,
) (out uint64) {
	// transfer in
	pairIn.TransferFrom(from, pkgaddr, amount)

	// calculate fees
	fee := (amount * feePermill) / 1000
	actualAmount := amount - fee

	// calculate out
	out = (liquidityOut * actualAmount) / (liquidityIn + actualAmount)

	// transfer out
	pairOut.Transfer(from, out)

	return out
}

// sqrt performs integer square root with binary search
func sqrt(n uint64) (res uint64) {
	if n < 2 {
		return n
	}

	start, end := uint64(1), uint64(n/2)
	for start <= end {
		mid := (start + end) / 2
		sqr := mid * mid

		// no truncation
		if sqr == n {
			return mid
		}

		// binary search
		if sqr <= n {
			start = mid + 1
			res = mid
		} else {
			end = mid - 1
		}
	}
	return res
}

// min returns lowest integer
func min(a uint64, b uint64) uint64 {
	if a <= b {
		return a
	} else {
		return b
	}
}

// LP token getters

func (c *CPAMM) TotalSupply() uint64 {
	return c.share.TotalSupply()
}

func (c *CPAMM) BalanceOf(owner users.AddressOrName) uint64 {
	return c.share.BalanceOf(owner.Resolve())
}

func (c *CPAMM) Allowance(owner, spender users.AddressOrName) uint64 {
	return c.share.Allowance(owner.Resolve(), spender.Resolve())
}

// LP token setters

func (c *CPAMM) Transfer(to users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	c.share.Transfer(caller, to.Resolve(), amount)
}

func (c *CPAMM) Approve(spender users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	c.share.Approve(caller, spender.Resolve(), amount)
}

func (c *CPAMM) TransferFrom(from, to users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	c.share.TransferFrom(caller, from.Resolve(), to.Resolve(), amount)
}

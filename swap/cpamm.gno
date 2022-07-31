package swap

import (
	"std"

	igrc20 "gno.land/p/grc/grc20"
	grc20 "gno.land/p/grc/grc20/impl"
)

// Pool for constant product market maker
type CPAMM struct {
	// LP tokens
	share *grc20.Token

	// pair information
	pairA      igrc20.GRC20
	pairB      igrc20.GRC20
	liquidityA uint64
	liquidityB uint64

	// fee amount per swap in permill
	feePermill uint64
}

func NewCPAMM(pairA, pairB igrc20.GRC20, feePermill uint64) *CPAMM {
	if feePermill >= 1000 {
		panic("invalid fee parameter, permill must be lower than 1000")
	}
	
	name := pairA.GetName() + "/" + pairB.GetName()
	symbol := pairA.GetSymbol() + "/" + pairB.GetSymbol()

	return &CPAMM{
		pairA:  	pairA,
		pairB:  	pairB,
		name:   	name,
		symbol: 	symbol,
		share:  	grc20.NewToken(name, symbol, 6),
		feePermill: feePermill,
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

// Pool operations

func (c *CPAMM) ProvideLiquidity(amountA uint64, amountB uint64) (newShares uint64) {
	caller := std.GetCallerAt(2)
	pkgaddr := std.GetOrigPkgAddr()

	// transfer tokens
	c.pairA.TransferFrom(caller, pkgaddr, amountA)
	c.pairB.TransferFrom(caller, pkgaddr, amountB)

	// cpamm invariant verification
	if c.liquidityA > 0 || c.liquidityB > 0 {
		if c.liquidityA*amountA != c.liquidityB*amountB {
			panic("invalid amount for provided liquidity")
		}
	}

	// mint shares
	totalSupply := c.share.TotalSupply()
	if !totalSupply {
		newShares = _sqrt(amountA * amountB)
	} else {
		newShares = min(
			(amountA * totalSupply) / c.liquidityA,
			(amountB * totalSupply) / c.liquidityB
		)
	}
	if !newShares {
		panic("no new shares")
	}
	c.share.Mint(caller, newShares)

	// update liquidity
	c.liquidityA += amountA
	c.liquidityB += amountB

	return newShares
}

func (c *CPAMM) RemoveLiquidity(shares uint64) (amountA uint64, amountB uint64) {
	caller := std.GetCallerAt(2)
	totalSupply := c.share.TotalSupply()

	// calculate liquidity to remove
	amountA = (shares * c.liquidityA) / totalSupply
	amountB = (shares * c.liquidityB) / totalSupply
	if !amountA || !amountB {
		panic("no liquidity to remove")
	}

	// burn shares
	c.share.Burn(caller, shares)

	// update liquidity
	c.liquidityA -= amountA
	c.liquidityB -= amountB

	// transfer removed liquidity
	c.pairA.Transfer(caller, amountA)
	c.pairB.Transfer(caller, amountB)

	return amountA, amountB
}

func (c *CPAMM) SwapA(amount uint64) uint64 {
	// swap from pair A
	out := swap(amount, c.pairA, c.pairB, c.liquidityA, c.liquidityB, c.feePermill)

	// update liquidity
	c.liquidityA += amount
	c.liquidityB -= out

	return out
}

func (c *CPAMM) SwapB(amount uint64) (out uint64) {
	// swap from pair B
	out := swap(amount, c.pairB, c.pairA, c.liquidityB, c.liquidityA, c.feePermill)

	// update liquidity
	c.liquidityB += amount
	c.liquidityA -= out

	return out
}

// swap swaps tokens from with the given liquidity
func swap(
	amount uint64,
	pairIn,
	pairOut igrc20.GRC20,
	liquidityIn,
	liquidityOut,
	feePermill uint64,
) (out uint64) {
	caller := std.GetCallerAt(2)
	pkgaddr := std.GetOrigPkgAddr()
	
	// transfer in
	pairIn.TransferFrom(caller, pkgaddr, amount)

	// calculate fees
	fee := (amount*feePermill)/1000
	actualAmount := amount-fee

	// calculate out
	out = (liquidityOut * actualAmount) / (liquidityIn + actualAmount)

	// transfer out
	pairOut.Transfer(caller, out)

	return out
}

// sqrt performs integer square root with binary search
func sqrt(n uint64) (res uint64) {
	if n < 2 {
		return n
	}

    start, end := 1, n/2
    for start <= end {
        mid := (start + end) / 2
        sqr := mid * mid

		// no truncation
        if sqr == x {
			return mid
		}

		// binary search
        if sqr <= x {
            start = mid + 1
            res = mid
        }
        else {
            end = mid - 1
		}
    }
    return res;
}

// min returns lowest integer
func min(a uint64, b uint64) uint64 {
	if a <= b {
		return a
	} else {
		return b
	}
}
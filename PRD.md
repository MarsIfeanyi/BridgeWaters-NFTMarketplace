The product is a smart contract that facilitates the creation and execution of ERC721 orders in a marketplace.
It leverages on-chain orders and VRS signatures to create and confirm orders.

# Functional Requirements:

The main functional requirement as of the time of writing the PRD are:

- listItem(): Allows users to list Item on the marketplace
- buyItem(): Allows users to buy Item from the marketplace
- verifySignature(): Helper function that will be called when an user calls buyItem().

###### listItem():

The marketplace should allow users to create ERC721 orders and list their tokens on the marketplace.
The order should contain the following information:

- Order Creator/Token Owner
- ERC721 Token Address (the contract that has the NFT)
- Token ID
- Price (in Ether)
- Signature (the seller must sign the hash of the token address, token ID, price, and owner)
- Deadline (the token cannot be bought after the deadline)
- Active status of the order

###### verifySignature():

This function should be called when an order is being created to verify the signature and confirm that it matches the owner's address. This is to ensure the integrity and authenticity of the order.

###### buyItem():

The contract should allow for the fulfillment of orders by buyers. This process should involve verifying the signature and other checks to ensure the validity of the transaction.

# Acceptance Criteria:

- Order Creation: Users should be able to create orders for their ERC721 tokens, including all required information.
- Signature Verification: The contract should correctly verify the signature of each order.
- Order Execution: Buyers should be able to fulfill orders, transferring ownership of the token and the payment.
- Test Coverage: All functions of the contract should be covered by tests, with no major issues detected.

## Pseudocode and Flow

createListing

- set order creator to msg.sender
- token address
- tokenId
- price
- sign
- deadline

preconditions

- owner
  - check that owner is really the owner of tokenId --> ownerOf()
  - check that owner has approved address(this) to spend tokenAddress -->isApprovedForAll()
- token address

  - check if token address is not address(0)
  - check if the address has code

- price
  - check that price > 0
- sign
-
- deadline
  - must be > block.timestamp

logic

- store data in storage
- increment id for Listings
- emit event

executeListing(payable)

- listingId

preconditions

- check that listingId< public counter
- check that msg.value == listing.price
- check that block.timestamp <= listing.deadline
- check that signature is signed by listing.owner

logic

- retrieve data from storage
- transfer ether from buyer to seller
- transfer nft from seller to buyer
- emit event

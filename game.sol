pragma solidity ^0.4.21;

/**
 * The Owned contract ensures that only the creator (deployer) of a 
 * contract can perform certain tasks.
 */
contract Owned
{
	address public owner = msg.sender;
	
	event LogOwnerChanged(address indexed old, address indexed current);
	
	modifier only_owner
	{
		require(msg.sender == owner);
		_;
	}
	
	function setOwner(address _newOwner) only_owner public
	{
		LogOwnerChanged(owner, _newOwner);
		owner = _newOwner;
	}
}

/**
 * The game contract does this and that...
 */
contract game is Owned
{
	uint public minBid;
	uint public noOfTeams;
	bool public acceptingBids;

	mapping (address => bool) isInvited;
	mapping (uint => address) bidderOnTeam;
	mapping (address => uint) bidValueOf;
	
	// add events
	event LogBidderInvited(address _bidder);
	event LogCloseBids();
	event LogOutbidden(address _newBidder, uint _newBid, uint _team, address _oldBidder);
	event LogBidPlaced(address _newBidder, uint _newBid, uint _team);
	event LogWinner(address _winner, uint _team);
	
	// add getters
	function getMinBid () constant returns(uint res)
	{
		return minBid;
	}

	function getNoOfTeams () constant returns(uint res)
	{
		return noOfTeams;
	}

	function getCurrentBidOnTeam (uint _team) constant returns(uint res)
	{
		return bidValueOf[bidderOnTeam[_team]];
	}
	

	function game (uint _minBid, uint _noOfTeams)
	{
		minBid = _minBid;
		noOfTeams = _noOfTeams;
		acceptingBids = true;
	}
	
	function inviteBidder(address _bidder) only_owner
	{
		isInvited[_bidder] = true;
		LogBidderInvited(_bidder);
	}

	function closeBids() only_owner
	{
		acceptingBids = false;
		LogCloseBids();
	}
	
	function bid(uint _team) payable
	{
		require (acceptingBids);
		require (isInvited[msg.sender]);
		require (_team <= _noOfTeams && _team > 0);

		if(bidderOnTeam[_team] == address(0)) // first bid
		{
			require (msg.value >= minBid);
		}
		else // overtake
		{
			require (msg.value >= 2 * bidValueOf[bidderOnTeam[_team]]);
			sendFunds95(bidderOnTeam[_team], bidValueOf[bidderOnTeam[_team]]);
			LogOutbidden(msg.sender, msg.value, _team, bidderOnTeam[_team]);
		}
		bidderOnTeam[_team] = msg.sender;
		bidValueOf[msg.sender] = msg.value;
		LogBidPlaced(msg.sender, msg.value, _team);
	}
	
	function endGame (uint _winningTeam) only_owner
	{
		require (!acceptingBids);
		require (_winningTeam <= _noOfTeams && _winningTeam > 0);
		
		sendFunds95(bidderOnTeam[_winningTeam], address(this).balance);
		// winner announced
		LogWinner(bidderOnTeam[_winningTeam], uint _winningTeam);
		selfdestruct(owner);
	}

	function sendFunds95 (address _reciever, uint _value) internal
	{
		uint amount = (95 * _value) / 100;
		_reciever.transfer(amount);
	}

	function()
	{
		revert();
	}	
}

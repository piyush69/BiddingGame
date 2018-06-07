xpragma solidity ^0.4.21;

/**
 * The game contract accepts bids on teams and rewards the winner.
 */
contract game
{
	uint public minBidWei;
	uint public noOfTeams;
	bool public acceptingBids;
	address public admin;

	mapping (address => bool) isInvited;
	mapping (uint => address) bidderOnTeam;
	mapping (address => uint) bidValueOf;
	
	// add events
	event LogBidderInvited(address _bidder);
	event LogCloseBids();
	event LogOutbidden(address _newBidder, uint _newBid, uint _team, address _oldBidder);
	event LogBidPlaced(address _newBidder, uint _newBid, uint _team);
	event LogWinner(address _winner, uint _team);
	
	modifier only_admin
	{
		require(msg.sender == admin);
		_;
	}

	function getCurrentBidOnTeam (uint _team) constant returns(uint res)
	{
		return bidValueOf[bidderOnTeam[_team]];
	}
	

	function game (uint _minBidWei, uint _noOfTeams)
	{
		minBidWei = _minBidWei;
		noOfTeams = _noOfTeams;
		acceptingBids = true;
		admin = msg.sender;
	}
	
	function inviteBidder(address _bidder) only_admin
	{
		isInvited[_bidder] = true;
		LogBidderInvited(_bidder);
	}

	function closeBids() only_admin
	{
		acceptingBids = false;
		LogCloseBids();
	}
	
	function bid(uint _team) payable
	{
		require (acceptingBids);
		require (isInvited[msg.sender]);
		require (_team <= noOfTeams && _team > 0);

		if(bidderOnTeam[_team] == address(0)) // first bid
		{
			require (msg.value >= minBidWei);
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
	
	function endGame (uint _winningTeam) only_admin
	{
		require (!acceptingBids);
		require (_winningTeam <= noOfTeams && _winningTeam > 0);
		
		sendFunds95(bidderOnTeam[_winningTeam], address(this).balance);
		// winner announced
		LogWinner(bidderOnTeam[_winningTeam], _winningTeam);
		selfdestruct(admin);
	}

	function sendFunds95 (address _reciever, uint _value) internal
	{
		if(_reciever != address(0))
		{
			uint amount = (95 * _value) / 100;
			_reciever.transfer(amount);
		}
	}

	function()
	{
		revert();
	}  
}
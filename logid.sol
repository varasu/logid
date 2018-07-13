pragma solidity ^ 0.4.9;

contract Logid {
	// Events
	event NewUser(
		uint256 _value,
		address indexed _user
	);
	
	event DeleteUser(
		address indexed _user
	);

	event BanUser(
		address indexed _user
	);

	event Withdraw(
		uint256 _value,
		address indexed _user
	);

	// contract owner
	// in this case owner can unregister/ban user. user's ether will be refunded
	// or set/change minEther value
	address public owner;

	// map of registered users in our (blog/site/platform)
	// key -> ethereum address, value -> deposited ether
	mapping(address => uint256) public registeredUsers;

	// mininum ether to deposit for registration
	// can setup on contract creation or with SetMinEther()
	uint256 public minEther;

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	modifier aboveMin() {
		require(minEther <= msg.value);
		_;
	}

	// Run on Contract creation
	constructor(uint256 _minEther, address _owner) public {
		if (_owner == 0) {
			owner = msg.sender;
		}
		owner = _owner;
		minEther = _minEther;
	}

	// prevent trapping ether
	function() public {
		revert();
	}

	// change owner
	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	// owner can change minEther when he/she wish
	function setMinEther(uint256 _minEther) public onlyOwner {
		minEther = _minEther;
	}	

	// Register() is payable function.
	// modifier aboveMin take care for the minEther limit enforcement
	function register() public payable aboveMin {
		// revert if already registered
		if (registeredUsers[msg.sender] > 0) {
			revert();
		}
		registeredUsers[msg.sender] = msg.value;
		emit NewUser(msg.value, msg.sender);
	}

	// delete user
	function deleteUser() public {
		if (registeredUsers[msg.sender] == 0) {
			revert();
		}
		uint256 amount = registeredUsers[msg.sender];
		registeredUsers[msg.sender] = 0;
		msg.sender.transfer(amount);
		emit DeleteUser(msg.sender);
	}

	// Ban
	function ban(address user) public onlyOwner {
		// how much ether to return
		uint256 amount = registeredUsers[user];
		// clear user ether value
		registeredUsers[user] = 0;
		// send back user's ether
		user.transfer(amount);
		emit BanUser(user);
	}

	// User can withdraw there deposit funds anytime
	// We only take one wei because zero value means banned user.
	function withdraw() public {
		if (registeredUsers[msg.sender] == 0) {
			revert();
		}
		uint256 amount = registeredUsers[msg.sender];
		uint256 _wei = amount - (amount - 1);
		// for the purpose not to be zero (and for fun), we take only one wei from the user
		registeredUsers[msg.sender] = _wei;
		// and send back user's ether
		msg.sender.transfer(amount);
		emit Withdraw(amount, msg.sender);
	}

	// This function check signature of the message (owner of the signature) and
	// if this user is registered in our smart contract
	function isAllowed(bytes m, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
		bytes32 hash = sha256(m);
		address user = ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s);
		if (registeredUsers[user] > 0) {
			return true;
		} else {
			return false;
		}
	}
}
